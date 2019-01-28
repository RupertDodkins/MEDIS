import medis.speckele_nulling.sn_filehandling as flh
import os
import numpy as np
import astropy.io.fits as pf
from configobj import ConfigObj
import ipdb
import matplotlib.pyplot as plt
import medis.speckele_nulling.sn_hardware as hardware
from validate import Validator
import medis.speckele_nulling.sn_preprocessing as pre
import medis.speckele_nulling.sn_processing as pro
from scipy.interpolate import interp1d
import medis.speckele_nulling.sn_math as snm
import dm_registration as dm
import PID as pid
from glob import glob
import time


def get_delta_I(image, cx = None, cy = None, 
                quad_width_pix = 7., inner_rad_pix = 0., 
                zone_type = None) :
    
    if zone_type == 'inner' : 
        image = image * pro.circle(image, cx, cy, inner_rad_pix)
    elif zone_type == 'outer' :
        image = image * (1 - pro.circle(image, cx, cy, inner_rad_pix))
    
    window = np.ceil(quad_width_pix*2.)
    xs, ys = np.meshgrid(np.arange(image.shape[0]), np.arange(image.shape[1]))
    subim = pre.subimage(image, (np.round(cx), np.round(cy)), window=window)
    subx = pre.subimage(xs, (np.round(cx), np.round(cy)), window=window)
    suby = pre.subimage(ys, (np.round(cx), np.round(cy)), window=window)      
    
    cumx = np.cumsum(np.sum(subim, axis = 1))
    cumy = np.cumsum(np.sum(subim, axis = 0))
    
    f_interpx = interp1d(subx[0,:], cumx)
    f_interpy = interp1d(suby[:,0], cumy)

    deltaIx = max(cumx)-2*f_interpx(cx-1)
    deltaIy = max(cumy)-2*f_interpy(cy-1)
    
    #plt.imshow(subim)
    #plt.show()
    
    return deltaIy, deltaIx
    
def tiptiltestimator_cub(delta_i_x, delta_i_y, gamma = 1., rotangle_rad = 0.):
    """ returns the estimation of tiptilt given the differential intensities """
    
    # estimation of the direction of the tip-tilt: theta
    theta = np.arctan(delta_i_y/delta_i_x)
    if delta_i_x < 0.:
        theta = theta-np.pi
    
    # amplitude of the differential intensity in that direction
    delta_i_theta = np.sqrt(delta_i_x**2.+delta_i_y**2.)
    
    # amplitude of the tip-tilt in that direction
    T_theta = (delta_i_theta/np.abs(gamma))**(1./3.)
    
    # projection on the axes of the tip-tilt mirror (takes the rotation angle into account)
    Tx = T_theta * np.cos(theta-rotangle_rad)
    Ty = T_theta * np.sin(theta-rotangle_rad)
    
    return Tx, Ty

def tiptiltestimator_lin(delta_i_x, delta_i_y, gamma = 1., rotangle_rad = 0.):
    """ returns the estimation of tiptilt given the differential intensities """
    
    # estimation of the direction of the tip-tilt: theta
    theta = np.arctan(delta_i_y/delta_i_x)
    if delta_i_x < 0.:
        theta = theta-np.pi
    
    # amplitude of the differential intensity in that direction
    delta_i_theta = np.sqrt(delta_i_x**2.+delta_i_y**2.)
    
    # amplitude of the tip-tilt in that direction
    T_theta = delta_i_theta / gamma
    
    # projection on the axes of the tip-tilt mirror (takes the rotation angle into account)
    Tx = T_theta * np.cos(theta-rotangle_rad)
    Ty = T_theta * np.sin(theta-rotangle_rad)
    
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
    
    bgds = flh.setup_bgd_dict(config)
    
    # onsky = 1 -> take real data
    # home = 1  -> analyse data already taken
    onsky=1
    home=0
    
    if onsky:
        p3k = hardware.P3K_COM('P3K_COM', configfile = hardwareconfigfile)
        pharo = hardware.PHARO_COM('PHARO', configfile = hardwareconfigfile)
        
    if home:
        # directory where the images are
        data_dir = '/home/ehuby/dev/repos/speckle_nulling/pharoimages_20150419/'
        # number of the first image        
        k0 = 215

    

    # parameters of the image
    centerx         = config['Image_params']['centerx']
    centery         = config['Image_params']['centery']
    lambdaoverd     = config['Image_params']['lambdaoverd']
    lambdaoverd_arc = config['Image_params']['lambdaoverd_arc']    
    angle           = config['AO']['rotang']*np.pi/180. # in radians
    
    # background and reference file name
    #background_file_name = config['Image_params']['background_file_name']
    #bgd = pre.combine_quadrants(pf.open(background_file_name))
    ref_file_name = config['QACITS_params']['ref_file_name']
    
    # defining the zone of interest for QACITS
    quad_width      = config['QACITS_params']['quad_width'] # in lambda/D
    inner_rad       = config['QACITS_params']['inner_rad']  # in lambda/D
    quad_width_pix  = quad_width * lambdaoverd # in pixels    
    inner_rad_pix   = inner_rad * lambdaoverd  # in pixels
    
    zone_type = config['QACITS_params']['type']
    pupil     = config['QACITS_params']['pupil']
    
    # reference values    
    Itot_off = config['QACITS_params']['Itot_off']
    DIx_ref = config['QACITS_params']['DIx_ref']
    DIy_ref = config['QACITS_params']['DIy_ref']
    
    beta     = config['QACITS_params']['beta']
    gam_in   = config['QACITS_params']['gam_in']
    gam_out  = config['QACITS_params']['gam_out']
    
    # proportionnal gain
    G        = config['PID']['Gain']
    deadband = config['PID']['deadband']

    # PID loop gains ### NOT USED ###
    """
    Kp = config['PID']['Kp']
    Ki = config['PID']['Ki']
    Kd = config['PID']['Kd']    
    # PID loop        
    p = pid.PID(P=np.array([Kp,Kp]), 
                I=np.array([Ki,Ki]),
                D=np.array([Kd,Kd]), Deadband=.01)
    p.setPoint(np.array([0.,0.]))
    """




    ### reference image (acquire image or load image)
    if ref_file_name != '':
        img = pre.combine_quadrants(pf.open(ref_file_name))
        k0+=1
    
    else :
        img = pharo.take_src_return_imagedata()
        
    img = pre.equalize_image(img, **bgds)

    delta_i_x_ref_in, delta_i_y_ref_in   = get_delta_I(img, 
                                                       cx = centerx,  cy=centery,
                                                       quad_width_pix = quad_width_pix,
                                                       inner_rad_pix  = inner_rad_pix, 
                                                       zone_type = 'inner')
    delta_i_x_ref_out, delta_i_y_ref_out = get_delta_I(img, 
                                                       cx = centerx,  cy=centery,
                                                       quad_width_pix = quad_width_pix,
                                                       inner_rad_pix  = inner_rad_pix, 
                                                       zone_type = 'outer')
    delta_i_x_ref, delta_i_y_ref         = get_delta_I(img, 
                                                       cx = centerx,  cy=centery,
                                                       quad_width_pix = quad_width_pix,
                                                       inner_rad_pix  = inner_rad_pix)


    ### file name for recording the tiptilt estimation and commands ##########
    ##########################################################################
    today=time.strftime("%Y%m%d_%H%M%S")
    save_file_name = os.path.join(os.getcwd(), 'qacits_save_files/'+today+'_')
    ipdb.set_trace()
    f=open(save_file_name+'params.txt','w+')
    f.write('Gain      = %3f\n' %(G))
    f.write('Deadband  = %3f\n' %(deadband))
    f.write('cx        = %5f\n' %(centerx))
    f.write('cy        = %5f\n' %(centery))
    f.write('angle     = %5f\n' %(angle*180./np.pi))
    f.write('lbdoverd  = %3f\n' %(lambdaoverd))
    f.write('quadwidth = %3f\n' %(quad_width))
    f.write('inner_rad = %3f\n' %(inner_rad))
    f.write('beta      = %3f\n' %(beta))
    f.write('gam_in    = %3f\n' %(gam_in))
    f.write('gam_out   = %3f\n' %(gam_out))
    f.write('Itot      = %3f\n' %(Itot_off))
    if ref_file_name != '':
        f.write('ref_file  = '+ref_file_name+'\n')
    f.write('DIx_ref   = %3f\n' %(delta_i_x_ref))
    f.write('DIy_ref   = %3f\n' %(delta_i_y_ref))
    f.write('type      = '+zone_type+'\n')    
    f.write('pupil     = '+pupil+'\n')  
    f.close()
    ##########################################################################
    ##########################################################################
    
    
    ttx_est = [] #np.zeros(N-1)
    tty_est = [] #np.zeros(N-1)
    T_x,  T_y = 0., 0.
    T_up, T_left = 0., 0.
    T_up_comm, T_left_comm = 0., 0.

    est_up = []
    est_left = []
    comm_up = []
    comm_left = []

#    N = 14
#    for k in range(N-1):
    k=0
    while True:
        
        if onsky:
            if np.abs(T_up_comm/lambdaoverd_arc) > deadband :
                p3k.sci_offset_up(T_up_comm)
                while not(p3k.isReady()) : ### waits till the AO is ready again
                    time.sleep(.1)
            if np.abs(T_left_comm/lambdaoverd_arc) > deadband :
                p3k.sci_offset_left(T_left_comm)
                while not(p3k.isReady()) : ### waits till the AO is ready again
                    time.sleep(.1)
        
            img = pharo.take_src_return_imagedata()     
        
        else :
            img_file_name = data_dir + 'ph'+str(k+k0).zfill(4)+'.fits'
            img = pre.combine_quadrants(pf.open(img_file_name))
            #img = pre.equalize_image(img, bkgd = bgd)
            
        img=pre.equalize_image(img, **bgds)

        
        ### compute the differential intensities        
        delta_i_x_in, delta_i_y_in   = get_delta_I(img, 
                                                   cx = centerx,  cy=centery,
                                                   quad_width_pix = quad_width_pix,
                                                   inner_rad_pix  = inner_rad_pix, 
                                                   zone_type = 'inner')
        delta_i_x_out, delta_i_y_out = get_delta_I(img, 
                                                   cx = centerx,  cy=centery,
                                                   quad_width_pix = quad_width_pix,
                                                   inner_rad_pix  = inner_rad_pix, 
                                                   zone_type = 'outer')
        delta_i_x_std, delta_i_y_std = get_delta_I(img, 
                                                   cx = centerx,  cy=centery,
                                                   quad_width_pix = quad_width_pix,
                                                   inner_rad_pix  = inner_rad_pix)
        
        if pupil == 'unobstructed' :
            if zone_type == 'stand': 
                delta_i_x, delta_i_y = delta_i_x_std, delta_i_y_std
                delta_i_x = (delta_i_x-delta_i_x_ref) / Itot_off  
                delta_i_y = (delta_i_y-delta_i_y_ref) / Itot_off
                Tup_est, Tleft_est = tiptiltestimator_cub(delta_i_x, delta_i_y, gamma = beta, rotangle_rad=angle)
            elif zone_type == 'inner':
                delta_i_x, delta_i_y = delta_i_x_in, delta_i_y_in
                delta_i_x = (delta_i_x-delta_i_x_ref_in) / Itot_off  
                delta_i_y = (delta_i_y-delta_i_y_ref_in) / Itot_off
                Tup_est, Tleft_est = tiptiltestimator_cub(delta_i_x, delta_i_y, gamma = beta, rotangle_rad=angle)
            elif zone_type == 'outer':
                print '[WARNING]: it is not relevant to use OUTER mode for an UNOBSTRUCTED PUPIL'
                delta_i_x, delta_i_y = delta_i_x_out, delta_i_y_out
                delta_i_x = (delta_i_x-delta_i_x_ref_out) / Itot_off  
                delta_i_y = (delta_i_y-delta_i_y_ref_out) / Itot_off
                Tup_est, Tleft_est = tiptiltestimator_cub(delta_i_x, delta_i_y, gamma = gam_out, rotangle_rad=angle)
            elif zone_type == 'both':
                print '[WARNING]: it is not relevant to use INNER-OUTER mode for an UNOBSTRUCTED PUPIL'
                delta_i_x, delta_i_y = delta_i_x_in, delta_i_y_in
                delta_i_x = (delta_i_x-delta_i_x_ref_in) / Itot_off  
                delta_i_y = (delta_i_y-delta_i_y_ref_in) / Itot_off
                Tup_in, Tleft_in = tiptiltestimator_cub(delta_i_x, delta_i_y, gamma = gam_in, rotangle_rad=angle)

                delta_i_x, delta_i_y = delta_i_x_out, delta_i_y_out
                delta_i_x = (delta_i_x-delta_i_x_ref_out) / Itot_off  
                delta_i_y = (delta_i_y-delta_i_y_ref_out) / Itot_off
                Tup_out, Tleft_out = tiptiltestimator_cub(delta_i_x, delta_i_y, gamma = gam_out, rotangle_rad=angle)

                Tup_est, Tleft_est = (Tup_in+Tup_out)/2., (Tleft_in+Tleft_out)/2.
                
        elif pupil == 'obstructed' :
            if zone_type == 'stand':
                print '[WARNING]: it is not relevant to use STANDARD mode for a CENTRALLY OBSTRUCTED PUPIL'
                delta_i_x, delta_i_y = delta_i_x_std, delta_i_y_std
                Tup_est, Tleft_est = tiptiltestimator_cub(delta_i_x, delta_i_y, gamma = beta, rotangle_rad=angle)
            elif zone_type == 'inner':
                print '[WARNING]: INNER mode only'
                delta_i_x, delta_i_y = delta_i_x_in, delta_i_y_in
                delta_i_x = (delta_i_x-delta_i_x_ref_in) / Itot_off  
                delta_i_y = (delta_i_y-delta_i_y_ref_in) / Itot_off
                Tup_est, Tleft_est = tiptiltestimator_lin(delta_i_x, delta_i_y, gamma = gam_in, rotangle_rad=angle)
            elif zone_type == 'outer':
                print '[WARNING]: OUTER mode only'
                delta_i_x, delta_i_y = delta_i_x_out, delta_i_y_out   
                delta_i_x = (delta_i_x-delta_i_x_ref_out) / Itot_off  
                delta_i_y = (delta_i_y-delta_i_y_ref_out) / Itot_off
                Tup_est, Tleft_est = tiptiltestimator_lin(delta_i_x, delta_i_y, gamma = gam_out, rotangle_rad=angle)
            elif zone_type == 'both':
                
                delta_i_x, delta_i_y = delta_i_x_in, delta_i_y_in
                delta_i_x = (delta_i_x-delta_i_x_ref_in) / Itot_off  
                delta_i_y = (delta_i_y-delta_i_y_ref_in) / Itot_off
                Tup_in, Tleft_in = tiptiltestimator_cub(delta_i_x, delta_i_y, gamma = gam_in, rotangle_rad=angle)

                delta_i_x, delta_i_y = delta_i_x_out, delta_i_y_out
                delta_i_x = (delta_i_x-delta_i_x_ref_out) / Itot_off  
                delta_i_y = (delta_i_y-delta_i_y_ref_out) / Itot_off
                Tup_out, Tleft_out = tiptiltestimator_cub(delta_i_x, delta_i_y, gamma = gam_out, rotangle_rad=angle)

                Tup_est, Tleft_est = (Tup_in+Tup_out)/2., (Tleft_in+Tleft_out)/2.
        

        # conversion in arcsec to feed the P3K tip tilt mirror        
        #Tup_est = -Tup_est*lambdaoverd_arc   ### the minus sign takes the flip into account
        Tup_est = Tup_est*lambdaoverd_arc
        Tleft_est = Tleft_est*lambdaoverd_arc
        
        ### command values
        T_up_comm   = - Tup_est  * G
        T_left_comm = -Tleft_est * G     
        
        #print 'est  tiptilt no rot  ', Tx_est, Ty_est
        print 'estimated (in lbd/D)       ', Tup_est/lambdaoverd_arc,  Tleft_est/lambdaoverd_arc
        print 'command                    ', T_up_comm/lambdaoverd_arc, T_left_comm/lambdaoverd_arc
        print '-----------'


        est_up.append(Tup_est)
        est_left.append(Tleft_est)
        comm_up.append(T_up_comm)
        comm_left.append(T_left_comm)
        

        ### record the data ##################################################        
        f=open(save_file_name+'est_Tup','a')
        f.write('%6f\n' %(Tup_est))
        f.close()
        f=open(save_file_name+'est_Tleft','a')
        f.write('%6f\n' %(Tleft_est))
        f.close()
#        f=open(save_file_name+'comm_Tup','a')
#        f.write('%6f\n' %(T_up_comm))
#        f.close()
#        f=open(save_file_name+'comm_Tleft','a')
#        f.write('%6f\n' %(T_left_comm))
#        f.close()
        ######################################################################
        
        
        
        ### DISPLAY
        # displays the subimage with the axes of the tiptilt mirror (white dashed lines)
        # and a representation of the estimated tiptilt (orientation and amplitude)

        #theta= np.arctan(delta_i_y_std/delta_i_x_std)
        theta= np.arctan(-Tleft_est/Tup_est) + angle
        if (-Tup_est) < 0.:
            theta = theta-np.pi
        subim=pre.subimage(img,(centerx,centery),np.ceil(2*quad_width_pix))
        
        # circle
        acirc = np.arange(0.,2*np.pi,2*np.pi/100.)
        xcirc = inner_rad_pix * np.cos(acirc) + quad_width_pix
        ycirc = inner_rad_pix * np.sin(acirc) + quad_width_pix
        plt.plot(xcirc, ycirc, 'w--')
        x1=quad_width_pix*np.cos(angle+np.pi) + quad_width_pix
        x2=quad_width_pix*np.cos(angle) + quad_width_pix
        y1=quad_width_pix*np.sin(angle+np.pi) + quad_width_pix        
        y2=quad_width_pix*np.sin(angle) + quad_width_pix  
        plt.plot([x1,x2],[y1,y2],'w--')
        x1=quad_width_pix*np.cos(angle+np.pi/2.) + quad_width_pix
        x2=quad_width_pix*np.cos(angle-np.pi/2.) + quad_width_pix
        y1=quad_width_pix*np.sin(angle+np.pi/2.) + quad_width_pix        
        y2=quad_width_pix*np.sin(angle-np.pi/2.) + quad_width_pix  
        plt.plot([x1,x2],[y1,y2],'w--')
        x1= quad_width_pix #quad_width_pix*np.cos(theta+np.pi) + quad_width_pix
        x2= np.sqrt(Tup_est**2.+Tleft_est**2.)/lambdaoverd_arc /.1 * inner_rad_pix*np.cos(theta) + quad_width_pix
        y1= quad_width_pix #*np.sin(theta) + quad_width_pix        
        y2= np.sqrt(Tup_est**2.+Tleft_est**2.)/lambdaoverd_arc /.1* inner_rad_pix*np.sin(theta) + quad_width_pix  
        plt.plot([x1,x2],[y1,y2],'c')        
        #plt.title(str(k0+k).zfill(2))        
        plt.imshow(subim)
        plt.show()
        """plt.savefig('figures/tt_subim_'+str(k0+k).zfill(2)+'.png')
        plt.clf()"""
        
        
        k+=1
    
    if home:
        ks = np.arange(N-1) + k0
        plt.plot(ks,np.asarray(est_up)/lambdaoverd_arc,'bo', label = 'x - up/down - south/north')
        plt.plot(ks,np.asarray(est_left)/lambdaoverd_arc,'rs', label = 'y - left/right - east/west')
        plt.plot([k0,k0+N-1],[0,0],'k--')
        plt.ylim(-1.,1.)
        plt.ylabel(r'$\lambda/D$')
        plt.legend(loc='upper right')
        plt.savefig('figures/tiptilt_corr_loop.png')
        #plt.show()
