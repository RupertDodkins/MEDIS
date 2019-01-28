import sn_preprocessing as pre
import os
import matplotlib.pyplot as plt
import matplotlib.cm as cm
# import astropy.io.fits as pf
# import astropy.io.fits as pf
# import ipdb
import sn_math as snm
import numpy as np
# from configobj import ConfigObj
import sn_filehandling as flh
import sn_hardware as hardware
import flatmapfunctions as FM
# from validate import Validator
import dm_functions as DM
import timeit
import time
import detect_speckles
import flatmapfunctions as fmf
import scipy.ndimage as sciim
from copy import deepcopy
import copy
# import medis.Telescope.FPWFS as FPWFS
from medis.Utils.plot_tools import quicklook_im, quicklook_wf
from medis.params import tp
import proper

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
        # print 'imparams', self.imparams
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
        #self.exclusionzone  = detect_speckles.create_speckle_aperture(
        #        image, self.xcentroid, self.ycentroid, config['NULLING']['exclusionzone'])
        #self.exclusionzone  = self.exclusionzone + detect_speckles.create_speckle_aperture(
        #        image, 2*self.imparams['centerx']-self.xcentroid, 
        #               2*self.imparams['centery']-self.ycentroid, 
        #               1.5*config['INTENSITY_CAL']['aperture_radius'])
        
        # plt.figure()
        # plt.imshow(image)
        # plt.figure()
        # plt.imshow(self.aperture)

        # plt.show()
        # ans = raw_input('press enter')
        self.intensity = detect_speckles.get_speckle_photometry(image, self.aperture)
        self.s_amp = None
        self.phase_intensities = [None, None, None, None]
        self.phases = config['NULLING']['phases']
        self.null_phase = None

        self.null_gain = None
        self.gains= config['NULLING']['amplitudegains']
        self.gain_intensities = [None, None, None, None]         

    def recompute_intensity(self, phaseimage):
        return detect_speckles.get_speckle_photometry(phaseimage, self.aperture)
    
    def generate_flatmap(self, speck_phase):
        """generates flatmap with a certain phase for this speckle"""
        # print 'intensity', self.intensity
        # ans = raw_input('press enter')
        s_amp = DM.amplitudemodel(self.intensity, self.krad, **self.abc)
        # print 'self.intensity:', self.intensity, 's_amp: ', s_amp, 'speck_phase: ', speck_phase#, 'x', self.xcentroid, 'y', self.ycentroid, 'kx', self.kvecx, 'ky', self.kvecy, 'self.krad: ', self.krad,
        self.s_amp = s_amp	
        # print s_amp
        if np.isnan(self.s_amp):
            print('commented this out. needs checking')
            exit()
            # ipdb.set_trace()
        # phase = phase - 1.9378 # got this offset by measuring phase (with quicklook_wf) when input phase is 0
        dm_phase = speck_phase + 1.9377
        if dm_phase >= np.pi: dm_phase = dm_phase-(2*np.pi)
        return DM.make_speckle_kxy(self.kvecx, self.kvecy, s_amp, dm_phase)
    
    def compute_null_phase(self, phases):
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
                print("WARNING: got an upward sloping parabola! Using best result.")
                self.null_gain = bestgain
            else:
                self.null_gain =-1.0*b/(2*a)
                if self.null_gain > max(self.gains):
                    print(("WARNING: computed gain is greater than ", 
                            max(self.gains),
                            ", using best result"))
                    self.null_gain = bestgain
                elif self.null_gain < min(self.gains):
                    print(("WARNING: computed gain is greater than ", 
                            min(self.gains),
                            ", using best result"))
                    self.null_gain = bestgain
                else:
                    pass
        print(("NULL GAIN IS: ", self.null_gain))
        return self.null_gain

def identify_bright_points(image, controlregion):
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
    return list(zip(sorted_i, sorted_j))

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

def filterpoints(pointslist, rad = 6.0, max = 5):
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
        i = i+1
    return plist



def generate_phase_nullmap(speckleslist, gain, phases):
    nullmap = 0
    for speck in speckleslist:
        null_phase=speck.compute_null_phase(phases)
        tp.null_phase = null_phase
        print(('null_phase', null_phase))
        nullmap = nullmap+gain*speck.generate_flatmap(null_phase)

    return nullmap

def generate_super_nullmap(speckleslist, phases):
    nullmap = 0
    for speck in speckleslist:
        null_phase=speck.compute_null_phase(phases)
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
        print((speck.null_phase))
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
        speck.generate_flatmap(0)
        orig = speck.intensity
        final = speck.recompute_intensity(field_im)
        #print speck.xcentroid, speck.ycentroid
   
        perc_imp = 100.0*(final-orig)/orig
        percent_improvements.append(perc_imp)
        total_int = final-orig
        total_ints += total_int
        null_gains.append(speck.null_gain)
        print(("Orig intensity: "+str(speck.intensity)+" "+
               "Final intensity: " + str(final)+"  "+
               'Null Gain:' + str(speck.null_gain)+"  "+
               "Percent improv: "+str(perc_imp)))
        if speck.null_gain>0:
            c_percent_improv.append(perc_imp)
            controlled_nms+= total_int
    print(("\nTotal amplitude change "+str(total_ints)+
           "\nNonzero gain amplitude change: "+str(controlled_nms)+
           "\nMean percent improvement: "+str(np.mean(percent_improvements))+
           "\nMean nonzero gain percent improvement: "+str(np.mean(c_percent_improv))))
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
def update_field(field_im, speckleslist):
    for speck in speckleslist:
        print((speck.xcentroid, speck.ycentroid))
        temp_field_im = field_im
        temp_field_im[speck.aperture] = 0
        plt.figure()
        plt.imshow(speck.aperture)
        plt.show()
        # print speck.aperture
        orig = speck.intensity
        final = speck.recompute_intensity(field_im)
        print(("Orig intensity: "+str(int(speck.intensity))+" "+"Final intensity: " + str(int(final))))
        speck.aperture = speck.aperture*speck.recompute_intensity(field_im)
        field_im = temp_field_im+speck.aperture
    return field_im

def get_ctrlrgnBoarder(controlregion):
    from scipy import ndimage
    controlregion = controlregion==1 # convert to Trues
    struct = ndimage.generate_binary_structure(2, 2)
    erode = ndimage.binary_erosion(controlregion, struct)
    print((type(erode), type(controlregion), np.shape(erode), np.shape(controlregion)))
    edges = controlregion ^ erode
    NaNned_edges = np.zeros((np.shape(edges)))
    NaNned_edges[edges] = np.NaN

    return NaNned_edges
# def kill_speckles(im):
#     configfilename = 'speckle_null_config_Rupe.ini'

# if __name__ == "__main__":
def speck_killing_loop(wfo):
    #configfilename = 'speckle_null_config.ini'
    #config = ConfigObj(configfilename)
    configfilename = tp.FPWFSdir+'speckle_null_config_Rupe.ini'
    hardwareconfigfile = tp.FPWFSdir+'speckle_instruments.ini'
    configspecfile = tp.FPWFSdir+'speckle_null_config.spec'
    print(configfilename)
    config = ConfigObj(configfilename, configspec=configspecfile)
    val = Validator()
    check = config.validate(val)
    
    #pharo = hardware.PHARO_COM('PHARO', 
    #            configfile = hardwareconfigfile)
    #p3k = hardware.P3K_COM('P3K_COM', configfile = hardwareconfigfile)
    camera = hardware.camera()
    ao   = hardware.ao()
    apmask = False
    if not apmask:
        aperturemask = np.ones((66,66))
    if apmask:
        aperturemask = dm.annularmask(66, 12, 33) 

    # nulled_field = None
    im_params= config['IM_PARAMS']
    null_params = config['NULLING']
    abc = config['INTENSITY_CAL']['abc']

    use_centoffs = config['NULLING']['cent_off']
    
    #bgds = flh.setup_bgd_dict(config) 
    fake_bgds = {'bkgd':np.zeros((tp.grid_size, tp.grid_size)), 
            'masterflat':np.ones((tp.grid_size, tp.grid_size)),
            'badpix': np.zeros((tp.grid_size, tp.grid_size))}
    print("WARNING: USING FAKE BGDS")
    bgds = fake_bgds.copy() 
    # controlregion = pf.open(tp.FPWFSdir+config['CONTROLREGION']['filename'])[0].data
    # controlregion = controlregion[512-int(tp.grid_size/2):512+int(tp.grid_size/2), 512-int(tp.grid_size/2):512+int(tp.grid_size/2)]
    # controlregion = np.roll(controlregion, 15)
    # controlregion[:,0:70] = 0
    # controlregion[:80] = 0
    # controlregion[-80:] = 0
    controlregion = np.zeros((tp.grid_size, tp.grid_size))
    controlregion[50:80,35:50] = 1
    boarder = get_ctrlrgnBoarder(controlregion)

    quicklook_im(controlregion, logAmp=False)
    # plt.show(block=True)

    #Notes==>scale exptime in snr
    exp = config['INTENSITY_CAL']['exptime']
    #Setup
    # initial_flatmap = ao.grab_current_flatmap()
    # initial_centoffs= ao.grab_current_centoffs()
    
    defaultim = np.ones((tp.grid_size, tp.grid_size) )

    vertsx = config['CONTROLREGION']['verticesx']
    vertsy = config['CONTROLREGION']['verticesy']
    
    # plt.ion()
    fig = plt.figure(figsize = (12, 12))
    ax1 =plt.subplot2grid((4,4),(0, 0), rowspan =2, colspan = 2)
    ax2 = plt.subplot2grid((4,4),(0, 2), rowspan =2, colspan = 2)
    ax3 =plt.subplot2grid((4,4),(3, 0)) 
    ax4 =plt.subplot2grid((4,4),(2, 2), rowspan =2, colspan = 2)
    #ax5 = plt.subplot2grid((4,4),(3,2))
    # ax1b =plt.subplot2grid((4,4),(0, 0), rowspan =2, colspan = 2)

    title = fig.suptitle('Speckle destruction')
    ax1.set_title('Image')
    ax2.set_title('Control region')
    ax3.set_title('RMS in region')
    ax4.set_title('Image')
    #ax5.set_title('Intensity')

    w1 = ax1.imshow(np.log10(np.abs(defaultim))+boarder, origin='lower', interpolation = 'nearest')
    current_cmap = cm.get_cmap()
    current_cmap.set_bad(color='white')
    # w1b = ax1b.imshow(boarder*10, origin='lower', interpolation = 'none')
    # ax1.set_xlim(min(vertsx), max(vertsx))
    # ax1.set_ylim(min(vertsy), max(vertsy))
    #ax1.set_ylim(int(im_params['centery'])-25, int(im_params['centery']+50))

    w2 = ax2.imshow(np.log(np.abs(controlregion*defaultim)), origin='lower', interpolation = 'nearest')
    # ax2.set_xlim(min(vertsx), max(vertsx))
    # ax2.set_ylim(min(vertsy), max(vertsy))
    
    w3 = ax3.plot([],[])
    ax3.set_xlim(0, 10)
    
    w4, = ax4.plot(np.abs(defaultim[64]))
    # w4 = ax4.imshow(np.log10(np.abs(defaultim))+boarder, origin='lower', interpolation = 'nearest')
    current_cmap = cm.get_cmap()
    current_cmap.set_bad(color='white')
    
    N_iterations = 10
    itcounter  = []
    maxfluxes = []
    meanfluxes = []
    totalfluxes = []
    rmsfluxes = []
    #w5 = ax5.plot(np.arange(10)*0, np.arange(10)*0)
    # w4 = ax4.imshow(np.log(camera.take_src_return_imagedata(exptime =exp)[242:758, 242:758]), origin='lower', interpolation = 'nearest')
    
    plt.show()
    tstamp = time.strftime("%Y%m%d-%H%M%S").replace(' ', '_')
    
    
    cubeoutputdir = os.path.join(null_params['outputdir'],
                                 tstamp)
    if not os.path.exists(cubeoutputdir):
        os.makedirs(cubeoutputdir)

    print(configfilename)
    result_imagecube =  output_imagecube(
                           N_iterations, tp.grid_size, 
                           filepath = os.path.join(cubeoutputdir,
                                        'test_'+ tstamp+'.fits'),
                           comment = 'fun', 
                           configfile = configfilename)
    
    clean_imagecube=  output_imagecube(
                           N_iterations, tp.grid_size, 
                           filepath = os.path.join(cubeoutputdir,
                                        'test_clean_'+ tstamp+'.fits'),
                           comment = 'fun', 
                           configfile = configfilename)
    
    cal_imagecube = output_imagecube(
                            4, tp.grid_size, 
                           filepath = os.path.join(cubeoutputdir,
                                         'test_cals_'+ tstamp+'.fits'),
                           comment = 'fun', 
                           configfile = configfilename)
    cal_imagecube.update(controlregion)
    cal_imagecube.update(bgds['bkgd'])
    cal_imagecube.update(bgds['masterflat'])
    cal_imagecube.update(bgds['badpix'])
   
   
    ####MAIN LOOP STARTS HERE##### 
    print("BEGINNING NULLING LOOP") 
     
    for iteration in range(N_iterations):
        # quicklook_wf(wfo)
        itcounter.append(iteration)

        if use_centoffs == False:
            current_flatmap = ao.grab_current_flatmap()
        if use_centoffs == True:
            current_centoffs= ao.grab_current_centoffs()
        # quicklook_im(current_flatmap, logAmp=False, show=True)
        print("Taking image of speckle field")
        # if nulled_field != None:
        #     raw_im = nulled_field
        # else:
        raw_im = camera.take_src_return_imagedata(wfo, exptime=exp)
        
        result_imagecube.update(raw_im)
        field_im = pre.equalize_image(raw_im, **bgds)
        clean_imagecube.update(field_im)

        field_ctrl = field_im*controlregion
        # print np.shape(field_im), np.shape(controlregion), np.shape(field_ctrl)
        # plt.figure()
        # plt.imshow(field_im)
        # plt.figure()
        # plt.imshow(controlregion)
        # plt.figure()
        # plt.imshow(field_ctrl)
        # plt.show(block=True)

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
        w1.set_data(np.log(np.abs(field_ctrl))+boarder)

        w1.autoscale()
        plt.draw()
        plt.pause(0.02) 
       
        if iteration >0:
            try:
                printstats(field_im, speckleslist)           
            except:
                pass
            flh.writeout(current_flatmap, 'latestiteration.fits')
        
        # ans = raw_input('Do you want to run a speckle nulling iteration[Y/N]?')
        ans = 'Y'
        if ans == 'N':
           flatmapans = eval(input('Do you want to reload the'+ 
                                  'flatmap/centoffs you started with[Y/N]?'))
           if flatmapans == 'Y':
               print ("Reloading initial flatmap/centoffs")
               
               if use_centoffs == False:
                   status = ao.load_new_flatmap((initial_flatmap))
               if use_centoffs == True:
                   status = ao.load_new_centoffs((initial_centoffs))
               #ao.load_new_flatmap(initial_flatmap)
           break
        
        print(('Iteration '+str(iteration)+
           ' total_intensity: '+str(np.sum(field_ctrl))))
        #return a list of points
        print("computing interesting bright spots")
        
        #note indices and coordinates are reversed
        ijofinterest = identify_bright_points(field_ctrl, controlregion)
        xyofinterest = [p[::-1] for p in ijofinterest] 

        print(("computed ",str(len(xyofinterest)), " bright spots"))
        max_specks = config['DETECTION']['max_speckles']
        
        #if len(xyofinterest)>50:
        #    xyofinterest = xyofinterest[0:49]
        
        if len(xyofinterest)<max_specks:
            max_specks = len(xyofinterest)

        fps = filterpoints(xyofinterest, 
                           max = max_specks, 
                           rad=config['NULLING']['exclusionzone'])
        print(fps)
        print("creating speckle objects")
        speckleslist = [speckle(field_im, xy[0], xy[1], config) for xy in fps]
        speckleslist = [x for x in speckleslist if(x.intensity)>0]
        #old way--filter the speckles
        #speckleslist =[speckle(field_im, xy[0], xy[1], config) for xy in xyofinterest]
        #speckleslist = filterspeckles(speckleslist, max = max_specks)
        phases = null_params['phases']
        # phases = [-np.pi/2.,0,np.pi/2.,np.pi]
        for idx, phase in enumerate(phases):
            print(("Phase ", phase))
            phaseflat = 0
            allspeck_aps= 0
            #put in sine waves at speckle locations
            for speck in speckleslist:
                #XXX
                # phaseflat= phaseflat+speck.generate_flatmap(phase)
                phaseflat= speck.generate_flatmap(phase)
                # quicklook_im(speck.generate_flatmap(phase), logAmp=False)
                allspeck_aps = allspeck_aps+ speck.aperture
            print('here')
            ax2.set_title('Phase: '+str(phase))
            if idx == 0:
                # w1.set_data( (allspeck_aps*field_ctrl)-0.95*field_ctrl)
                w1.set_data(np.log(np.abs((allspeck_aps*field_im)-0.95*field_im))+boarder)
                w1.autoscale(); plt.draw()
            #w1.set_data(field_ctrl); w1.autoscale(); plt.draw()


            phaseflat = phaseflat*aperturemask
            # plt.figure()
            # plt.imshow(allspeck_aps)
            # plt.show()
            # ans = raw_input('press enter')
            wf_temp = copy.copy(wfo)
            if use_centoffs == False:
                status = ao.load_new_flatmap(current_flatmap +phaseflat, wf_temp)
            # if use_centoffs == True:
            #     status = ao.load_new_centoffs(current_centoffs+
            #                  fmf.convert_flatmap_centoffs(phaseflat))
            tp.variable = proper.prop_get_phase(wf_temp)[20,20]
            print(('speck phase', tp.variable, 'intensity', proper.prop_get_amplitude(wf_temp)[20,20]))
            # plt.show(block=True)
            # quicklook_wf(wf_temp, show=True)

            phaseim = camera.take_src_return_imagedata(wf_temp, exptime =exp) 
            # quicklook_im(phaseim, show=True)
            phaseim = pre.equalize_image(phaseim, **bgds) 
            # quicklook_im(phaseim, show=True)
            w2.set_data(np.log(np.abs(phaseim*controlregion)))
            w2.autoscale();plt.draw();plt.pause(0.02) 
            
            # w4.set_data(range(128), np.sum(np.eye(tp.grid_size)*proper.prop_get_amplitude(wf_temp),axis=1))#ax4.plot(range(128),  proper.prop_get_amplitude(wf_temp)[20])#np.abs(field_im[20]))#+boarder)
            w4.set_data(list(range(128)), proper.prop_get_amplitude(wf_temp)[64])  # ax4.plot(range(128),  proper.prop_get_amplitude(wf_temp)[20])#np.abs(field_im[20]))#+boarder)
            ax4.set_xlim([0,128])
            ax4.set_ylim([0,0.2])

            print("recomputing intensities")
            for speck in speckleslist:
                phase_int = speck.recompute_intensity(phaseim)
                speck.phase_intensities[idx] = phase_int

            print((speck.phase_intensities))
            time.sleep(3)
        # if use_centoffs == False:
        #     ao.load_new_flatmap(current_flatmap, wf_temp)
        # # if use_centoffs == True:
        # #     ao.load_new_centoffs(current_centoffs)
        
        if config['NULLING']['null_gain'] == False:
            defaultgain = config['NULLING']['default_flatmap_gain']
            
            nullmap= generate_phase_nullmap(speckleslist, defaultgain, phases) 
            nullmap= nullmap*aperturemask
            if use_centoffs == False:
                # ao.load_new_flatmap(current_flatmap + nullmap, wfo)
                ao.load_new_flatmap(nullmap, wfo)
            # FPWFS.quicklook_wf(wfo)
            # camera.take_src_return_imagedata(wfo, exptime=exp)
            # if use_centoffs == True:
            #     ao.load_new_centoffs(current_centoffs+ fmf.convert_flatmap_centoffs(nullmap))
            
        # ans = raw_input('press enter')
        if config['NULLING']['null_gain'] == True:       
            ##NOW CALCULATE GAIN NULLS 
            
            print("DETERMINING NULL GAINS")
            gains = config['NULLING']['amplitudegains']
            for idx, gain in enumerate(gains):
                print("Checking optimal gains")
                nullmap= generate_phase_nullmap(speckleslist,  gain, phases) 
                nullmap= nullmap*aperturemask

                wf_temp = copy.copy(wfo)
                if use_centoffs == False:
                    ao.load_new_flatmap(current_flatmap + nullmap, wf_temp)
                # if use_centoffs == True:
                #     ao.load_new_centoffs(current_centoffs+ fmf.convert_flatmap_centoffs(nullmap))

                ampim = camera.take_src_return_imagedata(wf_temp, exptime =exp)
                # quicklook_wf(wf_temp)
                ampim = pre.equalize_image(ampim, **bgds)
                w2.set_data(np.log(np.abs(ampim*controlregion)))
                ax2.set_title('Gain: '+str(gain))
                w2.autoscale();plt.draw();plt.pause(0.02) 
                for speck in speckleslist:
                    amp_int = speck.recompute_intensity(ampim)
                    speck.gain_intensities[idx] = amp_int
                print((speck.gain_intensities))
                w4.set_data(list(range(128)), proper.prop_get_amplitude(wf_temp)[64])#ax4.plot(range(128),  proper.prop_get_amplitude(wf_temp)[20])#np.abs(field_im[20]))#+boarder)
                ax4.set_xlim([0,128])
                ax4.set_ylim([0,0.2])
            for speck in speckleslist:
                speck.compute_null_gain()
            supernullmap = generate_super_nullmap(speckleslist, phases)
            print("Loading supernullmap now that optimal gains have been found!")
            supernullmap = supernullmap*aperturemask
            if use_centoffs == False:
                # ao.load_new_flatmap(current_flatmap + supernullmap, wfo)
                ao.load_new_flatmap(supernullmap, wfo)
            # FPWFS.quicklook_wf(wfo)
            # quicklook_im(supernullmap,logAmp=False, show=True)
        

            # camera.take_src_return_imagedata(wfo, exptime=exp)
            # if use_centoffs == True:
            #     ao.load_new_centoffs(current_centoffs+ fmf.convert_flatmap_centoffs(supernullmap))
            #ao.load_new_flatmap(supernullmap)
            # w3.set_data(nullmap)

            # plt.draw()
        # w4.set_data(np.log(np.abs(field_im))+boarder)
        # plt.draw()
        # w4.autoscale();
        # quicklook_im(field_im, logAmp=False)
        quicklook_wf(wfo)
        plt.show(block=True)

        # ans = raw_input('press enter')
        # try:
        #     check = raw_input("would you like to continue?: ")
        # except EOFError:
        #     print ("Error: EOF or empty input!")
        #     check = ""
        # print check
        plt.show(block=False)
        # time.sleep(5)


        # camera.take_src_return_imagedata(wf_temp, exptime =exp) 
        # nulled_field = update_field(field_im, speckleslist)
        # print np.shape(nulled_field)
        # plt.figure()
        # plt.imshow(nulled_field)   
        # w4.set_data(np.log(nulled_field[242:758, 242:758])) 
        # null_map = nullmap
