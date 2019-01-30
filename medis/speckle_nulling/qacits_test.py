import numpy as np
import astropy.io.fits as pf
from configobj import ConfigObj
import ipdb
import matplotlib.pyplot as plt
import medis.speckle_nulling.sn_hardware as hardware
from validate import Validator
import medis.speckle_nulling.sn_preprocessing as pre
import medis.speckle_nulling.sn_processing as pro
from scipy.interpolate import interp1d
import medis.speckle_nulling.sn_math as snm
import dm_registration as dm
import PID as pid
from glob import glob
import time
import qacits_control as qa


def tiptiltestimator_circle(image, cx=None, cy= None, beta = None,
                     lambdaoverd=None, window = None):
    def cuberoot(x):
        if x<0:
            return -(-x)**(1.0/3)
        else:
            return x**(1.0/3)

    xs, ys = np.meshgrid(np.arange(image.shape[0]),
                         np.arange(image.shape[1]))
    subim = pre.subimage(image, (round(cx), round(cy)), window=window)
    subx = pre.subimage(xs, (round(cx), round(cy)), window=window)
    suby = pre.subimage(ys, (round(cx), round(cy)), window=window)
    
    cumx = np.cumsum(np.sum(subim, axis = 1))
    cumy = np.cumsum(np.sum(subim, axis = 0))
    
    f_interpx = interp1d(subx[0], cumx)
    f_interpy = interp1d(suby[:,0], cumy)

    deltaIx = max(cumx)-2*f_interpx(cx)
    deltaIy = max(cumy)-2*f_interpy(cy)

    Tx = cuberoot(deltaIx/beta)*cuberoot(deltaIx**2/(deltaIx**2+deltaIy**2))
    Ty = cuberoot(deltaIy/beta)*cuberoot(deltaIy**2/(deltaIx**2+deltaIy**2))
    return Tx, Ty

def tiptiltestimator(delat_i_x, delta_i_y, gamma = 1., rotangle = 0.):
    
    # tip-tilt estimation
    theta = np.arctan2(delta_i_y,delta_i_x)
    delta_i_theta = np.sqrt(delta_i_x**2.+delta_i_y**2.)
    T_theta = (delta_i_theta/gamma)**(1./3.)
    
    Tx = T_theta * np.cos(theta+rotangle)
    Ty = T_theta * np.sin(theta+rotangle)
    
    return Tx, Ty
    
def create_1D_DSP(N, power):
    DSP = (np.arange(0,N))**power
    DSP[0] = 0.
    return DSP

def generate_sequence(DSP, std):
    N=DSP.shape[0]
    i = np.complex(0.,1.)
    rand_tab = np.random.randn(N) + i * np.random.randn(N)

    t = np.abs(np.fft.fft(rand_tab*np.sqrt(DSP))/N)
    t = t - np.mean(t)
    
    # standard deviation
    stdev_actual = np.sqrt(np.mean(t**2.))
    t = t * std / stdev_actual  
    
    return t

if __name__ == "__main__":
    configfilename = 'qacits_config.ini'
    hardwareconfigfile = 'speckle_instruments.ini'
    configspecfile = 'qacits_config.spec'
    config = ConfigObj(configfilename, configspec=configspecfile)
    val = Validator()
    check = config.validate(val)
    
    lab=1
    home=0
    
    if lab:
        p3k = hardware.P3K_COM('P3K_COM', configfile = hardwareconfigfile)
        pharo = hardware.PHARO_COM('PHARO', configfile = hardwareconfigfile)

    # parameters defining the zone of interest
    centerx = config['Image_params']['centerx']
    centery = config['Image_params']['centery']
    spotcenters = np.resize(config['Image_params']['spotcenters_init'], (4,2))
    quad_width_pix = config['Image_params']['quad_width'] * config['Image_params']['lambdaoverd']
    inner_rad_pix = config['Image_params']['inner_rad'] * config['Image_params']['lambdaoverd']
    lambdaoverd_arc = config['Image_params']['lambdaoverd_arc']    
    # reference values    
    Itot_off = config['QACITS_params']['Itot_off']
    DIx_ref = config['QACITS_params']['DIx_ref']
    DIy_ref = config['QACITS_params']['DIy_ref']
    background_file_name = config['Image_params']['background_file_name']
    beta = config['QACITS_params']['beta']

    bgd = pre.combine_quadrants(pf.open(background_file_name))


    # PID loop gains
    Kp = config['PID']['Kp']
    Ki = config['PID']['Ki']
    Kd = config['PID']['Kd']
    
    #ipdb.set_trace()
    
    # PID loop        
    p = pid.PID(P=np.array([Kp,Kp]), 
                I=np.array([Ki,Ki]),
                D=np.array([Kd,Kd]), Deadband=.01)
    p.setPoint(np.array([0.,0.]))


    # Simulation of tiptilt drift
    dsp_power = 2.
    N = 20
    std = .05
    
    
    directory ='tiptilt_sequences/'
    filename = 'tiptilt_sequence_N'+str(N)+'_dsppow'+str(dsp_power)+'_std'+str(std)+'.txt'
    
    
    # filename = 'tiptilt_sequence_N'+str(N)+'_ramp_slope05_dirx'
    
    file = glob(directory+'*'+filename)
    
    if file == [] :
        print '##### CREATE SEQUENCE #####'
        DSP = create_1D_DSP(N, dsp_power)
        ttx = generate_sequence(DSP,std)
        tty = generate_sequence(DSP,std)
        f=open(directory+'x'+filename,'w')
        for k in range(N) : f.write('%6f \n' %(ttx[k]))
        f.close()
        f=open(directory+'y'+filename,'w')
        for k in range(N) : f.write('%6f \n' %(tty[k]))
        f.close()
    else:
	print '##### LOAD SEQUENCE #####'
        ttx=np.zeros(N)
        tty=np.zeros(N)
        f=open(directory+'x'+filename,'r')
        for k in range(N) : ttx[k] = f.readline()
        f.close()
        f=open(directory+'y'+filename,'r')
        for k in range(N) : tty[k] = f.readline()
        f.close()

    ipdb.set_trace()


    if lab:   
        img = pharo.take_src_return_imagedata()

    if lab:
        p3k.sci_offset_up(ttx[0])
        while not(p3k.isReady()) :
            time.sleep(.1)
        p3k.sci_offset_left(tty[0])
        while not(p3k.isReady()) :
            time.sleep(.1)


    ipdb.set_trace()

    dtx = ttx[1:]-ttx[:-1]
    dty = tty[1:]-tty[:-1]

    k0 = 185

    ttx_est = np.zeros(N-1)
    tty_est = np.zeros(N-1)
    Tx_est, Tup_pid = 0., 0.
    Ty_est, Tleft_pid = 0., 0.


    G = 0.9


    for k in range(N-1):

        if lab:
            # inject tiptilt from the sequence
            # p3k.sci_offset_up(dtx[k]+Tup_pid)
	    p3k.sci_offset_up(Tup_pid)
            while not(p3k.isReady()) :
                time.sleep(.1)
            #p3k.sci_offset_left(dty[k]+Tleft_pid)
            p3k.sci_offset_left(Tleft_pid)
            while not(p3k.isReady()) :
                time.sleep(.1)
        
            img = pharo.take_src_return_imagedata()
            
        else :
            dir = '/home/ehuby/dev/repos/speckle_nulling/pharoimages/'
            img_file_name = dir + 'ph'+str(k+k0).zfill(4)+'.fits'
            img = pre.combine_quadrants(pf.open(img_file_name))
            #img = pre.equalize_image(img, bkgd = bgd)
        
        img=img-bgd
                               
        # Derive center of the image from the satellite spots
#        if c == 1 :
#            spotcenters = dm.get_satellite_centroids(img)
#        else :
#            spotcenters = fit_satellite_centers(img, spotcenters, window=20)
        
        #spotcenters = fit_satellite_centers(img, spotcenters, window=20)
        #centerx, centery = np.mean(spotcenters, axis = 0)
        #print 'center x', centerx, 'centery', centery
        
        
        delta_i_x, delta_i_y = qa.get_delta_I(img, cx = centerx, cy=centery,
                                quad_width_pix = quad_width_pix,
                                inner_rad_pix = inner_rad_pix )#,zone_type = "inner")

        #delta_i_x = (delta_i_x - DIx_ref) / Itot_off  
        #delta_i_y = (delta_i_y - DIy_ref) / Itot_off   
        
        delta_i_x = (delta_i_x) / Itot_off  
        delta_i_y = (delta_i_y) / Itot_off  

        # tip tilt estimator in lambda over D        
        Tx_est, Ty_est = tiptiltestimator(delta_i_x, delta_i_y, gamma = beta)
        # conversion in arcsec to feed the P3K tip tilt mirror
        Tx_est = Tx_est*lambdaoverd_arc
        Ty_est = Ty_est*lambdaoverd_arc    
        
        #Tup_est, Tleft_est = snm.rotateXY(Tx_est, Ty_est, config['AO']['rotang'])
        Tup_est, Tleft_est = tiptiltestimator(delta_i_x, delta_i_y, gamma = beta, rotangle=config['AO']['rotang'])        
        Tup_est = -Tup_est*lambdaoverd_arc
        Tleft_est = Tleft_est*lambdaoverd_arc
        ttx_est[k] = Tup_est
        tty_est[k] = Tleft_est 
        
        # command value according to PID loop
        print 'com tiptilt         ', ttx[k+1]/lambdaoverd_arc, tty[k+1]
        print 'est tiptilt no rot  ', Tx_est/lambdaoverd_arc, Ty_est/lambdaoverd_arc
        print 'est tiptilt         ', Tup_est/lambdaoverd_arc, Tleft_est/lambdaoverd_arc
        #Tx_est, Ty_est = 0.8*[Tx_est,Ty_est] #
        #Tup_pid, Tleft_pid = p.update([Tup_est,Tleft_est])
	Tup_pid   = - G * Tup_est
	Tleft_pid = - G * Tleft_est 
	print 'est by PID          ', Tup_pid/lambdaoverd_arc, Tleft_pid/lambdaoverd_arc

        #print 'est tiptilt PID', Tx_est, Ty_est
        print '-----------'
        
        subim=pre.subimage(img,(centerx,centery),2*quad_width_pix)
        plt.imshow(subim)
        plt.show()

	#Tup_pid = 0.
	#Tleft_pid = 0.

    #plt.plot(ttx[1:], tty[1:])
    #plt.plot(ttx_est,tty_est)
    #plt.show()
    
        #ipdb.set_trace()
        
    #plt.plot(ttx[1:], ttx_est, 'bo')
    #plt.plot(tty[1:], tty_est, 'ro')
    #plt.show()
