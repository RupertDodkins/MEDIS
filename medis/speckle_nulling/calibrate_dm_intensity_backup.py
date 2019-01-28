from __future__ import division
import matplotlib.pyplot as plt
import ipdb
from validate import Validator
import numpy as np 
import medis.speckele_nulling.sn_math as snm
from configobj import ConfigObj
import numpy as np
import flatmapfunctions as FM
import medis.speckele_nulling.dm_functions as DM
import medis.speckele_nulling.sn_hardware as hardware
import medis.speckele_nulling.sn_preprocessing as pre
import scipy.optimize as opt
from detect_speckles import create_speckle_mask
import time

def onpress( event):
    xi, yi = (int(round(n)) for n in (event.xdata, event.ydata))
    print xi, yi
    xypixels.append( (xi, yi))
    if len(xypixels) == 4:
        fig.canvas.mpl_disconnect(cid)
    pass
    #return (xi, yi )


if __name__ == "__main__":
    #Load config file, check configuration file for errors
    hardwareconfigfile = 'speckle_instruments.ini'
    configfilename = 'speckle_null_config.ini'
    configspecfile = 'speckle_null_config.spec'
    config = ConfigObj(configfilename, configspec= configspecfile)
    val = Validator()
    check = config.validate(val)

    intconf = config['INTENSITY_CAL']
    im_params = config['IM_PARAMS']
    centerx = config['IM_PARAMS']['centerx']
    centery = config['IM_PARAMS']['centery']
    fwhm = float(config['IM_PARAMS']['lambdaoverd'])*3./2. # pixels per lambda/D
    exp = intconf['exptime']
    DMamp = int(intconf['default_dm_amplitude'])
    
    #ThIS NEEDS TO BE REPLACED WITH REAL PHARO AND P3K

    #pharo = hardware.fake_pharo()
    #Real thing
    pharo = hardware.PHARO_COM('PHARO', 
                configfile = hardwareconfigfile)
    #LOAD P3K HERE
    p3k = hardware.P3K_COM('P3K_COM', configfile = hardwareconfigfile)
    
    #current implementation has a background consisting of
    #star + waffle
    #possibly use this as a background
    initial_flatmap = p3k.grab_current_flatmap()
    #with_waffle = FM.add_waffle(initial_flatmap, 50) 
    #print ("sending new flatmap to p3k")
    #status = p3k.load_new_flatmap(FM.convert_hodm_telem(with_waffle))

    #replace with pharo.take_src_return_imagedata()
    firstim = pharo.take_src_return_imagedata(exptime = exp)#works, tested
    	

    #initialize range to test 
    kr = np.arange(intconf['min'],
                   intconf['max'],
                   intconf['stepsize'])  
    #initial_flatmap = FM.convert_hodm_telem(initial_flatmap)

    #Set up display area
    plt.ion()
    fig = plt.figure(figsize = (12, 12))
    ax1 =plt.subplot2grid((4,4),(0, 0), rowspan =3, colspan = 3)
    ax2 =plt.subplot2grid((4,4),(3, 0)) 
    ax3 =plt.subplot2grid((4,4),(3, 3))
    title = fig.suptitle('Intensity Calibration')
    ax1.set_title('Image-Original Image')
    ax2.set_title('Default DM map')
    ax3.set_title('Map perturbation')
    w1 = ax1.imshow(np.log(np.abs(firstim)), origin='lower', interpolation = 'nearest')
    ax1.set_xlim((centerx - 256, centerx+256))
    ax1.set_ylim((centery - 256, centery+256))
    w2 = ax2.imshow(initial_flatmap, origin='lower', interpolation = 'nearest')
    w3 = ax3.imshow(initial_flatmap, origin='lower', interpolation = 'nearest') 
    plt.show()
    
    
    xypixels = []
    ximcoords, yimcoords = np.meshgrid(np.arange(firstim.shape[0]),
                                      np.arange(firstim.shape[1]))

    actual_kvector_array = []
    intensity_array = []

    for kvecr in kr:
        if not intconf['auto']:
            title.set_text("Click on the 4 spots, then hit enter.  Kr: "+str(kvecr))
        if intconf['auto']:
            title.set_text("Kr: "+str(kvecr))
        #Check this line
        additionmapx = DM.make_speckle_kxy(kvecr, 0,DMamp , 0) 
        additionmapy = DM.make_speckle_kxy(0,kvecr, DMamp, 0) 
        additionmap = additionmapx + additionmapy
	#ipdb.set_trace()
        #THIS NEEDS TO BE UNCOMMENTED ONCE THE FUNCTION IS WRITTEN 
        #AS WELL AS PHARO!!
        status = p3k.load_new_flatmap(initial_flatmap+additionmap)
        #ipdb.set_trace()

        im = pharo.take_src_return_imagedata(exptime = exp)-firstim
        
        w3.set_data(additionmap)
        w1.set_data(np.log(np.abs(im)))
        plt.draw()
        plt.pause(0.01)
        if not intconf['auto']:
            cid = fig.canvas.mpl_connect('button_press_event', onpress)
            w = raw_input("Click the four spots then press enter in this window\n")
        if intconf['auto']:
            xy0 = DM.convert_kvecs_pixels(kvecr, 0, **im_params)
            xy1 = DM.convert_kvecs_pixels(-kvecr, 0, **im_params)
            xy2 = DM.convert_kvecs_pixels(0,kvecr, **im_params)
            xy3 = DM.convert_kvecs_pixels(0,-kvecr, **im_params)
            xypixels = [xy0, xy1, xy2, xy3]

        print "Fitting spot amplitudes and positions"
        #loops over the spots you clicked
        meanintensity = 0
        meankvec = 0
        meanphotom = 0


        for idx, xy in enumerate(xypixels):
            subim = pre.subimage(im, xy, window = 10)
            subx  = pre.subimage(ximcoords, xy, window = 10)
            suby  = pre.subimage(yimcoords, xy, window = 10)
            gauss_params = snm.fitgaussian((subx, suby), subim)
            amplitude = gauss_params[0]

            #convert pixels returns an xy pair.
            # in theory all the kvecs should be (x, 0) or (0, y)
            # in which case the norm will be equal to x or y
            kvec = np.linalg.norm(
                    DM.convert_pixels_kvecs(gauss_params[1], 
                                           gauss_params[2],
                                           **im_params))
            print "Gaussian centroid", gauss_params[1], gauss_params[2]
            print "corr. k-vector", kvec
            meanintensity = (meanintensity*float(idx)/float(idx+1) + 
                             amplitude/float(idx+1))
            meankvec = (meankvec*float(idx)/float(idx+1) + 
                             kvec/float(idx+1))
	    print gauss_params[2],gauss_params[1]
	    aperture = create_speckle_mask(im, [gauss_params[2],gauss_params[1]], centerx, centery, fwhm)
	    photometry = np.sum(im*aperture)/np.sum(aperture)
	    #ipdb.set_trace()

	    meanphotom = (meanphotom*float(idx)/float(idx+1) + 
                             photometry/float(idx+1))

        print ("\nMean Intensity: "+str(meanintensity) +
               "\nIntended radial k-vector: "+str(kvecr) +
               "\nMean k-vector: " + str(meankvec))
        #intensity_array.append(meanintensity)
        intensity_array.append(meanphotom)
        actual_kvector_array.append(meankvec)
        xypixels = []
    plt.ioff()
    plt.close('all')
    print ("\n Intended K-vectors")
    print (kr) 
    print ("\n Actual K-vectors")
    print (actual_kvector_array)
    print ("\n Intensities")
    print (intensity_array)
   
    #FIT THE FUNCTION 
    print "\n Performing global fit"       
    popt, pcov = opt.curve_fit(lambda x, ra, rb, rc: DM.intensitymodel(DMamp, x, a=ra, b=rb, c=rc), 
                                np.array(actual_kvector_array), np.array(intensity_array))
    fita, fitb, fitc = popt[0], popt[1], popt[2]
    
    print "Writing out a,b,c fit parameters to configfile"
    config['INTENSITY_CAL']['abc']['a'] = fita
    config['INTENSITY_CAL']['abc']['b'] = fitb
    config['INTENSITY_CAL']['abc']['c'] = fitc
    config.write()
    
    print "Reloading initial flatmap"
    a = p3k.load_new_flatmap(initial_flatmap )

    smoothks = np.arange(min(actual_kvector_array), max(actual_kvector_array), .01)
    
    plt.plot(actual_kvector_array, intensity_array, '.')
    plt.plot(smoothks, DM.intensitymodel(DMamp, smoothks, a=fita, b=fitb, c=fitc))
    plt.xlabel('actual k-vectors')
    plt.ylabel('intensity [counts]')
    plt.title('Data and fit')
    plt.show()
