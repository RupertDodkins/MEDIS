import sn_preprocessing as pre
import cv2
import os
import matplotlib.pyplot as plt
import astropy.io.fits as pf
import ipdb
import sn_math as snm
import numpy as np
from configobj import ConfigObj
import sn_filehandling as flh
import sn_hardware as hardware
import flatmapfunctions as FM
from validate import Validator
import dm_functions as DM
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
                image, self.xcentroid, self.ycentroid, 1.5*config['INTENSITY_CAL']['aperture_radius'])
        #self.exclusionzone  = self.exclusionzone + detect_speckles.create_speckle_aperture(
        #        image, 2*self.imparams['centerx']-self.xcentroid, 
        #               2*self.imparams['centery']-self.ycentroid, 
        #               1.5*config['INTENSITY_CAL']['aperture_radius'])
        self.intensity = detect_speckles.get_speckle_photometry(image, self.aperture)
        self.phase_intensities = [None, None, None, None]
        self.phases = config['NULLING']['phases']
        self.null_phase = None
    
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

def recompute_centroid(image, spots, window=20):
    """centroid each satellite spot using a 2d gaussian"""
    #spots = pre.get_spot_locations(image, eq=True,
    #        comment='SHIFT-Click on the satellites CLOCKWISE'+
    #                 'starting from 10 o clock,\n then close the window')
    #satellite centers
    scs = np.zeros((4, 2))
    for idx,xy in enumerate(spots):
        subim = pre.subimage(image, xy, window=window)
        popt = snm.image_centroid_gaussian1(subim)
        xcenp = popt[1]
        ycenp = popt[2]
        xcen = xy[0]-round(window/2)+xcenp
        ycen = xy[1]-round(window/2)+ycenp
        scs[idx,:] = xcen, ycen
    center =np.mean(scs, axis =0) 
    print "CENTER IS: ", center
    return center

def expected_spot_positions(kvecr, im_params):
    xy0 = DM.convert_kvecs_pixels(kvecr, 0, **im_params)
    xy1 = DM.convert_kvecs_pixels(-kvecr, 0, **im_params)
    xy2 = DM.convert_kvecs_pixels(0,kvecr, **im_params)
    xy3 = DM.convert_kvecs_pixels(0,-kvecr, **im_params)
    xypixels = [xy0, xy1, xy2, xy3]
    return xypixels

def generate_bulk_nullmap(speckleslist, initialmap, gain):
    nullmap = initialmap 
    for speck in speckleslist:
        null_phase=speck.compute_null_phase()
        nullmap = nullmap+gain*speck.generate_flatmap(null_phase)

    return nullmap

def fastplot(specklelist):

    fig2 = plt.figure(figsize=(4,4))
    ax2 = fig2.add_subplot(111)
    for idx, speck in specklelist:
        ax2.plot(speck.phases, speck.phase_intensities)
        ax2.set_title(( str(speck.xcentroid)+', '+
                        str(speck.ycentroid)))
        ax2.axvline(speck.nullphase);plt.draw()
        plt.draw()
        plt.pause(0.1)
        plt.cla()
    plt.close()

if __name__ == "__main__":
    #configfilename = 'speckle_null_config.ini'
    #config = ConfigObj(configfilename)
    plotphases = True

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
    
    ################
    #####SETUP######
    ################
    initial_flatmap = p3k.grab_current_flatmap()
    
    #add waffle pattern to centroid on
    #comment this out to get rid of the waffle
    first_xcen = im_params['centerx']
    first_ycen = im_params['centery']
    
    DMamp = 30
    kvecr = 30
    additionmapx = DM.make_speckle_kxy(kvecr, 0,DMamp, 0) 
    additionmapy = DM.make_speckle_kxy(0,kvecr, DMamp, 0) 
    additionmap = additionmapx + additionmapy
    print "loading waffle to centroid on"
    status = p3k.load_new_flatmap(initial_flatmap+additionmap)
    expected_xy_pos = expected_spot_positions(kvecr, im_params)
    print "searchign for expected spots to centroid at "
    print expected_xy_pos

    defaultim = np.ones((1024, 1024) )

    vertsx = config['CONTROLREGION']['verticesx']
    vertsy = config['CONTROLREGION']['verticesy']
    
    plt.ion()
    fig = plt.figure(figsize = (12, 12))
    ax1 =plt.subplot2grid((4,4),(0, 0), rowspan =2, colspan = 2)
    ax2 = plt.subplot2grid((4,4),(0, 2), rowspan =2, colspan = 2)
    ax3 =plt.subplot2grid((4,4),(3, 0)) 
    
    title = fig.suptitle('Speckle destruction')
    ax1.set_title('Image')
    ax2.set_title('Control region')

    w1 = ax1.imshow(np.log(np.abs(defaultim)), origin='lower', interpolation = 'nearest')
    
    #ax1.set_xlim(int(im_params['centerx'])-25, int(im_params['centerx']+50))
    #ax1.set_ylim(int(im_params['centery'])-25, int(im_params['centery']+50))

    ax1.set_xlim(min(vertsx), max(vertsx))
    ax1.set_ylim(min(vertsy), max(vertsy))
    
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
           filepath = os.path.join(null_params['outputdir'],tstamp,
                 'test_'+ tstamp+'.fits'),
           comment = 'fun', 
           configfile = configfilename)
    
    clean_imagecube=  output_imagecube(N_iterations, 1024, 
           filepath = os.path.join(null_params['outputdir'],tstamp,
                 'test_clean_'+ tstamp+'.fits'),
           comment = 'fun', 
           configfile = configfilename)
    
    cal_imagecube = output_imagecube(4, 1024, 
           filepath = os.path.join(null_params['outputdir'],tstamp,
                 'test_cals_'+ tstamp+'.fits'),
           comment = 'fun', 
           configfile = configfilename)
    cal_imagecube.update(controlregion)
    cal_imagecube.update(bgds['bkgd'])
    cal_imagecube.update(bgds['masterflat'])
    cal_imagecube.update(bgds['badpix'])
   
   
    ####MAIN LOOP STARTS HERE##### 
   
    for iteration in range(N_iterations):
        
        itcounter.append(iteration)

        current_map = p3k.grab_current_flatmap()
        
        print "Taking image of speckle field"
        raw_im = pharo.take_src_return_imagedata(exptime=exp)
        result_imagecube.update(raw_im)
        field_im = pre.equalize_image(raw_im, **bgds)
        
        #XXX RESHIFT normal image as well
        newcentroid = recompute_centroid(field_im, **bgds)
        shiftx, shifty = newcentroid - [first_xcen, first_ycen]
        field_im = sciim.interpolation.shift(field_im, [-shifty, -shiftx], order =1)
        controlregion = sciim.interpolation.shift(controlregion, [-shifty, -shiftx], order =1)

        clean_imagecube.update(field_im)
        field_ctrl = field_im*controlregion
        
        meanfluxes.append(np.mean(field_ctrl[field_ctrl>0]))
        maxfluxes.append(np.max(field_ctrl[field_ctrl>0]))
        totalfluxes.append(np.sum(field_ctrl))
        rmsfluxes.append(np.std(field_ctrl[field_ctrl>0]))

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
                #old version, unnecessary and immoral to apply gain twice
                #phaseflat= phaseflat+null_params['flatmap_gain']*speck.generate_flatmap(phase)
                
                phaseflat= phaseflat+speck.generate_flatmap(phase)
                allspeck_aps = allspeck_aps+ speck.aperture
            
            ax2.set_title('Phase: '+str(phase))
            w1.set_data(allspeck_aps); w1.autoscale(); plt.draw()
            w1.set_data(field_ctrl); w1.autoscale(); plt.draw()
            
            p3k.load_new_flatmap(phaseflat)
            #w3.set_data(phaseflat);plt.draw()
            
            phaseim = pharo.take_src_return_imagedata(exptime =exp) 
            phaseim = pre.equalize_image(phaseim, **bgds) 
            #XXX--recompute the image centroid to control for drifts
            newcentroid = recompute_centroid(phaseim, **bgds)
            #shift the image to account for the drift
            shiftx, shifty = newcentroid - [first_xcen, first_ycen]
            phaseim = sciim.interpolation.shift(phaseim, [-shifty, -shiftx], order =1)
            #OPTIONAL--update centroids
            #config['IM_PARAMS']['centerx'] = newcentroid[0]
            #config['IM_PARAMS']['centery'] = newcentroid[1]

            w2.set_data(np.log(np.abs(phaseim*controlregion)))
            w2.autoscale();plt.draw();plt.pause(0.02) 
            
            print "recomputing intensities"
            for speck in speckleslist:
                phase_int = speck.recompute_intensity(phaseim)
                speck.phase_intensities[idx] = phase_int
        
        if plotphases:
            ipdb.set_trace()
            fastplot(speckleslist)
        ipdb.set_trace()
        p3k.load_new_flatmap(current_map)
        nullmap= generate_bulk_nullmap(speckleslist, current_map, config['NULLING']['flatmap_gain'])
        print "LOADING NULL MAP"
        p3k.load_new_flatmap(nullmap)
        
        #w3.set_data(nullmap)
        plt.draw()
