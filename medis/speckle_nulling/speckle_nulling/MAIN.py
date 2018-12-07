import numpy as np
import pyfits as pf
from configobj import ConfigObj
import cv2
import ipdb
import matplotlib.pyplot as plt
import sn_hardware as hardware
import dm_functions as DM
import flatmapfunctions as fmap
import detect_speckles
from validate import Validator
import sn_preprocessing as pre


class speckle:
    def __init__(self, image, contour, imparams):
        self.speckleim=np.zeros(image.shape)
        self.none  = cv2.drawContours( 
                            self.speckleim,
                            [contour], 0, color = 1, 
                            thickness=-1)
        self.moments = cv2.moments(image*self.speckleim)
        self.intensity = self.moments['m00']
        self.intensity_scan = np.zeros(4)
        self.xcentroid = self.moments['m10']/self.intensity
        self.ycentroid = self.moments['m01']/self.intensity
        self.kvec      = DM.convert_pixels_kvecs(self.xcentroid,
                                                 self.ycentroid,
                                                 **imparams)
        self.kvecx     = -self.kvec[0]
        self.kvecy     = self.kvec[1]
        self.krad      = np.linalg.norm((self.kvecx, self.kvecy))
	
    def generate_flatmap(self, phase, a=None, b=None, c=None):
        """generates flatmap with a certain phase for this speckle"""
	s_amp = DM.amplitudemodel(self.intensity, self.krad, a=a, b=b, c=c)
	# print 's_amp: ', s_amp, 'self.krad: ', self.krad, 'phase: ', phase
	return DM.make_speckle_kxy(self.kvecx, self.kvecy, s_amp, phase)

class speckle2:
    def __init__(self, image, pos, imparams):
	
	cx=imparams['centerx']
	cy=imparams['centery']
	fwhm = int(imparams['lambdaoverd'])
        angle = imparams['angle']
        speckle_rad = fwhm * 2.5 *3.
        # !!!!! remove factor * 2.5 * 3. for a full aperture !!!!!!!
        aperture_mask = detect_speckles.create_speckle_mask(image, pos, cx, cy, speckle_rad)
	
	# modified attribute
	self.none  = aperture_mask
        
	self.speckleim=np.zeros(image.shape)
        self.moments = cv2.moments(image*aperture_mask)
        self.intensity = self.moments['m00']
        self.intensity_scan = np.zeros(4)
        self.xcentroid = self.moments['m10']/self.intensity
        self.ycentroid = self.moments['m01']/self.intensity
        self.kvec      = DM.convert_pixels_kvecs(self.xcentroid,
                                                 self.ycentroid,
                                                 **imparams)
        self.kvecx     = -self.kvec[0]
        self.kvecy     = self.kvec[1]
        self.krad      = np.linalg.norm((self.kvecx, self.kvecy))

	# new attributes
	self.amplitude = detect_speckles.get_speckle_photometry(image, aperture_mask)
	#self.kxy = detect_speckles.get_speckle_spatial_freq(image, pos, cx, cy, fwhm, angle)
	self.kxy = DM.convert_pixels_kvecs(pos[1],pos[0],**imparams)
        self.kx = -self.kxy[0]
	self.ky = self.kxy[1]
	self.kmod = np.linalg.norm((self.kx, self.ky))
	
    def generate_flatmap(self, phase, a=None, b=None, c=None):
        """generates flatmap with a certain phase for this speckle"""
	# s_amp = DM.amplitudemodel(self.intensity, self.krad, a=a, b=b, c=c)
	# with the new attributes of speckle2 class object	
	s_amp = DM.amplitudemodel(self.amplitude, self.kmod, a=a, b=b, c=c)
	# print 's_amp: ', s_amp, 'self.kmod: ', self.krad, 'phase: ', phase
	#return DM.make_speckle_kxy(self.kvecx, self.kvecy, s_amp, phase)
	return DM.make_speckle_kxy(self.kx, self.ky, s_amp, phase)


if __name__ == "__main__":

    configfilename = 'speckle_null_config.ini'
    hardwareconfigfile = 'speckle_instruments.ini'
    configspecfile = 'speckle_null_config.spec'
    config = ConfigObj(configfilename, configspec=configspecfile)
    val = Validator()
    check = config.validate(val)
    
    im_params = config['IM_PARAMS']
    abc = config['INTENSITY_CAL']['abc']
    phases = config['NULLING']['phases']
    cx = round(im_params['centerx'])
    cy = round(im_params['centery'])
    
    #Simulator
    #pharo = hardware.fake_pharo()
    
    #Real thing
    pharo = hardware.PHARO_COM('PHARO', 
                configfile = hardwareconfigfile)
    #LOAD P3K HERE
    p3k = hardware.P3K_COM('P3K_COM', configfile = hardwareconfigfile)
    #LOAD CURRENT FLATMAP 
    initial_flatmap = np.zeros((66, 66)) 
    initial_flatmap = p3k.grab_current_flatmap()
    status = p3k.load_new_flatmap(fmap.convert_hodm_telem(initial_flatmap))
    
    im = pharo.take_src_return_imagedata(exptime=4)#works, tested
    #bck = pre.combine_quadrants(pf.open('/data1/home/aousr/Desktop/speckle_nulling/pharoflatsdarks/medbackground.fits'))
    bck2=pf.open('/data1/home/aousr/Desktop/speckle_nulling/pharoflatsdarks_mb/medbackground.fits')[0].data
    #im = pre.equalize_image(im, bkgd=bck )
    im = im-bck2
    #im = pre.combine_quadrants(pf.open('/data1/home/aousr/Desktop/speckle_nulling/pharoimages/ph0186.fits'))


    #Replacing Mike's CV2 speckle detection with simple max search and gaussian fit 
    #speckleslist = detect_speckles.detect_speckles(im, configfile = configfilename)
    #speckleobjects = [speckle(im, contour, im_params) for contour in speckleslist]
    

    speckle_positions, speckle_amplitude = detect_speckles.detect_speckles2(im, configfile = configfilename, configspecfile=configspecfile)
    
    #speckleobjects = [speckle2(im, pos, im_params) for pos in speckle_positions]
    speckleobjects = []
    for k in range(speckle_positions.shape[1]) :
        speckleobjects.append(speckle2(im, speckle_positions[:,k], im_params))
    
    controlregion_tmp = pf.open('controlregion.fits')[0].data
    dummy = np.zeros(im.shape)
    #dummy2 = cv2.drawContours(dummy,[contour], 0, color = 1, thickness=-1)
    dummy3 = speckleobjects[0].none
    dummy4 = speckleobjects[1].none
    dummy5 = speckleobjects[2].none
    dummy6 = speckleobjects[3].none
    dummy7 = speckleobjects[4].none
    zoom = im*dummy3*controlregion_tmp # 2*dummy*im*controlregion_tmp + im
    plt.imshow(dummy3+controlregion_tmp+dummy4+dummy5+dummy6+dummy7)
    plt.show()
    #ipdb.set_trace()
    #intensities = np.zeros((len(speckleobjects), len(phases)))
    #intensities[:, 0] = np.array([x.intensity for x in speckleobjects])
    

    #figures out the initial amplitude to match to the speckle intensity
    # equiv_amps = np.array([DM.amplitudemodel(a.intensity, a.krad, **abc) for a in speckleobjects])
    # with the new attributes of speckle2 class object
    equiv_amps = np.array([DM.amplitudemodel(a.amplitude, a.kmod, **abc) for a in speckleobjects])
    
    for idx, phase in enumerate(phases):
        print "Taking image"
        flatmap_perturb = 0
        for speck in speckleobjects:
            # Generates the sine waves corresponding to all speckles and add them up
            flatmap_perturb = flatmap_perturb + speck.generate_flatmap(phase, **abc)
            #plt.figure(1)
            #plt.imshow(flatmap_perturb)
            #plt.show()
            print phase
        
        superposition = initial_flatmap + flatmap_perturb
        #plt.plot(initial_flatmap[:,33], 'b')
        #plt.plot(flatmap_perturb[:,33], 'r--')
        #plt.show()

        status = p3k.load_new_flatmap(fmap.convert_hodm_telem(superposition))
        im = pharo.take_src_return_imagedata(exptime=4)

	#ipdb.set_trace()

	#dummy = np.zeros(im.shape)
	#dummy2 = cv2.drawContours(dummy,[contour], 0, color = 1, thickness=-1) 
	# first modified version using moments
        #moments = cv2.moments(im*dummy)
	#for x in speckleobjects:
        #    x.intensity_scan[idx] = cv2.moments(im*dummy)['m00'] 
	#    print x.intensity_scan[idx] 

	# Modified way to measure the intensities (amplitudes) of the speckles
	# their position have already been detected and fitted by a gaussian profile
        position, amplitude = detect_speckles.detect_speckles2(im, speckle_positions=speckle_positions, configfile = configfilename, configspecfile=configspecfile)
        for k in range(speckle_positions.shape[1]):          
            speckleobjects[k].intensity_scan[idx] = amplitude[k]

        #recalculates speckle parameters (same locations)
        #newspeckleobjects = [speckle(im, contour, im_params) for contour in speckleslist]
	#intensities[:,idx] = np.array([x.intensity for x in newspeckleobjects])	

        
    #ipdb.set_trace()
    #use intensities luto calculate tan(abcd)
    #--> null phase

    # Compute the phase corresponding to the null
    nullmap = 0
    for speck in speckleobjects:
        A,B,C,D = speck.intensity_scan[0], speck.intensity_scan[1], speck.intensity_scan[2], speck.intensity_scan[3]
        res_scan = np.array([A,B,C,D])	
        # phase of the sine function with a reference at phases[0] (=0.)
        phase0 =  np.arctan((D-B)/(A-C))
        if phase0 < 0:
            phase0 += np.pi
        # phase of the minimum of the sine function
        null_phase = np.pi - phase0
            # there is an ambiguity of pi rad, we check that it is the minimum and not a maximum
        ind = np.argmin(np.abs(null_phase - np.array(phases)))
        if len((np.where(res_scan > res_scan[ind]))[0]) < 2:
            # if there are more points below, it means that it's a maximum, the null phase has to be shifted
            null_phase += np.pi

	# Generates the map that nulls the speckle
        nullmap = nullmap + speck.generate_flatmap(null_phase, **abc)

        print 'null_phase', null_phase

      	plt.figure(2)
        plt.plot(phases,res_scan)
        plt.plot([null_phase],[np.mean(res_scan)],'r*')
        plt.show()

	#ipdb.set_trace()
    

    status = p3k.load_new_flatmap(fmap.convert_hodm_telem(initial_flatmap + nullmap))
    im = pharo.take_src_return_imagedata(exptime=4)
    plt.imshow(im*controlregion_tmp)
    plt.show()
