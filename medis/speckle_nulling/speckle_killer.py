import medis.speckle_nulling.sn_preprocessing as pre
import cv2
import os
import matplotlib.pyplot as plt
import astropy.io.fits as pf
import ipdb
import medis.speckle_nulling.sn_math as snm
import numpy as np
from configobj import ConfigObj
import medis.speckle_nulling.sn_filehandling as flh
import medis.speckle_nulling.sn_hardware as hardware
import flatmapfunctions as FM
from validate import Validator
import medis.speckle_nulling.dm_functions as DM
import time
import detect_speckles
import scipy.ndimage as sciim
from copy import deepcopy

class output_imagecube:
    def __init__(self, n, size, filepath = None, comment = None, configfile = None):
        self.cube = np.zeros( (n, size, size))
        self.textstring = (comment + '\n\n\n'+self.config_to_string(configfile))
        flh.writeout(self.cube, outputfile = filepath, 
                            comment =comment)
        self.i = 0 
        self.filepath = filepath

        flh.writeout(self.cube, outputfile = filepath)
        with open(filepath+'.txt', 'w') as f:
            f.write(self.textstring)
    
    def config_to_string(self, configfile):
        stringy = ''
        with open(configfile) as f:
            for line in f:
                stringy = stringy+line
        return stringy

    def update(self, array ):
        self.cube[self.i, :,:] = array
        self.i = self.i+1
        flh.writeout(self.cube, outputfile = self.filepath)
                            


class speckle:
    def __init__(self, image,xp, yp, config):
        self.imparams = config['IM_PARAMS']
        self.abc       = config['INTENSITY_CAL']['abc']
        self.xcentroid = xp 
        self.ycentroid = yp 
        self.kvec      = DM.convert_pixels_kvecs(self.xcentroid,
                                                 self.ycentroid,
                                                 **self.imparams)
        self.kvecx     = self.kvec[0]
        self.kvecy     = self.kvec[1]
        self.krad      = np.linalg.norm((self.kvecx, self.kvecy))
        self.aperture  = detect_speckles.create_speckle_aperture(
                image, self.xcentroid, self.ycentroid, config['INTENSITY_CAL']['aperture_radius'])
        #Edit to take into account aperture on other side
        #self.aperture = self.aperture + detect_speckles.create_speckle_aperture(
        #        image, 2*self.imparams['centerx']-self.xcentroid, 
        #               2*self.imparams['centery']-self.ycentroid, 
        #               config['INTENSITY_CAL']['aperture_radius'])
        #Edit to take into account aperture on other side
        self.exclusionzone  = detect_speckles.create_speckle_aperture(
                image, self.xcentroid, self.ycentroid, 2*config['INTENSITY_CAL']['aperture_radius'])
        #self.exclusionzone  = self.exclusionzone + detect_speckles.create_speckle_aperture(
        #        image, 2*self.imparams['centerx']-self.xcentroid, 
        #               2*self.imparams['centery']-self.ycentroid, 
        #               1.5*config['INTENSITY_CAL']['aperture_radius'])

        self.intensity = detect_speckles.get_speckle_photometry(image, self.aperture)
        self.phase_intensities = [None, None, None, None]
        self.phases = config['NULLING']['phases']
        self.null_phase = None

        self.null_gain = None
        self.gains= config['NULLING']['amplitudegains']
        self.gain_intensities = [None, None, None, None]         
    def recompute_intensity(self, phaseimage):
        return detect_speckles.get_speckle_photometry(phaseimage, self.aperture)
    
    def generate_flatmap(self, phase):
        """generates flatmap with a certain phase for this speckle"""
        s_amp = DM.amplitudemodel(self.intensity, self.krad, **self.abc)
        print 's_amp: ', s_amp, 'self.krad: ', self.krad, 'phase: ', phase	
        return DM.make_speckle_kxy(self.kvecx, self.kvecy, s_amp, phase)
    
    def compute_null_phase(self):
        A, B, C, D = self.phase_intensities 
        phase0 =  np.arctan((D-B)/(A-C))
        if phase0 < 0:
            phase0 += np.pi
        
        null_phase = np.pi - phase0
        ind = np.argmin(np.abs(null_phase - np.array(phases)))
        if len((np.where(self.phase_intensities > self.phase_intensities[ind]))[0]) < 2:
            null_phase += np.pi
        self.null_phase = null_phase
        return null_phase
    
    def compute_null_gain(self):
        L = self.gain_intensities.copy()
        
        strictly_increasing = all(x<y for x, y in zip(L, L[1:]))
        strictly_decreasing = all(x<y for x, y in zip(L, L[1:]))
        if strictly_increasing:
            self.null_gain = max(L)
        elif strictly_decreasing:
            self.null_gain = min(L)
        else:
            #fit a decreasing parabola
            a, b, c = np.polyfit(self.amplitudegains, L, deg=2)
            if a>1:
                print "WARNING: got an upward sloping parabola!"
                self.null_gain = min(L)
            else:
                self.null_gain =-1.0*b/(2*a)
        print "NULL GAIN IS: ", self.null_gain
        return self.null_gain

def identify_bright_points(image):
    """WARNING: indexes, NOT coordinates"""
    max_filt = sciim.filters.maximum_filter(image, size= 6)
    
    pts_of_interest = (max_filt == image)
    pts_of_interest_in_region = pts_of_interest*controlregion
    iindex, jindex = np.nonzero((max_filt*controlregion == image*controlregion)*controlregion)
    intensities = np.zeros(iindex.shape)
    for i in range(len(intensities)):
        intensities[i] = image[iindex[i], jindex[i]]
    order = np.argsort(intensities)[::-1]
    sorted_i = iindex[order]
    sorted_j = jindex[order]
    return zip(sorted_i, sorted_j)

def filterspeckles(specklelist, max=5):
    copylist= deepcopy(specklelist)
    #FIRST ELEMENT ALWAYS SELECTED
    sum = copylist[0].exclusionzone*1.0
    returnlist = []
    returnlist.append(copylist[0])
    if (max == 1):
        return returnlist
    if max >1:
        i=1

        while len(returnlist)<max:
            if i>=len(copylist):
                break
            print "max: ",max," i: ",i
            sum_tmp = sum+copylist[i].exclusionzone*1.0 
            print "test"
            print i, (sum_tmp>1).any()
            if (sum_tmp>1).any():
                i=i+1
                sum_tmp = sum
            else:
                returnlist.append(copylist[i])
                sum = sum_tmp
                i = i+1
        return returnlist

def generate_phase_nullmap(speckleslist, initialmap, gain):
    nullmap = initialmap 
    for speck in speckleslist:
        null_phase=speck.compute_null_phase()
        nullmap = nullmap+gain*speck.generate_flatmap(null_phase)

    return nullmap

def generate_super_nullmap(speckleslist, initialmap)
    for speck in speckleslist:
        null_phase=speck.compute_null_phase()
        nullmap = nullmap+speck.null_gain*speck.generate_flatmap(null_phase)
    return nullmap
    
            
def fastplot(specklelist):

    fig2 = plt.figure(figsize=(4,4))
    ax2 = fig2.add_subplot(111)
    for speck in specklelist:
        ax2.plot(speck.phases, speck.phase_intensities)
        ax2.set_title(( str(speck.xcentroid)+', '+
                        str(speck.ycentroid)))
        ax2.axvline(speck.null_phase)
        print speck.null_phase
        plt.draw()
        plt.pause(0.1)
        plt.cla()
    plt.close()


if __name__ == "__main__":
    #configfilename = 'speckle_null_config.ini'
    #config = ConfigObj(configfilename)
    configfilename = 'speckle_null_config.ini'
    hardwareconfigfile = 'speckle_instruments.ini'
    configspecfile = 'speckle_null_config.spec'
    config = ConfigObj(configfilename, configspec=configspecfile)
    val = Validator()
    check = config.validate(val)
    
    pharo = hardware.PHARO_COM('PHARO', 
                configfile = hardwareconfigfile)
    p3k = hardware.P3K_COM('P3K_COM', configfile = hardwareconfigfile)
    im_params= config['IM_PARAMS']
    null_params = config['NULLING']
    abc = config['INTENSITY_CAL']['abc']
    bgds = flh.setup_bgd_dict(config) 
    controlregion = pf.open(config['CONTROLREGION']['filename'])[0].data
    #Notes==>scale exptime in snr
    exp = config['INTENSITY_CAL']['exptime']
    #Setup
    initial_flatmap = p3k.grab_current_flatmap()
    
    defaultim = np.ones((1024, 1024) )

    vertsx = config['CONTROLREGION']['verticesx']
    vertsy = config['CONTROLREGION']['verticesy']
    
    plt.ion()
    fig = plt.figure(figsize = (12, 12))
    ax1 =plt.subplot2grid((4,4),(0, 0), rowspan =2, colspan = 2)
    ax2 = plt.subplot2grid((4,4),(0, 2), rowspan =2, colspan = 2)
    ax3 =plt.subplot2grid((4,4),(3, 0)) 
    #ax4 =plt.subplot2grid((4,4),(3, 3))
    #ax5 = plt.subplot2grid((4,4),(3,2))
    
    title = fig.suptitle('Speckle destruction')
    ax1.set_title('Image')
    ax2.set_title('Control region')
    #ax3.set_title('Null map')
    #ax4.set_title('Phase map')
    #ax5.set_title('Intensity')

    w1 = ax1.imshow(np.log(np.abs(defaultim)), origin='lower', interpolation = 'nearest')
    
    #ax1.set_xlim(int(im_params['centerx'])-25, int(im_params['centerx']+50))
    #ax1.set_ylim(int(im_params['centery'])-25, int(im_params['centery']+50))

    ax1.set_xlim(min(vertsx), max(vertsx))
    ax1.set_ylim(min(vertsy), max(vertsy))
    #ax1.set_ylim(int(im_params['centery'])-25, int(im_params['centery']+50))
    
    w2 = ax2.imshow(np.log(np.abs(controlregion*defaultim)), origin='lower', interpolation = 'nearest')
    #ax2.set_xlim(int(im_params['centerx'])-25, int(im_params['centerx']+50))
    #ax2.set_ylim(int(im_params['centery'])-25, int(im_params['centery']+50))
    ax2.set_xlim(min(vertsx), max(vertsx))
    ax2.set_ylim(min(vertsy), max(vertsy))
    #w3 = ax3.imshow(initial_flatmap, origin='lower', interpolation = 'nearest')
    #w4 = ax4.imshow(initial_flatmap, origin='lower', interpolation = 'nearest') 
    
    N_iterations = 10
    itcounter  = []
    maxfluxes = []
    meanfluxes = []
    totalfluxes = []
    rmsfluxes = []
    #w5 = ax5.plot(np.arange(10)*0, np.arange(10)*0)
    
    plt.show()

    tstamp = time.strftime("%Y%m%d-%H%M%S").replace(' ', '_')
    result_imagecube =  output_imagecube(N_iterations, 1024, 
           filepath = os.path.join(null_params['outputdir'],
                 'test_'+ tstamp+'.fits'),
           comment = 'fun', 
           configfile = configfilename)
    
    clean_imagecube=  output_imagecube(N_iterations, 1024, 
           filepath = os.path.join(null_params['outputdir'],
                 'test_clean_'+ tstamp+'.fits'),
           comment = 'fun', 
           configfile = configfilename)
    
    cal_imagecube = output_imagecube(4, 1024, 
           filepath = os.path.join(null_params['outputdir'],
                 'test_cals_'+ tstamp+'.fits'),
           comment = 'fun', 
           configfile = configfilename)
    cal_imagecube.update(controlregion)
    cal_imagecube.update(bgds['bkgd'])
    cal_imagecube.update(bgds['masterflat'])
    cal_imagecube.update(bgds['badpix'])
   
   
    ####MAIN LOOP STARTS HERE##### 
    
    referenceval = 6000000.0
     
    for iteration in range(N_iterations):
        
        itcounter.append(iteration)

        current_map = p3k.grab_current_flatmap()
        
        print "Taking image of speckle field"
        raw_im = pharo.take_src_return_imagedata(exptime=exp)
        result_imagecube.update(raw_im)
        field_im = pre.equalize_image(raw_im, **bgds)
        clean_imagecube.update(field_im)
        field_ctrl = field_im*controlregion
        
        meanfluxes.append(np.mean(field_ctrl[field_ctrl>0]))
        maxfluxes.append(np.max(field_ctrl[field_ctrl>0]))
        totalfluxes.append(np.sum(field_ctrl))
        rmsfluxes.append(np.std(field_ctrl[field_ctrl>0])/referenceval)

        w5 = plt.plot(itcounter,rmsfluxes) 
        #w5 = plt.plot(itcounter, maxfluxes)
        #w5 = plt.plot(itcounter, totalfluxes)
        ax1.set_title('Iteration: '+str(iteration)+
                      ',  Mean: '+str(meanfluxes[iteration])+
                      ',  Max: '+str(maxfluxes[iteration]))
        w1.set_data(np.log(np.abs(field_ctrl)))
        w1.autoscale()
        plt.draw()
        plt.pause(0.02) 
        
        print ('Iteration '+str(iteration)+
           ' total_intensity: '+str(np.sum(field_ctrl)))
        #return a list of points
        print "computing interesting bright spots"
        
        #note indices and coordinates are reversed
        ijofinterest = identify_bright_points(field_ctrl)
        xyofinterest = [p[::-1] for p in ijofinterest] 
        
        max_specks = config['DETECTION']['max_speckles']
        if len(xyofinterest)>50:
            xyofinterest = xyofinterest[0:49]
        
        if len(xyofinterest)<max_specks:
            max_specks = len(xyofinterest)

        print "creating speckle objects"
        speckleslist = [speckle(field_im, xy[0], xy[1], config) for xy in xyofinterest]
        speckleslist = filterspeckles(speckleslist, max = max_specks)

        phases = null_params['phases']
        for idx, phase in enumerate(phases):
            print "Phase ", phase
            phaseflat = current_map
            allspeck_aps= 0
            for speck in speckleslist:
                phaseflat= phaseflat+speck.generate_flatmap(phase)
                allspeck_aps = allspeck_aps+ speck.aperture
            
            ax2.set_title('Phase: '+str(phase))
            w1.set_data(allspeck_aps); w1.autoscale(); plt.draw()
            w1.set_data(field_ctrl); w1.autoscale(); plt.draw()
            
            p3k.load_new_flatmap(phaseflat)
            #w3.set_data(phaseflat);plt.draw()
            
            phaseim = pharo.take_src_return_imagedata(exptime =exp) 
            phaseim = pre.equalize_image(phaseim, **bgds) 
            
            w2.set_data(np.log(np.abs(phaseim*controlregion)))
            w2.autoscale();plt.draw();plt.pause(0.02) 
            
            print "recomputing intensities"
            for speck in speckleslist:
                phase_int = speck.recompute_intensity(phaseim)
                speck.phase_intensities[idx] = phase_int
        #fastplot(speckleslist)
        p3k.load_new_flatmap(current_map)
       
        ##NOW CALCULATE GAIN NULLS 
        print "DETERMINING NULL GAINS"
        gains = config['NULLING']['amplitudegains']:
        for idx, gain in enumerate(gains):
            print "Checking optimal gains"
            nullmap= generate_phase_nullmap(speckleslist, current_map, gain) 
            p3k.load_new_flatmap(nullmap)
        
            ampim = pharo.take_src_return_imagedata(exptime =exp) 
            ampim = pre.equalize_image(ampim, **bgds) 
            w2.set_data(np.log(np.abs(ampim*controlregion)))
            ax2.set_title('Gain: '+str(gain))
            w2.autoscale();plt.draw();plt.pause(0.02) 
            for speck in speckleslist:
                amp_int = speck.recompute_intensity(ampim)
                speck.gain_intensities[idx] = amp_int
        for speck in speckleslist:
            speck.compute_null_gain()
        supernullmap = generate_super_nullmap(speckleslist, current_map)
        print "Loading supernullmap now that optimal gains have been found!"
        p3k.load_new_flatmap(supernullmap)
        #w3.set_data(nullmap)
        plt.draw()
