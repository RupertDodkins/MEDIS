import ipdb
import medis.speckle_nulling.sn_hardware as hardware
import medis.speckle_nulling.sn_preprocessing as pre
import numpy as np
import os
import astropy.io.fits as pf
import medis.speckle_nulling.sn_filehandling as flh
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
            method='gaussfit',outputfile = 'badpix.fits'):
    
    if method == 'gaussfit':
        masterbadpixelmask = pre.locate_badpix(image, sigmaclip = 2.5)
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

    print ("\n\n\n\nThis script is meant to tell PHARO to take a bunch of backgrounds,\n darks, and flats, then assemble them into the correctly formatted 1024x1024 region \nthat we care about, and place them in the following directory:")
    print config['BACKGROUNDS_CAL']['dir']
    
    print ('\n\n\n\nIf this script does not work, my advice would be to bypass it completely and do it manually take some flats, backgrounds and darks.  \nAssemble them yourselves (see sn_preprocessing.py), \nparticularly combine_quadrants, locate_badpix, and save them as masterflat.fits, masterdark.fits, badpix.fits in the same directory mentioned above')

    filetypes = ['backgrounds',
                 'flats', 'flatdarks']
    
    for ftype in filetypes:
        imnames = []
        commandstring = ("\n\n\n\nSet up Pharo to the configurations to take "+ftype.upper()+" then hit any key. ")
        s= raw_input(commandstring)

        
        if ftype == 'backgrounds':
            for i in range(int(config['BACKGROUNDS_CAL']['N'])):
                fname = pharo.take_src_return_imagename(
                            exptime = bgdconfig['bgdtime'])
                imnames.append(fname)
                print ftype.upper()+" taken so far: "
                print imnames 
            background = build_median(imnames,
                           outputfile = os.path.join(outputdir, 'medbackground.fits'))
            ipdb.set_trace()    
        if ftype == 'flats':
            
            for i in range(int(config['BACKGROUNDS_CAL']['N'])):
                fname = pharo.take_src_return_imagename(
                            exptime = bgdconfig['flattime'])
                imnames.append(fname)
                print ftype.upper()+" taken so far: "
                print imnames 
            med_flat = build_median(imnames, outputfile=os.path.join(outputdir, 'medflat.fits'))
                #XXXX fix flat fielding
        if ftype == 'flatdarks':
            for i in range(int(config['BACKGROUNDS_CAL']['N'])):
                fname = pharo.take_src_return_imagename(
                            exptime = bgdconfig['flattime'])
                imnames.append(fname)
                print ftype.upper()+" taken so far: "
                print imnames 
            med_flatdark = build_median(imnames, outputfile=os.path.join(outputdir, 'medflatdark.fits'))
    
    bp = build_badpixmask(med_flatdark, 
        outputfile = os.path.join(outputdir,'badpix.fits'))
#bp  = build_badpixmask(targ_bkgd-cal_bkgd,
#    outputfile = os.path.join(outputdir,'badpix.fits'))
    mf = build_master_flat(med_flat-med_flatdark, badpix=bp,
        outputfile = os.path.join(outputdir,'masterflat.fits'))
