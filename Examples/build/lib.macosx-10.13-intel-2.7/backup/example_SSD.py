import sys, os
sys.path.append('D:/dodkins/MEDIS/MEDIS')
import glob
import numpy as np
# np.set_printoptions(threshold=np.inf)
import cPickle as pickle
import multiprocessing
import time
from functools import partial
import matplotlib.pylab as plt
from medis.params import ap,cp,tp,mp,sp
# import medis.Detector.analysis as ana
import medis.Detector.readout as read
import medis.Detector.pipeline as pipe
import medis.Detector.temporal as temp
from medis.Detector.distribution import gaussian, poisson, MR, gaussian2
from scipy.optimize import curve_fit
from medis.Utils.plot_tools import view_datacube, quicklook_im, loop_frames
import medis.Utils.misc as misc
import medis.Detector.get_photon_data as gpd
from medis.Utils.misc import debprint

# os.system("taskset -p 0xfffff %d" % os.getpid())
ap.companion=True
ap.contrast = 0.1
ap.numframes = 2000
tp.detector = 'ideal'#''MKIDs
sp.save_obs = False
mp.date = '180325/'
mp.datadir= os.path.join(mp.rootdir,mp.data, mp.date)
mp.obsfile = 'r0varyObsfile.h5'
sp.show_cube = False
sp.return_cube = False
cp.vary_r0 = True
tp.occulter_type = None#
tp.satelite_speck = True
tp.speck_peakIs = [0.02]
sp.show_wframe = False#'continuous'
if sp.show_wframe == 'continuous':
    sp.fig = plt.figure()

ints = np.empty(0)
times= np.empty(0)
max_photons=5e7 #5e7 appears to be the max Pool can handle irrespective of machine capability?
# ap.numframes=200
num_chunks = int(ap.star_photons*ap.numframes/max_photons)
if num_chunks < 1:
    num_chunks = 1
print num_chunks

# ap.numframes = int(max_photons/ap.star_photons)

# num_chunks=1
bin_time=2e-3#10e-3
num_ints = int(cp.frame_time*ap.numframes/bin_time)
# ylocs = range(35, 45)
# xlocs = range(85, 95)
xlocs = range(0,128)#range(0,128)#65
ylocs = range(0,128)#range(0,128)#85
LCmapFile = os.path.join(mp.rootdir,mp.proc_dir, mp.date, 'LCvaryR0.pkl')
IratioFile = os.path.join(mp.rootdir, mp.proc_dir, mp.date,'IrvaryR0.pkl')#Iratio4040_6chunk.pkl'
# tp.LCmap = np.zeros((len(xlocs), len(ylocs), num_ints))


def make_LC_map():
    LCmap = np.zeros((len(xlocs),len(ylocs),num_chunks*num_ints))
    for i in range(num_chunks):

        start = i*max_photons
        # print start, start+max_photons
        packets = pipe.read_obs(max_photons=max_photons,start=start)

        # newpackets = pipe.isolate_interval(packets,[0,0.1])
        # print np.shape(newpackets)
        # cube = pipe.arange_into_cube(newpackets)
        # image = pipe.make_intensity_map(cube)
        # image = pipe.make_intensity_map_packets(packets)
        # # loop_frames
        # quicklook_im(image)
        # print image[58,67]

        # xloc, yloc = 58., 67.
        # xloc, yloc = 60., 60.
        # xloc, yloc = 60., 60.
        start = packets[0, 2]
        end = packets[-1, 2]
        # print start, end

        for ix, xloc in enumerate(xlocs):
            for iy, yloc in enumerate(ylocs):
                print np.shape(packets)
                LC, packets = pipe.get_lightcurve(packets, xloc, yloc, start, end + cp.frame_time, bin_time=bin_time, speed_up=True)
                # print LC['intensity']
                LCmap[ix,iy,i*num_ints:(i+1)*num_ints] = LC['intensity']
                if (ix*len(ylocs) + iy)%10==0: misc.progressBar(value = (ix*len(ylocs) + iy), endvalue=len(xlocs)*len(ylocs))
    with open(LCmapFile, 'wb') as handle:
        pickle.dump(LCmap, handle, protocol=pickle.HIGHEST_PROTOCOL)


def save_LCmap(LCmap):
    with open(LCmapFile, 'wb') as handle:
        pickle.dump(LCmap, handle, protocol=pickle.HIGHEST_PROTOCOL)

def plot_LC_map(xlocs, ylocs, LCmapFile, inspect=False):
    
    with open(LCmapFile, 'rb') as handle:
        LCmap =pickle.load(handle)

    # print np.shape(LCmap)
    LCmap = LCmap[:,:,:]
    # plt.plot(LCmap[60,40])
    # plt.figure()
    # LCmap = temp.downsample(LCmap, factor=10)
    # plt.plot(LCmap[60,40])
    # plt.show()

    print np.shape(LCmap)

    # xinspect = range(35,45)
    # yinspect = range(85,95)

    total_map = np.sum(LCmap,axis=2)
    median_map = np.median(LCmap,axis=2)
    interval_map = np.sum(LCmap[:,:,:100],axis=2)

    # if inspect:
    #     plt.imshow(median_map[yinspect[0]:yinspect[-1],xinspect[0]:xinspect[-1]])
    #     plt.show()

    quicklook_im(total_map, logAmp=True, show=False)
    quicklook_im(median_map, logAmp=True, show=False)
    quicklook_im(interval_map, logAmp=True, show=False)

    if os.path.isfile(IratioFile):
        with open(IratioFile, 'rb') as handle:
            Ic,Is,Iratio,mIratio =pickle.load(handle)
        print np.shape(Iratio)
    else:    
        Iratio= np.zeros((len(xlocs),len(ylocs)))
        Ic= np.zeros((len(xlocs),len(ylocs)))
        Is= np.zeros((len(xlocs),len(ylocs)))
        mIratio=np.zeros((len(xlocs),len(ylocs)))
        for ix, xloc in enumerate(xlocs):
            for iy, yloc in enumerate(ylocs):
                if (ix*len(ylocs) + iy)%100==0: misc.progressBar(value = (ix*len(ylocs) + iy), endvalue=len(xlocs)*len(ylocs))
                ints = LCmap[ix,iy]

                ID = pipe.get_intensity_dist(ints)
                bincent = (ID['binsS'] + np.roll(ID['binsS'],1))/2.
                bincent = np.array(bincent)[1:]

                # popt, _ = curve_fit(gaussian, ID['binsS'][:-1], ID['histS'])
                # plt.plot(ID['binsS'][:-1], gaussian(ID['binsS'][:-1], *popt), 'r--')
                # popt, _ = curve_fit(poisson, ID['binsS'][:-1], ID['histS'])
                # plt.plot(ID['binsS'][:-1], poisson(ID['binsS'][:-1], *popt), 'g--')
                # bincent = np.linspace(0,100000,len(bincent))
                # gauss = gaussian2(bincent, 1000,np.mean(ints)) + 0.0001 * np.random.normal(size=bincent.size)
                # popt, _ = curve_fit(gaussian2, bincent, gauss, p0=[100,100])
                # print popt

                # plt.plot(bincent, gauss)
                # plt.plot(bincent, gaussian2(bincent, *popt), 'g--')
                # print sum(gauss)
                # print np.mean(ints)

                guessIc = np.mean(ints)*0.7
                guessIs = np.mean(ints)*0.3

                # popt, _ = curve_fit(MR, bincent, gauss, p0=[guessIc,guessIs])
                # print popt
                # plt.plot(bincent, MR(bincent, *popt), 'g--')
                # print sum(MR(bincent, *popt))

                # popt, _ = curve_fit(func, bincent, ID['histS'])
                # plt.plot(bincent, func(bincent, *popt), 'r--')
                try:
                    popt, _ = curve_fit(MR, bincent, ID['histS'], p0=[guessIc,guessIs])
                    Ic[ix,iy] = popt[0]
                    Is[ix,iy] = popt[1]  
                    Iratio[ix,iy] = popt[0]/popt[1]   
                    m = (np.sum(ints) - (popt[0]+popt[0]))/(np.sqrt(popt[1]**2 + 2*popt[0]+popt[1])*len(ints))
                    mIratio[ix,iy] = m**-1*(Iratio[ix,iy])
                except RuntimeError:
                    pass
                # print np.shape(ints)
                # EI = np.sum(ints)
                # # print EI
                # EI2 = EI**2
                # # print EI2
                # var = np.var(ints)
                # # print var
                # Is[ix,iy] = EI-np.sqrt(EI2-var)
                # # print Is[ix,iy]
                # Ic[ix,iy] = EI-Is[ix,iy]
                # # print Ic[ix,iy]
                # Iratio[ix,iy] = Ic[ix,iy]/Is[ix,iy]
                # exit()
                if inspect==True:# and xloc in yinspect and yloc in xinspect:
                    plt.figure()
                    plt.plot(ints)
                    print xloc, yloc
                    plt.figure()
                    plt.step(bincent, ID['histS'])
                    plt.plot(bincent, MR(bincent, *popt), 'b--')
                    print popt, popt[0]/popt[1]
                    plt.show()

        with open(IratioFile, 'wb') as handle:
            pickle.dump([Ic,Is,Iratio,mIratio], handle, protocol=pickle.HIGHEST_PROTOCOL)

    quicklook_im(Ic,  logAmp=True, show=False)#, vmax=25)#
    quicklook_im(Is, logAmp=True, show=False)#,vmax=5,)#
    quicklook_im(Iratio, logAmp=True, show=False)#,vmax=25,)#
    quicklook_im(mIratio, logAmp=True, show=False)#, vmax=5,)#
    quicklook_im(mIratio*Iratio, logAmp=True, show=False)#, vmax=500,)#
    plt.show()
    return total_map,median_map,interval_map,Iratio,mIratio


def mp_worker(idx, packets):
    ints = get_LCmap_multi(idx, packets)
    return ints

def run():
    packets = pipe.read_obs(max_photons=max_photons)
    print packets[:50], packets.shape
    # tp.packets = packets

    print sp.num_processes, 'NUM_PROCESSES'
    p = multiprocessing.Pool(sp.num_processes)
    LCmap = np.zeros((len(xlocs), len(ylocs), num_ints))
    print num_ints, num_chunks
    for i in range(num_chunks):
        packets_chunk = packets[i*max_photons:(i+1)*max_photons]
        print debprint((i, packets_chunk.shape))
        prod_x = partial(mp_worker, packets=packets_chunk)  # prod_x has only one argument x (y is fixed to 10)
        # idxs = range(tp.grid_size**2)
        idxs = range(len(xlocs)*len(ylocs))
        print debprint(idxs)
        LClist = p.map(prod_x, idxs)
        # LClist = mp_worker(idxs[0])
        # LClist = p.map(mp_worker, idxs)

        # LClist = []
        # for idx in idxs:
        #     ints = p.apply_async(mp_worker, (idx, packets)).get()
        #     print ints
        #     LClist.append(ints)
            # print LClist
        binned_chunk = num_ints/num_chunks
        print debprint((len(LClist[0]), binned_chunk))
        for idx in idxs:
            ix = idx / len(xlocs)
            iy = idx % len(xlocs)
            LCmap[ix,iy,i*binned_chunk:(i+1)*binned_chunk] = LClist[idx]

    plt.imshow(LCmap[:,:,0])
    plt.show()
    return LCmap

def get_LCmap_multi(idx, packets):

    # ix = idx/tp.grid_size
    # iy = idx%tp.grid_size
    ix = idx/len(xlocs)
    iy = idx%len(xlocs)
    # print ix, iy
    xloc = xlocs[ix]
    yloc = ylocs[iy]
    # print xloc, yloc
    # print tp.packets
    # print np.shape(packets), packets[:5]
    start = packets[0,2]
    end = packets[-1,2]
    # print start, end

    time0 = time.time()
    LC = pipe.get_lightcurve(packets, xloc, yloc, start, end+cp.frame_time, bin_time=bin_time)
    # print LC['intensity']
    time1 = time.time()
    print 'time', time1-time0
    # tp.LCmap[ix, iy] = LC['intensity']
    # if (ix * len(ylocs) + iy) % 10 == 0: misc.progressBar(value=(ix * len(ylocs) + iy),
    #                                                       endvalue=len(xlocs) * len(ylocs))
    return LC['intensity']

if __name__ == '__main__':
    sp.num_processes = 25
    if not os.path.isfile(mp.datadir + mp.obsfile):
        print '********** Making obsfile ***********'
        begin = time.time()
        gpd.run()
        end = time.time()
        print 'Time elapsed: ', end-begin
        print '*************************************'


    if not os.path.isfile(LCmapFile):
        sp.num_processes = 5
        print '********** Making LightCurve file ***********'
        begin = time.time()
        # if __name__ == '__main__':
        # LCmap = run()
        LCmap = make_LC_map()
        end = time.time()
        save_LCmap(LCmap)
        print 'Time elapsed: ', end - begin
        print '*********************************************'

    images = plot_LC_map(xlocs, ylocs, LCmapFile, inspect=False)
# #     # print end-begin
#
# # make_LC_map(num_chunks, max_photons, xlocs, ylocs, bin_time, LCmapFile)
#
#     labels = ['total_map','median','interval_map','Iratio','mIratio']
#     import medis.Detector.analysis as ana
#     ana.make_cont_plot(images,labels)

# max_photons=1.5e8
# packets = pipe.read_obs(max_photons=max_photons,start=0)
# # image = pipe.make_intensity_map_packets(packets)
# # quicklook_im(image)
# for xloc in range(30,96,4):
#     for yloc in [61,62]:#range(0,120,20):#range(65,70,1):
#         # xloc, yloc = 58, 27
#         print xloc, yloc

#         LC = pipe.get_lightcurve(packets,xloc,yloc)
#         print sum(LC['intensity'])
#         plt.plot(LC['time'][:-1], LC['intensity'])

#         ID = pipe.get_intensity_dist(LC['intensity'])
#         plt.figure()
#         plt.plot(ID['binsS'][:-1], ID['histS'])
#         plt.show()


