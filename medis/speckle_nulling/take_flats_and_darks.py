import ipdb
import sys
import time
import sn_hardware as hardware
import sn_preprocessing as pre
import numpy as np
import os
import astropy.io.fits as pf
import sn_filehandling as flh 
from configobj import ConfigObj

def build_median(imagelist, outputfile = None): 
    """Takes a list of image paths and builds a median image"""
    first = True
    for image in imagelist:
        hdulist= pf.open(image)
        data = pre.combine_quadrants(hdulist)
        #data= hdulist[0].data
        #data = pre.combine_quadrants(data)
        #filesused.append(image+';   ')
        if first:
            imcube = data[:,:,np.newaxis]
            first = False
        else:            
            np.concatenate((imcube, data[:,:,np.newaxis]), axis=2)
        hdulist.close()                
    medimage = np.median(imcube, axis=2)
    if outputfile is not None:
        print "Writing median image to "+outputfile
        strfiles = [x+'; ' for x in imagelist]
        strfilesused = ("Files used to create master image:   "+
                        ''.join(strfiles))
        flh.writeout(medimage, outputfile,
                     comment = strfilesused)

    return medimage

def build_master_flat(mfminusmd, badpix=None, 
                      kernelsize = 9,
                      outputfile = 'masterflat.fits',
                      removezeros = True):
    """removes bad pixels from a background subtracted master flat"""
    im1 = pre.removebadpix(mfminusmd, badpix, kernelsize=kernelsize)
    ans = im1/np.mean(im1)
    if removezeros:
        ans=pre.removebadpix(ans, ans==0, kernelsize = kernelsize)

    flh.writeout(ans, outputfile)
    return ans

def build_master_dark(rawdark, badpix = None, outputfile='masterdark.fits'):
    ans=pre.removebadpix(rawdark, badpix)
    flh.writeout(ans, outputfile)
    return ans

def build_badpixmask(image,
            method='gaussfit',outputfile = 'badpix.fits', sigmaclip = None):
    
    if method == 'gaussfit':
        masterbadpixelmask = pre.locate_badpix(image, sigmaclip = sigmaclip)
        print "Writing badpix image to "+outputfile
        flh.writeout(masterbadpixelmask, outputfile)
    return masterbadpixelmask


if __name__ == "__main__":
    hardwareconfigfile = 'speckle_instruments.ini'
    configfilename = 'speckle_null_config.ini'
    config = ConfigObj(configfilename)
    bgdconfig= config['BACKGROUNDS_CAL']
    outputdir = config['BACKGROUNDS_CAL']['dir']
    pharo = hardware.PHARO_COM('PHARO', 
                configfile = hardwareconfigfile)
    
    localoutputdir = pharo.localoutputdir
    
    print config['BACKGROUNDS_CAL']['dir']
        

    filetypes = ['backgrounds',
                 'flats', 'flatdarks']

    #Defaults    
    print "Making default flats and badpix.  Rename these if the other ones suck"
    flh.writeout(np.ones((1024,1024)),
                os.path.join(outputdir, 'defaultflap.fits'))
    
    flh.writeout(np.zeros((1024,1024)),
                os.path.join(outputdir, 'defaultbadpix.fits'))

    #Badpix and flatdarks
    badpixdir = config['BACKGROUNDS_CAL']['flatdarkdir']
    badpixfiles = config['BACKGROUNDS_CAL']['flatdarkfiles']
    commandstring = ("\n\n\n\n Do you want to generate a bad pixel map from "+badpixdir + " files "+badpixfiles+ '[Y/N]')
    s= raw_input(commandstring)
    
    if s == 'Y':
        fnames = flh.parsenums(badpixfiles)
        fullpaths = [os.path.join(badpixdir, x) for x in fnames]
        for fn in fullpaths:
            print "scping: " + fn
            pharo.scp_specific_image(fn)
        localfiles = [os.path.join(localoutputdir, x) for x in fnames]
        print "Making median flatdark"
        med_flatdark = build_median(localfiles, outputfile=os.path.join(outputdir, 'medflatdark.fits'))
        print "Making bad pixelmask"
        bp = build_badpixmask(med_flatdark, 
            outputfile = os.path.join(outputdir,'badpix.fits'), sigmaclip = 3.2)

    elif s != 'Y':
        pass

    time.sleep(0.5)
    try:
        bp = pf.open(os.path.join(outputdir, 'badpix.fits'))[0].data
        med_flatdark = pf.open(os.path.join(outputdir, 'medflatdark.fits'))[0].data
    except:
        print ("Can't find med_flatdark and badpix.fits in "
                + outputdir+", quitting")
        sys.exit(0)


    #FLATS
    flatdir = config['BACKGROUNDS_CAL']['flatdir']
    flatfiles = config['BACKGROUNDS_CAL']['flatfiles']
    commandstring = ("\n\n\n\n Do you want to generate a master flat map from "+flatdir + " files "+flatfiles+ '[Y/N]')
    s= raw_input(commandstring)
    
    if s == 'Y':
        fnames = flh.parsenums(flatfiles)
        fullpaths = [os.path.join(flatdir, x) for x in fnames]
        for fn in fullpaths:
            print "scping: " + fn
            pharo.scp_specific_image(fn)
        localfiles = [os.path.join(localoutputdir, x) for x in fnames]
        print "Making median flat"
        med_flat = build_median(localfiles, outputfile=os.path.join(outputdir, 'medflat.fits'))
        print "Making master flat"
        mf = build_master_flat(med_flat-med_flatdark, badpix=bp,
            outputfile = os.path.join(outputdir,'masterflat.fits'))

    elif s != 'Y':
        pass

    #BGDS
    bgddir = config['BACKGROUNDS_CAL']['bgddir']
    bgdfiles = config['BACKGROUNDS_CAL']['bgdfiles']
    commandstring = ("\n\n\n\n Do you want to generate a master bgd map from "+bgddir + " files "+bgdfiles+ '[Y/N]')
    s= raw_input(commandstring)
    
    if s == 'Y':
        fnames = flh.parsenums(bgdfiles)
        fullpaths = [os.path.join(bgddir, x) for x in fnames]
        for fn in fullpaths:
            print "scping: " + fn
            pharo.scp_specific_image(fn)
        localfiles = [os.path.join(localoutputdir, x) for x in fnames]
        print "Making median bgd"
        background = build_median(localfiles,
                           outputfile = os.path.join(outputdir, 'medbackground.fits'))

    elif s != 'Y':
        pass

    #for ftype in filetypes:
    #    imnames = []
    #    commandstring = ("\n\n\n\nSet up Pharo to the configurations to take "+ftype.upper()+" then hit any key. ")
    #    s= raw_input(commandstring)

    #    
    #    if ftype == 'backgrounds':
    #        for i in range(int(config['BACKGROUNDS_CAL']['N'])):
    #            fname = pharo.take_src_return_imagename(
    #                        exptime = bgdconfig['bgdtime'])
    #            imnames.append(fname)
    #            print ftype.upper()+" taken so far: "
    #            print imnames 
    #        background = build_median(imnames,
    #                       outputfile = os.path.join(outputdir, 'medbackground.fits'))
    #        ipdb.set_trace()    
    #    if ftype == 'flats':
    #        
    #        for i in range(int(config['BACKGROUNDS_CAL']['N'])):
    #            fname = pharo.take_src_return_imagename(
    #                        exptime = bgdconfig['flattime'])
    #            imnames.append(fname)
    #            print ftype.upper()+" taken so far: "
    #            print imnames 
    #        med_flat = build_median(imnames, outputfile=os.path.join(outputdir, 'medflat.fits'))
    #            #XXXX fix flat fielding
    #    if ftype == 'flatdarks':
    #        for i in range(int(config['BACKGROUNDS_CAL']['N'])):
    #            fname = pharo.take_src_return_imagename(
    #                        exptime = bgdconfig['flattime'])
    #            imnames.append(fname)
    #            print ftype.upper()+" taken so far: "
    #            print imnames 
    #        med_flatdark = build_median(imnames, outputfile=os.path.join(outputdir, 'medflatdark.fits'))
    #
    #bp = build_badpixmask(med_flatdark, 
    #    outputfile = os.path.join(outputdir,'badpix.fits'))
#bp # = build_badpixmask(targ_bkgd-cal_bkgd,
#   # outputfile = os.path.join(outputdir,'badpix.fits'))
    #mf = build_master_flat(med_flat-med_flatdark, badpix=bp,
    #    outputfile = os.path.join(outputdir,'masterflat.fits'))
