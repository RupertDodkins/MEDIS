# from __future__ import print_function
# from configobj import ConfigObj
import numpy as np
import pdb
# import serial
import os.path
import os, sys
import time
import socket
# import ipdb
import subprocess
import pyfits as pf
import flatmapfunctions
# import pexpect
#GLOBAL FUNCTION
verbose=True
# print = print if verbose else lambda *a, **k: None
# import matplotlib.pyplot as plt
sys.path.append(os.path.dirname(os.path.dirname(os.path.dirname(os.path.realpath(__file__)))) + "/active_nuller")
# sys.path.append(os.path.dirname(os.path.realpath(__file__)) + "/../../active_nulling")
# print os.path.dirname(os.path.realpath(__file__)) + "/../../active_nulling"
# import Telescope.FPWFS as FPWFS
import proper

class fake_pharo():
    """a fake PHARO simulator; returns a random image from 
       fake_data.fits plus some random noise"""
    def __init__(self):
        self.i= 0.0 
    def get_image(self):
        1#print("Warning, using fake pharo simulator!")
        self.i=self.i+1
        seed = np.random.randint(0, 28)
        imdata = np.zeros((1024, 1024))
        # imdata[256:256+512, 256:256+512]=pf.open('fake_data.fits')[0].data[seed]
        imdata = np.array(pf.open('Rupe2.fits')[0].data)*3000
        randnoise = np.abs(np.random.normal(15, 12, (1024, 1024)))
        return imdata+randnoise
    def take_src_return_imagedata(self, exptime = 4):
        return self.get_image()

class fake_p3k():
    def __init__(self):
        self.i = 0.0
    def warn(self):
        1#print("Warning, using fake p3k!!")
    pass

    def getstatus(self):
        return self.warn()
    def grab_current_centoffs(self):
        return self.warn()
    def grab_current_flatmap(self):
        return np.zeros((66,66))
    def load_new_flatmap(self, fmap):
        return self.warn()
    def safesend2(self, thing):
        return self.warn()

class camera():
    """simulator for the MKID array\n
        add links to the detector degradation code here"""
    def __init__(self):#obj_map
        self.i= 0.0 
        diam = 0.1                 # telescope diameter in meters
        f_lens = 24 * diam    
    def take_src_return_imagedata(self, wfo, exptime = 4):
        1#print("Warning, using fake pharo simulator!")
        self.i=self.i+1
        # imdata = np.zeros((1024, 1024))
        # FPWFS.propagate_DM(wfo, f_lens, obj_map)
        # FPWFS.quicklook_wf(wfo)
        # FPWFS.quicklook_wf(wfo)
        return proper.prop_get_amplitude(wfo)

class ao():
    """the DM optics"""
    def __init__(self):
        self.i = 0.0

        self.obj_map = np.zeros((66,66))       
    def warn(self):
        1#print("Warning, using fake p3k!!")
    pass

    def getstatus(self):
        return self.warn()
    def grab_current_centoffs(self):
        return self.warn()
    def grab_current_flatmap(self):
        return self.obj_map
    def load_new_flatmap(self, fmap, wfo):
        self.obj_map = fmap
        diam = 5.0                 # telescope diameter in meters
        f_lens = 20 * diam 
        FPWFS.propagate_DM(wfo, f_lens, fmap)
        # FPWFS.quicklook_wf(wfo)
        return wfo
    def safesend2(self, thing):
        return self.warn()
# #class PHARO_COM:
# #    
# #    def __init__(self, name, configfile = ''):
# #        configObj = ConfigObj(configfile)
# #        #configure_pharo_dir
# #        #self.datapath = self.get_data_path()
# #
# #        self.name=name
# #        try:
# #            PHAROconfig = configObj[self.name]
# #        except:
# #            print('ERROR accessing ', self.name, ".", 
# #                   self.name, " was not found in the configuration file", configfile)
# #            return 
# #        
# #        print ("WARNING : PHARO DIRECTORY SET TO DEFAULT")
# #        self.pharoimagedir = PHAROconfig['Setup']['pharoimagedir']
# #        self.localoutputdir = PHAROconfig['Setup']['localoutputdir']
# #        self.timedelay = PHAROconfig['Setup']['timedelay']
# #        self.logfile = os.path.join(self.localoutputdir, 
# #                               PHAROconfig['Setup']['logfile'])
# #
# #        if not os.path.exists(self.localoutputdir):
# #            print( "Creating local output directory: "+self.localoutputdir)
# #            os.makedirs(self.localoutputdir)
# #        if not os.path.isfile(self.logfile):
# #            print( "Creating logfile at "+self.logfile)
# #
# #        try:
# #            self.pharo_p3k = P3K_COM('P3K_COM', configfile=configfile)
# #        except:
# #            print("Warning: No P3K connection")
# #
# #        return
# #
# #    def logdata(self, commentstring):
# #        with open(self.logfile,'a+') as lf:
# #            lf.write(commentstring+'\n')
# #
# #    def combine_quadrants(self, image):
# #        """combines the four pharo quadrants into a unified image"""
# #        quad1=(image[0].data)[0,:,:]
# #        quad2=(image[0].data)[1,:,:]
# #        quad3=(image[0].data)[2,:,:]
# #        quad4=(image[0].data)[3,:,:]
# #        
# #        toprow=np.hstack((quad2, quad1))
# #        bottomrow=np.hstack((quad3, quad4))
# #        returnimage=np.vstack((toprow, bottomrow))
# #        #nb--in the reduction pipeline the following is commnented in 
# #        #in this program WYSIWYG with PHARO;s monitor
# #        #returnimage = returnimage[:,::-1]
# #        return returnimage
# #    
# #    def get_latest_image_name(self):
# #        """gets the name of the latest image in the PHARO ezra2 output directory"""
# #        stdout, stderr = subprocess.Popen(
# #                            ['ssh', 
# #                            'pharo@ezra2.palomar.caltech.edu', 
# #                            'ls '+self.pharoimagedir], 
# #                             stdout=subprocess.PIPE).communicate()
# #        listoffiles=stdout.split('\n')
# #        fitsfiles=[x for x in listoffiles if 'fits' in x]
# #        numlist = []
# #        for fitsfile in fitsfiles:
# #            numlist.append( int(''.join(a for a in fitsfile if a.isdigit())))
# #        maxind = numlist.index(max(numlist))
# #        return os.path.join(self.pharoimagedir, fitsfiles[maxind])
# #    
# #    def get_allfiles(self):
# #        """get a list of all the files in teh PHARO ezra2 output directory"""
# #        stdout, stderr = subprocess.Popen(
# #                            ['ssh', 
# #                            'pharo@ezra2.palomar.caltech.edu', 
# #                            'ls '+self.pharoimagedir], 
# #                             stdout=subprocess.PIPE).communicate()
# #        listoffiles=stdout.split('\n')
# #        fitsfiles=[x for x in listoffiles if 'fits' in x]
# #        return [os.path.join(self.pharoimagedir, x) for x in fitsfiles]
# #
# #    def scp_latest_image(self):
# #        """gets the latest image in the ezra2 directory and 
# #        saves it to the local dir. returns the path to the image
# #        on the LOCAL output directory"""
# #        filename = self.get_latest_image_name()
# #        stdout, stderr = subprocess.Popen(
# #                            ['scp', 'pharo@ezra2.palomar.caltech.edu:'+filename, 
# #                            self.localoutputdir], stdout=subprocess.PIPE).communicate()
# #        for s in [stdout, stderr]:
# #            if s is not None:
# #                #pass
# #                print(s)
# #        return  os.path.join(self.localoutputdir,filename.split('/')[-1])
# #        
# #    def scp_specific_image(self, imagename):
# #        """grabs a specific image from the local dir"""
# #        stdout, stderr = subprocess.Popen(
# #                            ['scp', 'pharo@ezra2.palomar.caltech.edu:'+imagename, 
# #                            self.localoutputdir], stdout=subprocess.PIPE).communicate()
# #        for s in [stdout, stderr]:
# #            if s is not None:
# #                print(s)
# #        return 
# #    
# #    def take_src(self, exptime):
# #        """takes an image on pharo. does not return anything""" 
# #        #self.pharo_p3k.safesend2('pharo take_srcimage 2')        
# #        self.pharo_p3k.safesend2('pharo take_srcimage '+ str(int(exptime)))
# #        return
# #
# #    def take_src_return_imagename(self, exptime=2):
# #        """takes an image on pharo and returns the path
# #        to the image on the local computer"""
# #        previousfiles = self.get_allfiles()
# #        if len(previousfiles)>0:
# #            latest = previousfiles[-1]
# #        else:
# #            latest = None
# #        self.take_src(exptime)
# #        #if latest image is in initial files (ie the most recent)
# #        #one hasn't been written yet, keep looking
# #        time.sleep(float(self.timedelay))
# #        while latest in previousfiles:
# #            print('hi')
# #            latest = self.get_latest_image_name()
# #        return self.scp_latest_image() 
# #        
# #    def take_src_return_imagedata(self, exptime=2, piezopos = None):
# #        """takes an image on pharo and returns a numpy array
# #        of the combined 1024x1024 image"""
# #        previousfiles = self.get_allfiles()
# #        latest = previousfiles[-1]
# #        if len(previousfiles)>0:
# #            latest = previousfiles[-1]
# #        else:
# #            latest = None
# #        #print (previousfiles)
# #        self.take_src(exptime)
# #        #if latest image is in initial files (ie the most recent)
# #        #one hasn't been written yet, keep looking
# #        time.sleep(float(self.timedelay))
# #        while latest in previousfiles:
# #            latest = self.get_latest_image_name()
# #        a = self.scp_latest_image()
# #        print ("Transferring image "+a)
# #        with pf.open(a) as f:
# #            if piezopos is not None:
# #                self.logdata(a+','+str(piezopos))
# #                f[0].header.set('PIEZOPOS', float(piezopos))
# #                f[0].writeto(a, 'ignore', clobber=True)
# #            return (self.combine_quadrants(f))
# #    
# #    def take_src_return_imagedata_header(self, exptime=2, piezopos = None):
# #        """takes an image on pharo and returns a numpy array
# #        of the combined 1024x1024 image"""
# #        previousfiles = self.get_allfiles()
# #        latest = previousfiles[-1]
# #        if len(previousfiles)>0:
# #            latest = previousfiles[-1]
# #        else:
# #            latest = None
# #        #print (previousfiles)
# #        self.take_src(exptime)
# #        #if latest image is in initial files (ie the most recent)
# #        #one hasn't been written yet, keep looking
# #        time.sleep(float(self.timedelay))
# #        while latest in previousfiles:
# #            latest = self.get_latest_image_name()
# #        a = self.scp_latest_image()
# #        print ("Transferring image "+a)
# #        with pf.open(a) as f:
# #            if piezopos is not None:
# #                self.logdata(a+','+str(piezopos))
# #                f[0].header.set('PIEZOPOS', float(piezopos))
# #                f[0].writeto(a, 'ignore', clobber=True)
# #            return f[0].header, self.combine_quadrants(f)
# ##        ## END HERE


# class P3K_COM:

#     def __init__(self, name, configfile=''):
#         self.name = name

#         #check to see if the config files are there
#         if not os.path.isfile(configfile): 
#            print('ERROR accessing ',self.name,
#                  '.  The configuration file [',configfile, 
#                  '] was not found') 
#            return
#         #create configuration object 
#         configObj = ConfigObj(configfile)
#         #check to see if the object is in the config file
#         try:
#             P3Kconfig = configObj[self.name]
#         except:
#             print('ERROR accessing ', self.name, ".", 
#                    self.name, " was not found in the configuration file", configfile)
#             return 

#         #set the port parameters appropriately      
#         self.IPaddress  =       P3Kconfig["Setup"]["IPaddress"]
#         self.comport       = int(  P3Kconfig["Setup"]["comport"])
#         self.statusport       = int(  P3Kconfig["Setup"]["statusport"])
#         self.timeout    = float(P3Kconfig["Setup"]["timeout"])
#         self.maxtries   = int(  P3Kconfig["Setup"]["maxtries"])
# 	self.localoutputdir = P3Kconfig['Setup']['p3k_localoutputdir']

#         #Try connecting separately
#         try:
#             self.comconnection= self.connect(port=self.comport) 
#             print("Opened connection to P3K communication port")
#             print("\tat address ", self.IPaddress, ":",self.comport)
#         except:
#             print("Failed to open connection to P3K communication port")
#             print("\tat address ", self.IPaddress, ":",self.comport)
#         try:
#             self.statusconnection= self.connect(port=self.statusport) 
#             print("Opened connection to P3K status port")
#             print("\tat address ", self.IPaddress, ":",self.statusport)
#         except:
#             print("Failed to open connection to P3K status port")
#             print("\tat address ", self.IPaddress, ":",self.statusport)

#     def connect(self,  
#                 host    =None, 
#                 port    =None, 
#                 timeout =None,
#                 maxtries=None):
#         if host is None:
#             host=self.IPaddress
#         if port is None:
#             port=self.comport
#         if timeout is None:
#             timeout=self.timeout
#         if maxtries is None:
#             maxtries=self.maxtries
#         def formatmsg(inpstring):
#             #formats a message into a format readable
#             #by the controller
#             return (inpstring + '\n')
#         s=socket.socket(socket.AF_INET, socket.SOCK_STREAM)
#         s.settimeout(timeout)
#         s.connect((host, port))
#         return s 
    
#     def safesend2(self, inpstring, connection=None):
#         self.comconnection=self.connect(port=self.comport)
#         if connection is None:
#             connection = self.comconnection
#         def formatmsg(inpstring):
#             #formats a message into a format readable
#             #by the controller
#             return (inpstring + '\n')
#         while True: 
#             connection.send(formatmsg(inpstring))
#             response = connection.recv(1000)
#             print( "response:")
#             print( response)
#             if not 'BSY' in response:
#                 return response
#                 break
#             time.sleep(.2)

#     def sci_offset_radec(self, ra, dec):
#         pass
    
#     def sci_offset_up(self,upamt):
#    #     if self.isReady():
#         if True:
#             self.safesend2(('sci_motion u '+str(upamt)))
#             pass
#         else:
#             self.safesend2('cancel')
#             pass

#     def sci_offset_left(self,leftamt):
#         if True:
#             self.safesend2(('sci_motion l '+str(leftamt)))
#             pass
#         else:
#             self.safesend2('cancel')
#             pass
    
#     def isReady(self):
        
#         self.statusconnection= self.connect(port=self.statusport) 
#         ans = self.safesend2('', connection=self.statusconnection)
#         if 'sci_motion.running=F' in ans:
#             return True
#         else:
#             return False
    
#     def getstatus(self):
#         """Returns the p3K status as a dictionary."""
#         self.statusconnection= self.connect(port=self.statusport) 
#         ans = self.safesend2('', connection=self.statusconnection)
#         anslist = ans.split()
#         outdict = {}
#         for thingy in anslist:
#             try:
#                 key, val = thingy.split('=')[0], thingy.split('=')[1]
#             except:
#                 print( key +" failed")
#                 pass
#             outdict[key]=val
#         return outdict

#     def load_new_flatmap(self, fmap,
#                          fmap_filename = 'hodm_sn_temp',
#                          fmapdir_p3k = '/p3k/tables/hodm_map/'):
#         try:
#             flatmapfunctions.make_hmap(self.localoutputdir+fmap_filename,fmap)	
#         except:
#             print("Warning: converting flatmap to 1d")
#             flatmapfunctions.make_hmap(self.localoutputdir+fmap_filename,
#                     flatmapfunctions.convert_hodm_telem(fmap))

#         stdout, stderr = subprocess.Popen(
#                         ['scp', 
#                          self.localoutputdir+fmap_filename,
#                          'aousr@p3k-telem.palomar.caltech.edu:'+fmapdir_p3k],
#                          stdout=subprocess.PIPE).communicate()
#         for s in [stdout, stderr]:
#             if s is not None:
#                 print(s)
#         status=self.safesend2('hwfp hodm_map='+fmapdir_p3k+fmap_filename)
#         #self.safesend2('hwfp dm=on')
#         #while not self.getstatus()['dm'] == '0':
#         #    self.safesend2('hwfp dm=off')
#         pass

#     #def load_new_flatmap(self, fmap,
#     #                     fmap_filename = 'hodm_sn_temp',
#     #                     fmapdir_p3k = '/p3k/tables/hodm_map/',
#     #                     centoff_filename = 'centoff_sn_temp',
#     #                     centoffdir_p3k = '/p3k/tables/cent_offsets/',
#     #                     centroid_offset = False):
#     #    try:
#     #        flatmapfunctions.make_hmap(self.localoutputdir+fmap_filename,fmap)	
#     #    except:
#     #        print("Warning: converting flatmap to 1d")
#     #        flatmapfunctions.make_hmap(self.localoutputdir+fmap_filename,
#     #                flatmapfunctions.convert_hodm_telem(fmap))

#     #    if not centroid_offset:
#     #        stdout, stderr = subprocess.Popen(
#     #                        ['scp', 
#     #                         self.localoutputdir+fmap_filename,
#     #                         'aousr@p3k-telem.palomar.caltech.edu:'+fmapdir_p3k],
#     #                         stdout=subprocess.PIPE).communicate()
#     #        for s in [stdout, stderr]:
#     #            if s is not None:
#     #                print(s)
#     #        status=self.safesend2('hwfp hodm_map='+fmapdir_p3k+fmap_filename)
#     #        #self.safesend2('hwfp dm=on')
#     #        #while not self.getstatus()['dm'] == '0':
#     #        #    self.safesend2('hwfp dm=off')
#     #        pass

#     #    if centroid_offset:
#     #        converted_flatmap = flatmapfunctions.convert_flatmap_centoff(flatmapfunctions.convert_hodm_telem(fmap))
#     #        centroid_offsetfile = flatmapfunctions.make_centoff_file(converted_flatmap, fname = os.path.join(self.localoutputdir , centoff_filename))
#     #        
#     #         
#     #        stdout, stderr = subprocess.Popen(
#     #                        ['scp', 
#     #                         os.path.join(self.localoutputdir, centoff_filename),
#     #                         'aousr@p3k-telem.palomar.caltech.edu:'+centoffdir_p3k],
#     #                         stdout=subprocess.PIPE).communicate()
#     #        for s in [stdout, stderr]:
#     #            if s is not None:
#     #                print(s)
#     #        status=self.safesend2('hwfp cent_offsets='+centoffdir_p3k+centoff_filename)
#     #        self.safesend2('hwfp dm=off')
#     #        self.safesend2('hwfp dm=on')
#     #        pass

#     def grab_current_flatmap(self):
#         """get the current flatmap, move it to this computer, 
#         return it as an array"""
#         current_flatmap_path = self.getstatus()['hodm_map']
#         stdout, stderr = subprocess.Popen(
#                             ['scp', 
#                              'aousr@p3k-telem.palomar.caltech.edu:'+
#                              current_flatmap_path, 
#                              self.localoutputdir], 
#                              stdout=subprocess.PIPE).communicate()
#         for s in [stdout, stderr]:
#             if s is not None:
#                 print(s)
#         fmapfile = os.path.join(self.localoutputdir,current_flatmap_path.split('/')[-1])
#         current_flatmap = flatmapfunctions.convert_hodm_telem(flatmapfunctions.load_flatmap(fmapfile))
        
#         return current_flatmap

#     def grab_current_centoffs(self):
#         """get the current centroid offsets, move it to this computer, 
#         return it as an array"""
#         current_centoffs_path = self.getstatus()['cent_offset']
#         stdout, stderr = subprocess.Popen(
#                             ['scp', 
#                              'aousr@p3k-telem.palomar.caltech.edu:'+
#                              current_centoffs_path, 
#                              self.localoutputdir], 
#                              stdout=subprocess.PIPE).communicate()
#         for s in [stdout, stderr]:
#             if s is not None:
#                 print(s)
#         fmapfile = os.path.join(self.localoutputdir,current_centoffs_path.split('/')[-1])
#         current_centoffs = flatmapfunctions.load_flatmap(fmapfile)
        
#         return current_centoffs

#     def load_new_centoffs(self, new_centoff, 
#                           centoffdir_p3k = '/p3k/tables/cent_offsets/',
#                           centoff_filename = 'co_sn_temp'):
#         centroid_offsetfile = flatmapfunctions.make_centoff_file(new_centoff, fname = os.path.join(self.localoutputdir , centoff_filename))
#         stdout, stderr = subprocess.Popen(
#                         ['scp', 
#                          os.path.join(self.localoutputdir, centoff_filename),
#                          'aousr@p3k-telem.palomar.caltech.edu:'+centoffdir_p3k],
#                          stdout=subprocess.PIPE).communicate()
#         for s in [stdout, stderr]:
#             if s is not None:
#                 print(s)
#         status=self.safesend2('hwfp cent_offsets='+centoffdir_p3k+centoff_filename)
#         self.safesend2('hwfp dm=off')
#         self.safesend2('hwfp dm=on')
#         pass



# class Piezo:
#     """
#     The class that controls the piezo stepper.
#     Sample usage:
#     >>>import coronagraphobjects as co
#     >>>piezo=co.Piezo('PIEZO', configfile='dvcconfig.ini')
#     >>>piezo.home()
#     >>>piezo.getposition() 
#     '0.002'
#     """

#     def __init__(self, name, configfile=''):
#         self.name = name
#         #check to see if the config files are there
#         if not os.path.isfile(configfile): 
#            print('ERROR accessing ',self.name,
#                  '.  The configuration file [',configfile, 
#                  '] was not found') 
#            return
#         #create configuration object 
#         configObj = ConfigObj(configfile)
#         #check to see if the object is in the config file
#         try:
#             piezoconfig = configObj[self.name]
#         except:
#             print('ERROR accessing ', self.name, ".", 
#                    self.name, " was not found in the configuration file", configfile)
#             return 
#         #set the port parameters appropriately      
#         self.port       = piezoconfig["Setup"]["port"]
#         self.baudrate   = int(piezoconfig["Setup"]["baudrate"])
#         self.bytesize   = int(piezoconfig["Setup"]["bytesize"])
#         self.parity     = piezoconfig["Setup"]["parity"]
#         self.stopbits   = int(piezoconfig["Setup"]["stopbits"])
#         self.timeout    = float(piezoconfig["Setup"]["timeout"])
#         if piezoconfig['Setup']['rtscts']=='True':
#             self.rtscts= True
#         else:
#             self.rtscts = False
#         self.timedelay  = float(piezoconfig["Setup"]["timedelay"]) 
        

#         #set the hardware parameters
#         self.velocity = piezoconfig["Hardware"]["velocity"]
#         self.homeposition = piezoconfig["Hardware"]["homeposition"]
#         self.driftcompensation=int(piezoconfig["Hardware"]["driftcompensation"])
#         #try connecting to the port, create piezocon object
#         try:
#             self.piezocon = serial.Serial(port = self.port,
#                                     baudrate = self.baudrate,
#                                     bytesize = self.bytesize,
#                                     parity = self.parity,
#                                     stopbits = self.stopbits,
#                                     rtscts   = self.rtscts,
#                                     timeout=self.timeout)
#             #XXXXX CHECK THIS LINE XXXXXXX
#             self.piezocon.isOpen()
#             print( "Opened connection to ", self.name,
#                    " on port ",         self.port,"\n",
#                    " with baudrate ",   self.baudrate,"\n",
#                    " with bytesize ",   self.bytesize,"\n",
#                    " with parity   ",     self.parity,"\n",
#                    " with stopbits ",    self.stopbits,"\n")
#         except:
#             print( "ERROR: Unable to open connection to ", self.name, 
#                    " on port ",         self.port,"\n",
#                    " with baudrate ",   self.baudrate,"\n",
#                    " with bytesize ",   self.bytesize,"\n",
#                    " with parity   ",     self.parity,"\n",
#                    " with stopbits ",    self.stopbits,"\n",
#                    "\n Did you perhaps forget to chmod the usbport?\n")
#             return
#         self.safesend('CCL 1 advanced')
#         time.sleep(0.2)
#         self.safesend('CSV 1')
#         print('Setting command set to old version')
#         try:
#             self.safesend('ONL 1');print("Switching to online mode")
#             self.safesend('SVO A1'); print("Switching servo ON")
#             print("Configuring motion presets")
            
#             self.safesend( ("VCO A1")); print("Velocity control mode on.")
#             self.safesend( ("VEL A"+self.velocity)); print("Velocity set to ",self.velocity, "um/s")
#             if self.driftcompensation == 1:
#                 self.safesend( ("DCO A1")); print("Setting drift compensation to ON")
#             else:
#                 self.safesend( ("DCO A0")); print("Setting drift compensation to OFF")
#         except:
#             print("Failed to set motion presets")
        
        
#         #this should specify serial port parameters/etc
#         if self.check_connection():
#             print( "Connection OK")
    
#     def safesend(self, inpstring):
#         self.piezocon.write(inpstring+'\n')
#         time.sleep(self.timedelay)
#         ans=self.piezocon.readline()
#         if ans is not "":
#             if ans[-1]=='\n':
#                 return ans[:-1]
#             else:
#                 return ans
#         else:
#             pass
#    # #Important function to check if everything is ready   
#     def isReady(self):
#         self.piezocon.flushInput()
#         self.piezocon.flushOutput()
#         ans=self.safesend('ERR?')
#         errorcodes = {'0': "No Error",
#                       '1': "Parameter syntax error",
#                       '5': " Cannot set position when servo is off",
#                       '10': "Controller was stopped",
#                       '18': "Invalid macro name",
#                       '19': "Error while recording macro",
#                       '20': "Macro not found",
#                       '23': "Illegal axis identifier",
#                       '26': "Parameter missing",
#                       '301':"Send buffer overflow",
#                       '302':"Voltage out of limits",
#                       '303':"Cannot set voltage when servo on",
#                       '304':"Received command is too long",
#                       '307':"Timeout while receiving command",
#                       '309':"Insufficient space to store macro"}
        
#         if ans in errorcodes.keys():
#             if ans=='0':
#                 return True
#             else:
#                 print(ans)
#                 print(errorcodes[ans])
#                 return False
#         else:
#             self.piezocon.flushOutput()
#             self.piezocon.flushInput()
#             print("Error occured in checking status, flushing buffer. Try again in 1 second")
#             time.sleep(1)
#             return False
    
         
#     ####STANDARD COMMANDS FOR LYOT WHEEL####
     
#     def check_connection(self):
#         print( "checking serial connection")
#         return self.piezocon.isOpen()

#     def getposition(self):
#         #serial commands to return the current position
#         if self.isReady():
#             ans=self.safesend("POS? A")
#             time.sleep(self.timedelay)
#             return (''.join(c for c in ans if (c.isdigit() or c=='-' or c=='.')))
#             #return filter(str.isdigit, ans)
#         else:
#             return 
    
#     def ontarget(self):
#         if self.isReady():
#             ans = self.safesend('ONT?')
#             time.sleep(self.timedelay)
#             if ans == '1':
#                 return True
#             else:
#                 return False
#         else:
#             return False
             
#     ####MOVE FUNCTIONS####### 
#     def home(self):
#         if self.isReady():
#             ans=self.safesend(('MOV A'+self.homeposition))
#             print("Homing Stage")
    
#     def moveabsolute(self, target):
#         if not (isinstance(target, float) or isinstance(target, int)):
#             print("Please enter a number")
#             return
#         if not (target > 0):
#             print("Please enter a positive number")
#             return
#         else:
#             if self.isReady():
#                 ans = self.safesend(('MOV A'+str(target)))
#                 print("Moving to position ", target)
#             else:
#                 print("The piezo stop had some problem")
#                 print("Please try again")
#                 return
                 
#     def moverelative(self, target):
#         if not (isinstance(target, float) or isinstance(target, int)):
#             print("Please enter a number")
#             return
#         else:
#             if self.isReady():
#                 ans = self.safesend(('MVR A'+str(target)))
#                 print("Moving the piezo by", target)
#             else:
#                 print("The piezo stop had some problem")
#                 print("Please try again")
#                 return



# class NIRC2_COM:
    
#     def __init__(self, name, configfile = ''):
#         configObj = ConfigObj(configfile)

#         self.name=name
#         try:
#             CAMERAconfig = configObj[self.name]
#         except:
#             print('ERROR accessing ', self.name, ".", 
#                    self.name, " was not found in the configuration file", configfile)
#             return 
        
#         print ("WARNING : DIRECTORY SET TO DEFAULT")
#         self.cameraserver   = CAMERAconfig['Setup']['cameraserver']
#         self.camerapassword = CAMERAconfig['Setup']['camerapassword']
#         self.cameraimagedir = CAMERAconfig['Setup']['cameraimagedir']
#         self.localoutputdir = CAMERAconfig['Setup']['localoutputdir']
#         self.timedelay = CAMERAconfig['Setup']['timedelay']
#         self.logfile = os.path.join(self.localoutputdir, 
#                                CAMERAconfig['Setup']['logfile'])

#         if not os.path.exists(self.localoutputdir):
#             print( "Creating local output directory: "+self.localoutputdir)
#             os.makedirs(self.localoutputdir)
#         if not os.path.isfile(self.logfile):
#             print( "Creating logfile at "+self.logfile)

#         return

#     def logdata(self, commentstring):
#         with open(self.logfile,'a+') as lf:
#             lf.write(commentstring+'\n')

#     def combine_quadrants(self, image):
#         #"""combines the four camera quadrants into a unified image"""
#         data = image[0].data
#         #quad1=(image[0].data)[0,:,:]
#         #quad2=(image[0].data)[1,:,:]
#         #quad3=(image[0].data)[2,:,:]
#         #quad4=(image[0].data)[3,:,:]
#         #
#         #toprow=np.hstack((quad2, quad1))
#         #bottomrow=np.hstack((quad3, quad4))
#         #returnimage=np.vstack((toprow, bottomrow))
#         ##nb--in the reduction pipeline the following is commnented in 
#         ##in this program WYSIWYG with CAMERA;s monitor
#         ##returnimage = returnimage[:,::-1]
#         #return returnimage
#         return data
    
#     def get_latest_image_name(self):
#         """gets the name of the latest image in the CAMERA output directory"""
#         #stdout, stderr = subprocess.Popen(
#         #                    ['ssh', 
#         #                    self.cameraserver, 
#         #                    'ls '+self.cameraimagedir], 
#         #                     stdout=subprocess.PIPE).communicate()
#         child = pexpect.spawn('ssh '+
#                               self.cameraserver+
#                               ' ls '+
#                               self.cameraimagedir)
#         child.expect('assword:')
#         child.sendline(self.camerapassword)
#         stdout = child.readlines()
        
#         fitsfiles=[x.strip() for x in stdout if 'fits' in x]
#         #fitsfiles=[x for x in listoffiles if 'fits' in x]
#         numlist = []
#         for fitsfile in fitsfiles:
#             numlist.append( int(''.join(a for a in fitsfile if a.isdigit())))
#         maxind = numlist.index(max(numlist))
#         return os.path.join(self.cameraimagedir, fitsfiles[maxind])
    
#     def get_allfiles(self):
#         """get a list of all the files in teh CAMERA output directory"""
#         child = pexpect.spawn('ssh '+
#                               self.cameraserver+
#                               ' ls '+
#                               self.cameraimagedir)
#         child.expect('assword:')
#         child.sendline(self.camerapassword)
#         stdout = child.readlines()
        
#         fitsfiles=[x.strip() for x in stdout if 'fits' in x]
#         return [os.path.join(self.cameraimagedir, x) for x in fitsfiles]

#     def scp_latest_image(self):
#         """gets the latest image in the camera directory and 
#         saves it to the local dir. returns the path to the image
#         on the LOCAL output directory"""
#         filename = self.get_latest_image_name()
#         stringtosend = ('scp '+
#                                self.cameraserver+':'+
#                               filename+
#                               ' '+self.localoutputdir)
#         child = pexpect.spawn(stringtosend)
#         child.expect('assword:')
#         child.sendline(self.camerapassword)
#         print( child.readlines())
#         return  os.path.join(self.localoutputdir,filename.split('/')[-1])
        
#     def scp_specific_image(self, imagename):
#         """grabs a specific image from the local dir"""
#         filename = imagename
#         child = pexpect.spawn('scp '+ 
#                               self.cameraserver+':'+filename+
#                               ' '+self.localoutputdir)
#         child.expect('assword:')
#         child.sendline(self.camerapassword)
#         return  os.path.join(self.localoutputdir,filename.split('/')[-1])
    
#     def safesend(self, string):
#         child = pexpect.spawn('ssh '+
#                               self.cameraserver+
#                               ' '+string)
#         child.expect('assword:')
#         child.sendline(self.camerapassword)
#         stdout = child.readlines()
#         return stdout

#     def take_src(self, exptime = None):
#         """takes an image on camera. does not return anything""" 
#         #self.camera_p3k.safesend2('camera take_srcimage 2')        
#         #stdout, stderr = subprocess.Popen(
#         #                    ['ssh', 
#         #                    self.cameraserver, 
#         #                    'goi'], 
#         #                    stdout=subprocess.PIPE).communicate()
#         #for s in [stdout, stderr]:
#         #    if s is not None:
#         #        print(s)
#         print( "WARNING: EXPTIME DEFAULT")
#         self.safesend('goi')
#         return

#     def take_src_return_imagename(self, exptime=2):
#         """takes an image on camera and returns the path
#         to the image on the local computer"""
#         previousfiles = self.get_allfiles()
#         if len(previousfiles)>0:
#             latest = previousfiles[-1]
#         else:
#             latest = None
#         self.take_src(exptime)
#         #if latest image is in initial files (ie the most recent)
#         #one hasn't been written yet, keep looking
#         time.sleep(float(self.timedelay))
#         while latest in previousfiles:
#             print('hi')
#             latest = self.get_latest_image_name()
#         return self.scp_latest_image() 
        
#     def take_src_return_imagedata(self, exptime=2, piezopos = None):
#         """takes an image on camera and returns a numpy array
#         of the combined 1024x1024 image"""
#         previousfiles = self.get_allfiles()
#         latest = previousfiles[-1]
#         if len(previousfiles)>0:
#             latest = previousfiles[-1]
#         else:
#             latest = None
#         #print (previousfiles)
#         self.take_src(exptime)
#         #if latest image is in initial files (ie the most recent)
#         #one hasn't been written yet, keep looking
#         time.sleep(float(self.timedelay))
#         while latest in previousfiles:
#             latest = self.get_latest_image_name()
#         a = self.scp_latest_image()
#         print ("Transferring image "+a)
#         with pf.open(a,  ignore_missing_end = True, silent = True) as f:
#             if piezopos is not None:
#                 self.logdata(a+','+str(piezopos))
#                 f[0].header.set('PIEZOPOS', float(piezopos))
#                 f[0].writeto(a, 'ignore', clobber=True)
#             return (self.combine_quadrants(f))
    
#     def take_src_return_imagedata_header(self, exptime=2, piezopos = None):
#         """takes an image on camera and returns a numpy array
#         of the combined 1024x1024 image"""
#         previousfiles = self.get_allfiles()
#         latest = previousfiles[-1]
#         if len(previousfiles)>0:
#             latest = previousfiles[-1]
#         else:
#             latest = None
#         #print (previousfiles)
#         self.take_src(exptime)
#         #if latest image is in initial files (ie the most recent)
#         #one hasn't been written yet, keep looking
#         time.sleep(float(self.timedelay))
#         while latest in previousfiles:
#             latest = self.get_latest_image_name()
#         a = self.scp_latest_image()
#         print ("Transferring image "+a)
#         with pf.open(a) as f:
#             if piezopos is not None:
#                 self.logdata(a+','+str(piezopos))
#                 f[0].header.set('PIEZOPOS', float(piezopos))
#                 f[0].writeto(a, 'ignore', clobber=True)
#             return f[0].header, self.combine_quadrants(f)
# #        ## END HERE

