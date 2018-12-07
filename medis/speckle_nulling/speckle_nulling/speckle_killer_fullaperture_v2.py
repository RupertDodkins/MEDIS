import sn_preprocessing as pre
# import cv2
import os
import matplotlib.pyplot as plt
import pyfits as pf
# import ipdb
import sn_math as snm
import numpy as np
from configobj import ConfigObj
import sn_filehandling as flh
import sn_hardware as hardware
import flatmapfunctions as FM
from validate import Validator
import dm_functions as DM
import timeit
import time
import detect_speckles
import flatmapfunctions as fmf
import define_control_annulus_auto
import dm_registration as DMR
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
        self.aperture = self.aperture + detect_speckles.create_speckle_aperture(
                image, 2*self.imparams['centerx']-self.xcentroid, 
                       2*self.imparams['centery']-self.ycentroid, 
                       config['INTENSITY_CAL']['aperture_radius'])
        #Edit to take into account aperture on other side
        self.exclusionzone  = detect_speckles.create_speckle_aperture(
                image, self.xcentroid, self.ycentroid, config['NULLING']['exclusionzone'])
        self.exclusionzone  = self.exclusionzone + detect_speckles.create_speckle_aperture(
                image, 2*self.imparams['centerx']-self.xcentroid, 
                       2*self.imparams['centery']-self.ycentroid, 
                       config['NULLING']['exclusionzone'])

        self.intensity = detect_speckles.get_speckle_photometry(image, self.aperture)
        #self.finalintensity = None
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
        #L = self.gain_intensities
        
        strictly_increasing = all(x<y for x, y in zip(self.gain_intensities, self.gain_intensities[1:]))
        strictly_decreasing = all(x<y for x, y in zip(self.gain_intensities, self.gain_intensities[1:]))
        bestgain = self.gains[self.gain_intensities.index(min(self.gain_intensities))]
        if strictly_increasing:
            self.null_gain = bestgain
        elif strictly_decreasing:
            self.null_gain = bestgain
        else:
            #fit a decreasing parabola
            a, b, c = np.polyfit(self.gains, self.gain_intensities, deg=2)
            if a<1:
                print "WARNING: got an upward sloping parabola! Using best result."
                self.null_gain = bestgain
            else:
                self.null_gain =-1.0*b/(2*a)
                if self.null_gain > max(self.gains):
                    print ("WARNING: computed gain is greater than ", 
                            max(self.gains),
                            ", using best result")
                    self.null_gain = bestgain
                elif self.null_gain < min(self.gains):
                    print ("WARNING: computed gain is greater than ", 
                            min(self.gains),
                            ", using best result")
                    self.null_gain = bestgain
                else:
                    pass
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
            #print "max: ",max," i: ",i
            sum_tmp = sum+copylist[i].exclusionzone*1.0 
            #print "test"
            #print i, (sum_tmp>1).any()
            if (sum_tmp>1).any():
                i=i+1
                sum_tmp = sum
            else:
                returnlist.append(copylist[i])
                sum = sum_tmp
                i = i+1
        return returnlist

def filterpoints(pointslist, rad = 6.0, max = 5, 
                             cx = None, cy = None):
    plist = pointslist[:]
    returnlist = []
    returnlist.append(plist[0])
    if (max == 1):
        return returnlist
    if max >1:
        i=1
    while len(plist)>max:
        try:
            sublist = plist[i:]
            bright = plist[i-1]
        except:
            return plist[0:max]
        for item in sublist:
            if ((bright[1]-item[1])**2+
                (bright[0]-item[0])**2<(rad+1)**2):
                #print "removing ", item, "for being too close to ", bright
                plist.remove(item)
            #opposite kvector as well
            elif ((bright[1] - (2*cy - item[1]))**2+
                (bright[0]-(2*cx - item[0]))**2<(rad+1)**2):
                plist.remove(item)
        i = i+1
    return plist


def generate_phase_nullmap(speckleslist, gain):
    nullmap = 0
    for speck in speckleslist:
        null_phase=speck.compute_null_phase()
        nullmap = nullmap+gain*speck.generate_flatmap(null_phase)

    return nullmap

def generate_super_nullmap(speckleslist):
    nullmap = 0
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

def printstats(field_im, speckleslist):
    percent_improvements = []
    total_ints = 0
    null_gains = []
    c_percent_improv = []
    controlled_nms= 0
    for speck in speckleslist:
        orig = speck.intensity
        final = speck.recompute_intensity(field_im)
        #print speck.xcentroid, speck.ycentroid
   
        perc_imp = 100.0*(final-orig)/orig
        percent_improvements.append(perc_imp)
        total_int = final-orig
        total_ints += total_int
        null_gains.append(speck.null_gain)
        print ("Orig intensity: "+str(int(speck.intensity))+" "+
               "Final intensity: " + str(int(final))+"  "+
               'Null Gain:' + str(speck.null_gain)+"  "+
               "Percent improv: "+str(perc_imp))
        if speck.null_gain>0:
            c_percent_improv.append(perc_imp)
            controlled_nms+= total_int
    print ("\nTotal amplitude change "+str(total_ints)+
           "\nNonzero gain amplitude change: "+str(controlled_nms)+
           "\nMean percent improvement: "+str(np.mean(percent_improvements))+
           "\nMean nonzero gain percent improvement: "+str(np.mean(c_percent_improv)))
#class regionstats:
#    def __init__(self,referenceval = 600000 ):
#        self.referenceval = referenceval 
#        self.itcounter  = []
#        self.maxfluxes = []
#        self.meanfluxes = []
#        self.totalfluxes = []
#        self.rmsfluxes = []
#    def update(field_ctrl_im):
#        meanfluxes.append(np.mean(field_ctrl_im[field_ctrl_im>0]))
#        maxfluxes.append(np.max(field_ctrl_im[field_ctrl_im>0]))
#        totalfluxes.append(np.sum(field_ctrl_im))
#        rmsfluxes.append(np.std(field_ctrl_im[field_ctrl_im>0])/referenceval)

if  __name__ == "__main__":
    configfilename = 'speckle_null_config.ini'
    configspecfile = 'speckle_null_config.spec'
    hardwareconfigfile = 'speckle_instruments.ini'
    config = ConfigObj(configfilename, configspec=configspecfile)
    val = Validator()
    check = config.validate(val)
    
    # pharo = hardware.PHARO_COM('PHARO', 
    #             configfile = hardwareconfigfile)
    # p3k = hardware.P3K_COM('P3K_COM', configfile = hardwareconfigfile)
    pharo = hardware.fake_pharo()
    p3k   = hardware.fake_p3k()

    im_params= config['IM_PARAMS']
    null_params = config['NULLING']
    abc = config['INTENSITY_CAL']['abc']

    use_centoffs = config['NULLING']['cent_off']
    
    # bgds = flh.setup_bgd_dict(config) 
    fake_bgds = {'bkgd':np.zeros((1024, 1024)), 
           'masterflat':np.ones((1024, 1024)),
           'badpix': np.zeros((1024, 1024))}
    print "WARNING: USING FAKE BGDS"
    bgds = fake_bgds.copy() 
    controlregion = pf.open(config['CONTROLREGION']['filename'])[0].data
    #Notes==>scale exptime in snr
    exp = config['INTENSITY_CAL']['exptime']
    #Setup
    initial_flatmap = p3k.grab_current_flatmap()
    initial_centoffs= p3k.grab_current_centoffs()
    
    defaultim = np.ones((1024, 1024) )

    vertsx = config['CONTROLREGION']['verticesx']
    vertsy = config['CONTROLREGION']['verticesy']
    anncentx, anncenty = vertsx[0], vertsy[0]
    annrad = np.sqrt( (vertsx[0]-vertsx[2])**2+
                      (vertsy[0]-vertsy[2])**2)
    
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
    ax3.set_title('RMS in region')
    #ax4.set_title('Phase map')
    #ax5.set_title('Intensity')

    w1 = ax1.imshow(np.log(np.abs(defaultim)), origin='lower', interpolation = 'nearest')
    ax1.set_xlim(anncentx-annrad, anncentx+annrad)
    ax1.set_ylim(anncenty-annrad, anncenty+annrad)
    #ax1.set_ylim(int(im_params['centery'])-25, int(im_params['centery']+50))
    
    w2 = ax2.imshow(np.log(np.abs(controlregion*defaultim)), origin='lower', interpolation = 'nearest')
    ax2.set_xlim(anncentx-annrad, anncentx+annrad)
    ax2.set_ylim(anncenty-annrad, anncenty+annrad)
    
    w3 = ax3.plot([],[])
    ax3.set_xlim(0, 10)
    
     
    N_iterations = 10
    itcounter  = []
    maxfluxes = []
    meanfluxes = []
    totalfluxes = []
    rmsfluxes = []
    #w5 = ax5.plot(np.arange(10)*0, np.arange(10)*0)
    
    plt.show()
    tstamp = time.strftime("%Y%m%d-%H%M%S").replace(' ', '_')
    
    
    cubeoutputdir = os.path.join(null_params['outputdir'],
                                 tstamp)
    if not os.path.exists(cubeoutputdir):
        os.makedirs(cubeoutputdir)
    print "making resultcubes 1"
    result_imagecube =  output_imagecube(
                           N_iterations, 1024, 
                           filepath = os.path.join(cubeoutputdir,
                                        'test_'+ tstamp+'.fits'),
                           comment = 'fun', 
                           configfile = configfilename)
    
    print "making resultcubes 2"
    clean_imagecube=  output_imagecube(
                           N_iterations, 1024, 
                           filepath = os.path.join(cubeoutputdir,
                                        'test_clean_'+ tstamp+'.fits'),
                           comment = 'fun', 
                           configfile = configfilename)
    
    print "making resultcubes 3"
    cal_imagecube = output_imagecube(
                            4, 1024, 
                           filepath = os.path.join(cubeoutputdir,
                                         'test_cals_'+ tstamp+'.fits'),
                           comment = 'fun', 
                           configfile = configfilename)
    cal_imagecube.update(controlregion)
    cal_imagecube.update(bgds['bkgd'])
    cal_imagecube.update(bgds['masterflat'])
    cal_imagecube.update(bgds['badpix'])
   
   
    ####MAIN LOOP STARTS HERE##### 
    print "BEGINNING NULLING LOOP" 
     
    for iteration in range(N_iterations):
        
        itcounter.append(iteration)

        if use_centoffs == False:
            current_flatmap = p3k.grab_current_flatmap()
        if use_centoffs == True:
            current_centoffs= p3k.grab_current_centoffs()
                    
        print "Taking image of speckle field"
        raw_im = pharo.take_src_return_imagedata(exptime=exp)
        result_imagecube.update(raw_im)
        field_im = pre.equalize_image(raw_im, **bgds)
        clean_imagecube.update(field_im)
        field_ctrl = field_im*controlregion
        meanfluxes.append(np.mean(field_ctrl[field_ctrl>0]))
        maxfluxes.append(np.max(field_ctrl[field_ctrl>0]))
        totalfluxes.append(np.sum(field_ctrl))
        rmsfluxes.append(np.std(field_ctrl[field_ctrl>0])/
                         config['NULLING']['referenceval'])

        ax3.plot(itcounter,rmsfluxes) 
        #w5 = plt.plot(itcounter, maxfluxes)
        #w5 = plt.plot(itcounter, totalfluxes)
        ax1.set_title('Iteration: '+str(iteration)+
                      ',  Mean: '+str(meanfluxes[iteration])+
                      ',  Max: '+str(maxfluxes[iteration]))
        w1.set_data(np.log(np.abs(field_ctrl)))
        w1.autoscale()
        plt.draw()
        plt.pause(0.02) 
        
        # Check if there is an improvement
        if iteration >0:
            printstats(field_im, speckleslist)           
            flh.writeout(current_flatmap, 'latestiteration.fits')
            print "REcomputing image center"
            
            plt.figure()
            plt.imshow(field_im)
            plt.show()

            DMR.dm_reg_autorun(field_im, configfilename, configspecfile) 
            #update configuration
            config = ConfigObj(configfilename, configspec=configspecfile)
            val = Validator()
            check = config.validate(val)
            print "REdefining control region"
            define_control_annulus_auto.run(configfilename, configspecfile)
            controlregion = pf.open(config['CONTROLREGION']['filename'])[0].data
             
        ans = raw_input('Do you want to run a speckle nulling iteration[Y/N]?')
        #ans = 'Y'
        if ans == 'N':
           flatmapans = raw_input('Do you want to reload the'+ 
                                  'flatmap/centoffs you started with[Y/N]?')
           if flatmapans == 'Y':
               print ("Reloading initial flatmap/centoffs")
               
               if use_centoffs == False:
                   status = p3k.load_new_flatmap((initial_flatmap))
               if use_centoffs == True:
                   status = p3k.load_new_centoffs((initial_centoffs))
           break
        
        print ('Iteration '+str(iteration)+
           ' total_intensity: '+str(np.sum(field_ctrl)))
        #return a list of points
        print "computing interesting bright spots"
        
        #note indices and coordinates are reversed
        ijofinterest = identify_bright_points(field_ctrl)
        xyofinterest = [p[::-1] for p in ijofinterest] 
        
        print "computed ",str(len(xyofinterest)), " bright spots"
        max_specks = config['DETECTION']['max_speckles']
        
        #if len(xyofinterest)>50:
        #    xyofinterest = xyofinterest[0:49]
        
        if len(xyofinterest)<max_specks:
            max_specks = len(xyofinterest)

        fps = filterpoints(xyofinterest, 
                           max = max_specks, 
                           rad=config['NULLING']['exclusionzone'],
                           cx = config['IM_PARAMS']['centerx'],
                           cy = config['IM_PARAMS']['centery'])
        print "creating speckle objects"
        speckleslist = [speckle(field_im, xy[0], xy[1], config) for xy in fps]
        #old way--filter the speckles
        #speckleslist =[speckle(field_im, xy[0], xy[1], config) for xy in xyofinterest]
        #speckleslist = filterspeckles(speckleslist, max = max_specks)
        phases = null_params['phases']
        for idx, phase in enumerate(phases):
            print "Phase ", phase
            phaseflat = 0
            allspeck_aps= 0
            #put in sine waves at speckle locations
            for speck in speckleslist:
                #XXX
                phaseflat= phaseflat+speck.generate_flatmap(phase)
                
                allspeck_aps = allspeck_aps+ speck.aperture
            
            ax2.set_title('Phase: '+str(phase))
            if idx == 0:
                w1.set_data( (allspeck_aps*field_ctrl)-0.95*field_ctrl)
                w1.autoscale(); plt.draw()
            #w1.set_data(field_ctrl); w1.autoscale(); plt.draw()
            
            #p3k.load_new_flatmap(phaseflat)
            if use_centoffs == False:
                status = p3k.load_new_flatmap(current_flatmap +phaseflat)
            if use_centoffs == True:
                status = p3k.load_new_centoffs(current_centoffs+
                             fmf.convert_flatmap_centoffs(phaseflat))
            #w3.set_data(phaseflat);plt.draw()
            
            phaseim = pharo.take_src_return_imagedata(exptime =exp) 
            phaseim = pre.equalize_image(phaseim, **bgds) 
            
            w2.set_data(np.log(np.abs(phaseim*controlregion)))
            w2.autoscale();plt.draw();plt.pause(0.02) 
            
            print "recomputing intensities"
            for speck in speckleslist:
                phase_int = speck.recompute_intensity(phaseim)
                speck.phase_intensities[idx] = phase_int
        
        if use_centoffs == False:
            p3k.load_new_flatmap(current_flatmap)
        if use_centoffs == True:
            p3k.load_new_centoffs(current_centoffs)
        
        if config['NULLING']['null_gain'] == False:
            defaultgain = config['NULLING']['default_flatmap_gain']
            
            nullmap= generate_phase_nullmap(speckleslist, defaultgain) 
            
            if use_centoffs == False:
                p3k.load_new_flatmap(current_flatmap + nullmap)
            if use_centoffs == True:
                p3k.load_new_centoffs(current_centoffs+ fmf.convert_flatmap_centoffs(nullmap))
            
        
        if config['NULLING']['null_gain'] == True:       
            ##NOW CALCULATE GAIN NULLS 
            print "DETERMINING NULL GAINS"
            gains = config['NULLING']['amplitudegains']
            for idx, gain in enumerate(gains):
                print "Checking optimal gains"
                nullmap= generate_phase_nullmap(speckleslist,  gain) 
                if use_centoffs == False:
                    p3k.load_new_flatmap(current_flatmap + nullmap)
                if use_centoffs == True:
                    p3k.load_new_centoffs(current_centoffs+ fmf.convert_flatmap_centoffs(nullmap))
            
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
            supernullmap = generate_super_nullmap(speckleslist)
            print "Loading supernullmap now that optimal gains have been found!"
            if use_centoffs == False:
                p3k.load_new_flatmap(current_flatmap + supernullmap)
            if use_centoffs == True:
                p3k.load_new_centoffs(current_centoffs+ fmf.convert_flatmap_centoffs(supernullmap))
            #p3k.load_new_flatmap(supernullmap)
            #w3.set_data(nullmap)
            plt.draw()


#if __name__ == "__main__":
#
#    configfilename = 'speckle_null_config.ini'
#    configspecfile = 'speckle_null_config.spec'
#
#    run(configfilename, configspecfile)
