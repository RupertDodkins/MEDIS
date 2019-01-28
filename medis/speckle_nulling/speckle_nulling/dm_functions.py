
import sn_processing as pro
# from validate import Validator
import matplotlib.pyplot as plt
import sys
import numpy as np 
import sn_math as snm
from configobj import ConfigObj
import numpy as np
# import ipdb
import sn_filehandling as flh
# from PIL import Image
# from PIL import ImageDraw
from medis.params import tp

def intensitymodel( amp, k_rad, a=0, b=0, c=0):
    """Radial dependence of spot calibration\n
    intensity = amp**2*(a*k_rad**2 + b*k_rad + c)"""
    return  amp**2*(a*k_rad**2 + b*k_rad + c)

def amplitudemodel(counts, k_rad, a=0, b=0, c=0):
    """Radial dependence of spot calibration\n
    amplitude = sqrt(counts/(a*k_rad**2 + b*k_rad + c))""" 
    #fudge = 0.5

    fudge = 1
    print(counts, a, k_rad, b, c)
    retval = fudge*np.sqrt((counts/(a*k_rad**2 + b*k_rad + c)))
    # print 'amplitudemodel', counts, k_rad, a, b, c, retval
    retval = counts/np.sqrt(c)
    if np.isnan(retval):
        print('got nan. Added by Rupert D')
        exit()
    else:
        return retval

def text_to_flatmap(text, amplitude, x=15, y=15, N=66):
    image = Image.new('L', (N,N))
    draw = ImageDraw.Draw(image)
    draw.text((x, y), text, amplitude)
    j = np.asarray(image)
    return j

def make_speckle_kxy(kx, ky, amp, dm_phase):
    """given an kx and ky wavevector, 
    generates a NxN flatmap that has 
    a speckle at that position"""
    N = tp.ao_act
    dmx, dmy   = np.meshgrid( 
                    np.linspace(-0.5, 0.5, N),
                    np.linspace(-0.5, 0.5, N))

    xm=dmx*kx*2.0*np.pi
    ym=dmy*ky*2.0*np.pi
    # print 'DM phase', dm_phase
    ret = amp*np.cos(xm + ym +  dm_phase)
    return ret

def make_speckle_xy(xs, ys, amps, phases, 
                    centerx=None, centery=None, 
                    angle = None,
                    lambdaoverd= None):
    """given an x and y pixel position, 
    generates a NxN flatmap that has 
    a speckle at that position"""
    #convert first to wavevector space
    kxs, kys = convert_pixels_kvecs(xs, ys, 
                  centerx = centerx,
                  centery = centery,
                  angle = angle,
                  lambdaoverd = lambdaoverd)
    print(angle)
    exit()
    returnmap = make_speckle_kxy(kxs,kys,amps,phases)
    return returnmap

def make_speckle_xy_old(xs, ys, amps, phases, 
                    centerx=None, centery=None, 
                    angle = None,
                    lambdaoverd= None):
    """given an x and y pixel position, 
    generates a NxN flatmap that has 
    a speckle at that position"""
    assert len(xs)==len(ys)
    assert len(xs)==len(amps)
    assert len(xs) == len(phases)
    xss = np.array(xs)
    yss = np.array(ys)
    #convert first to wavevector space
    kxs, kys = convert_pixels_kvecs(xss, yss, 
                  centerx = centerx,
                  centery = centery,
                  angle = angle,
                  lambdaoverd = lambdaoverd)
    returnmap = 0
    for idx in range(len(kxs)):
        returnmap = (returnmap+
            make_speckle_kxy(kxs[idx],kys[idx],
            amps[idx],phases[idx]))
    return returnmap

def convert_pixels_kvecs(pixelsx, pixelsy, 
                    centerx=None, centery=None,
                    angle = None,
                    lambdaoverd= None):
    """converts pixel space to wavevector space"""

    offsetx = pixelsx - centerx
    offsety = pixelsy - centery
    # print 'angle in convert_pixels_kvecs', angle
    rxs, rys = snm.rotateXY(offsetx, offsety, 
                            thetadeg = -1.0*angle)
    kxs, kys = rxs/lambdaoverd, rys/lambdaoverd
    # print kxs, kys
    return kxs, kys
                     
def convert_kvecs_pixels(kx, ky, 
                    centerx=None, centery=None, 
                    angle = None,
                    lambdaoverd= None):
    """converts wavevector space to pixel space"""
    rxs, rxy = kx*lambdaoverd, ky*lambdaoverd
    offsetx, offsety = snm.rotateXY(rxs, rxy, 
                                    thetadeg = angle)
    pixelsx = offsetx + centerx
    pixelsy = offsety + centery
    return pixelsx, pixelsy

def annularmask(N, inner, outer):
    a = np.zeros((N,N))
    ret = pro.annulus(a, float(N)/2-0.5, float(N)/2-0.5, inner, outer)
    return ret

def circularmask(N,rad):
    a = np.zeros((N,N))
    ret = pro.circle(a, float(N)/2,float(N)/2, rad)
    return ret

if __name__ == "__main__":
    N=21
    fake_flatmap = np.zeros((N,N))
    configfilename = 'speckle_null_config.ini'
    configspecfile = 'speckle_null_config.spec'
    configspec = ConfigObj(configspecfile, _inspec = True)
    config = ConfigObj(configfilename, configspec= configspec)
    val = Validator()
    test = config.validate(val)
    
    centerx = config['IM_PARAMS']['centerx']
    centery = config['IM_PARAMS']['centery']
    angle = config['IM_PARAMS']['angle']
    lambdaoverd =config['IM_PARAMS']['lambdaoverd']
    dm = config['AOSYS']['dmcyclesperap']
    abc = config['INTENSITY_CAL']['abc']

#    flh.ds9(b)

