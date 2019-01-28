#
import sys
import proper
import numpy as np
import pickle as pickle
# # import vip
# # import pyfits as pyfits
# import matplotlib.pylab as plt
# import copy
# import math
# # import deformable_mirror as DM
# from scipy.optimize import curve_fit
# # from scipy import interpolate
from medis.params import tp, cp, mp, ap, iop, fp
sys.path.append(tp.FPWFSdir)
import medis.speckle_nulling.speckle_nulling.speckle_killer_v3 as skv3
import dm_functions as DM
from medis.Utils.plot_tools import loop_frames, quicklook_wf, quicklook_im


controlregion = np.zeros((tp.grid_size, tp.grid_size))
controlregion[fp.controlregion[0]:fp.controlregion[1], fp.controlregion[2]:fp.controlregion[3]] = 1

def speckle_killer(wf, phase_map):
    # with open(iop.phase_ideal, 'rb') as handle:
    #     phase_ideal = pickle.load(handle)

    # quicklook_im(phase_map, logAmp=False)

    ijofinterest = skv3.identify_bright_points(proper.prop_get_amplitude(wf), controlregion)
    xyofinterest = [p[::-1] for p in ijofinterest]
    print(xyofinterest, len(xyofinterest))
    if len(xyofinterest) == 0:
        y = int(np.random.uniform(fp.controlregion[0],fp.controlregion[1]))
        x = int(np.random.uniform(fp.controlregion[2], fp.controlregion[3]))
        xyofinterest = [(y,x)]
    if len(xyofinterest) < fp.max_specks:
        fp.max_specks = len(xyofinterest)
    print(fp.max_specks)
    fps = skv3.filterpoints(xyofinterest,max=fp.max_specks,rad=fp.exclusionzone)
    print(fps)


    null_map = np.zeros((tp.ao_act,tp.ao_act))
    for speck in fps:
        print(speck)
        kvecx, kvecy = DM.convert_pixels_kvecs(speck[0],speck[1],tp.grid_size/2,tp.grid_size/2,angle=0,lambdaoverd=fp.lod )
        dm_phase = phase_map[speck[1],speck[0]]
        s_amp = proper.prop_get_amplitude(wf)[speck[1],speck[0]]*5.3

        null_map += -DM.make_speckle_kxy(kvecx, kvecy, s_amp, dm_phase)#+s_ideal#- 1.9377
    null_map /= len(fps)

    area_sum = np.sum(proper.prop_get_amplitude(wf)*controlregion)
    print(area_sum)
    with open(iop.measured_var, 'ab') as handle:
        pickle.dump(area_sum, handle, protocol=pickle.HIGHEST_PROTOCOL)

    return null_map

def active_null(wf, iter, w):

    ip = iter % 4
    with open(iop.NCPA_meas, 'rb') as handle:
        Imaps, null_map, _ = pickle.load(handle)
    Imaps[ip] = piston_refbeam(wf, iter, w)

    # loop_frames(Imaps)
    # focal_map = None
    if (iter+1)%4 == 0:# and not np.any(Imaps[:,1,1] == 0): #iter >= 3
        focal_map = measure_phase(Imaps)
        # quicklook_wf(wf, show=True)
        # quicklook_im(proper.prop_get_phase(wf), logAmp=False, show=False, colormap="jet", vmin=-3.14, vmax=3.14)
        # quicklook_im(phase_map, logAmp=False, show=False, colormap="jet", vmin=-3.14, vmax=3.14)
        # quicklook_im(proper.prop_get_phase(wf)-phase_map, logAmp=False, show=False, colormap="jet", vmin=-3.14, vmax=3.14)

    # if iter >= tp.active_converge_steps*4:
    # if focal_map != None:
        print('running speckle killer')
        null_map += speckle_killer(wf, focal_map)

    with open(iop.NCPA_meas, 'wb') as handle:
        pickle.dump((Imaps, null_map, iter+1), handle, protocol=pickle.HIGHEST_PROTOCOL)

def piston_refbeam(wf, iter, w):
    beam_ratio = 0.7 * tp.band[0] / w * 1e-9
    wf_ref = proper.prop_begin(tp.diam, w, tp.grid_size, beam_ratio)
    proper.prop_define_entrance(wf_ref)
    phase_mod = iter%4 * w/4#np.pi/2
    obj_map = np.ones((tp.grid_size,tp.grid_size))*phase_mod
    proper.prop_add_phase(wf_ref, obj_map)
    wf_ref.wfarr = wf.wfarr + wf_ref.wfarr
    Imap =proper.prop_shift_center(np.abs(wf_ref.wfarr) ** 2)
    return Imap

def measure_phase(Imaps):
    phase_map = -1*np.arctan2(Imaps[3]-Imaps[1],Imaps[0]-Imaps[2]) #*180/np.pi

    # loop_frames(Imaps+1e-9, logAmp=True)
    # phase_map = proper.prop_shift_center(phase_map)
    # phase_map = np.roll(np.roll(np.rot90(phase_map, 2), 1, 0), 1, 1)  # to convert back to how it is by the DM
    # quicklook_im(phase_map, logAmp=False)
    return phase_map


# def calc_k(pixel_coords):
#     fwhm = 3.37
#     # dist = np.sqrt(pixel_coords[0]**2 + pixel_coords[1]**2)
#     kx = pixel_coords[0]/fwhm
#     ky = pixel_coords[1]/fwhm
#     return kx, ky
#
# def calc_coords(kx, ky):
#     fwhm = 3.37
#     px = kx*fwhm
#     py = ky*fwhm
#     print px, py
#     return [px,py]
#
# def do_amp_calib(wfo, f_lens, calib_file):
#     amp = 2e-08 # 6e-8 gives speck same height as PSF
#     # anum=10
#     knum=10
#     kmin = 10
#     kmax = 33
#
#     karray = np.linspace(kmin,kmax,knum)
#     # calib_map = np.zeros((anum,knum))
#     # for ia, amp in enumerate(np.linspace(0,6e-8,anum)):#np.arange(0,1e-7,1e-8):
#     Is = np.zeros((knum))
#     for ik,k in enumerate(karray):
#         wf_temp = copy.copy(wfo)
#         obj_map = DM.create_waffle([0,0], [0,k], [k,0], [amp,amp])#create_waffle(0,k, 0,amp)
#         propagate_DM(wf_temp, f_lens, obj_map)
#         # ik = [0,1,0,-1]
#         # I = 0
#         # for ix in ik:
#         #     # print ix, ix*k, np.roll(ik,1)[ix], np.roll(ik,1)[ix]*k
#         #     spec_loc = FPWFS.calc_coords(ix*k, np.roll(ik,1)[ix]*k)
#         #     I += FPWFS.get_speck_intensity(wf_temp, spec_loc)
#         # I = I/len(ik)
#         spec_loc = calc_coords(k,0)
#         I = get_speck_intensity(wf_temp, spec_loc)
#         print 'amp', amp, ik,'k', k, 'intensity', I
#         Is[ik] =I
#         # calib_map[ia,ik]=I
#
#             # FPWFS.quicklook_wf(wf_temp)
#     def func(k, a, b, c):
#         I = amp**2/(a*k**2 + b*k + c)
#         return I
#
#     popt, pcov = curve_fit(func, karray, Is)
#     plt.plot(karray, func(karray, *popt), 'g--')
#
#     plt.plot(karray, Is)
#     print popt
#     plt.show()
#     #
#
# def do_amp_calib_numerical(wfo, f_lens, calib_file):
#     amp = 2e-08 # 6e-8 gives speck same height as PSF
#     anum=5
#     knum=5
#     kmin = 10
#     kmax = 33
#
#     karray = np.linspace(kmin,kmax,knum)
#     calib_map = np.zeros((anum,knum))
#     for ia, amp in enumerate(np.linspace(0,6e-8,anum)):#np.arange(0,1e-7,1e-8):
#         for ik,k in enumerate(np.linspace(10,33,knum)):
#             wf_temp = copy.copy(wfo)
#             obj_map = DM.create_waffle([0,0], [0,k], [k,0], [amp,amp])#create_waffle(0,k, 0,amp)
#             propagate_DM(wf_temp, f_lens, obj_map)
#             # ik = [0,1,0,-1]
#             # I = 0
#             # for ix in ik:
#             #     # print ix, ix*k, np.roll(ik,1)[ix], np.roll(ik,1)[ix]*k
#             #     spec_loc = FPWFS.calc_coords(ix*k, np.roll(ik,1)[ix]*k)
#             #     I += FPWFS.get_speck_intensity(wf_temp, spec_loc)
#             # I = I/len(ik)
#             spec_loc = calc_coords(k,0)
#             I = get_speck_intensity(wf_temp, spec_loc)
#             print ia, 'amp', amp, ik,'k', k, 'intensity', I
#             # Is[ik] =I
#             calib_map[ia,ik]=I
#
#             # FPWFS.quicklook_wf(wf_temp)
#
#     plt.imshow(calib_map)
#     plt.figure()
#     plt.plot(calib_map[1])
#     plt.figure()
#     plt.plot(calib_map[:,1])
#     plt.show()
#     np.savetxt(calib_file, calib_map)
#
# def do_amp_calib_1d(wfo, f_lens, calib_file):
#     amp = 2e-08 # 6e-8 gives speck same height as PSF
#     anum=5
#     k = 20
#     # knum=5
#     # kmin = 10
#     # kmax = 33
#     aarray=np.linspace(0,5e-8,anum)
#     Is = np.zeros((anum))
#     for ia, amp in enumerate(aarray):#np.arange(0,1e-7,1e-8):
#         # for ik,k in enumerate(np.linspace(10,33,knum)):
#         wf_temp = copy.copy(wfo)
#         obj_map = DM.create_waffle([0,0], [0,k], [k,0], [amp,amp])#create_waffle(0,k, 0,amp)
#         propagate_DM(wf_temp, f_lens, obj_map)
#         # ik = [0,1,0,-1]
#         # I = 0
#         # for ix in ik:
#         #     # print ix, ix*k, np.roll(ik,1)[ix], np.roll(ik,1)[ix]*k
#         #     spec_loc = FPWFS.calc_coords(ix*k, np.roll(ik,1)[ix]*k)
#         #     I += FPWFS.get_speck_intensity(wf_temp, spec_loc)
#         # I = I/len(ik)
#         spec_loc = calc_coords(k,0)
#         I = get_speck_intensity(wf_temp, spec_loc)
#         print ia, 'amp', amp, 'intensity', I
#         # quicklook_wf(wf_temp)
#         Is[ia] =I
#         # calib_map[ia,ik]=I
#
#
#
#     def func(a, A):
#         I = A* (a**0.5)
#         return I
#     print Is, aarray
#     popt, pcov = curve_fit(func, aarray, Is)
#     print popt
#     plt.plot(aarray, func(aarray, *popt), 'g--')
#
#     plt.plot(aarray, Is)
#     plt.show()
#     np.savetxt(calib_file, popt)
#
#
# def get_I_map(calib_file):
#     I_map = np.loadtxt(calib_file)
#     # plt.figure()
#     # plt.imshow(I_map)
#     # plt.show()
#     return I_map
#
# def calc_amp(I_map, I, k):
#     coeffs = I_map
#     print coeffs, I, k
#     amp = (I/coeffs)**2
#     print amp
#     # anum=5
#     # knum=5
#     # aarray = np.linspace(0,6e-8,anum)
#     # karray = np.linspace(10,33,knum)
#     # print k
#     # # a_map = #could flip I_map to make a_map
#     # # plt.plot(karray, I_map)
#     # # plt.show()
#     # k_func = interpolate.interp1d(range(len(karray)), karray)
#     # # print k_func(k)
#     # plt.imshow(I_map)
#     # plt.figure()
#     # plt.plot(I_map[3])
#     # plt.show()
#     return amp
#
# def propagate_DM(wfo, f_lens, obj_map):
#     proper.prop_propagate(wfo, f_lens, "telescope pupil imaging lens")
#     # quicklook_wf(wfo)
#     proper.prop_lens(wfo, f_lens, "telescope pupil imaging lens")
#     proper.prop_propagate(wfo, f_lens, "DM")
#
#     # quicklook_wf(wfo)
#     # after_dm = proper.prop_get_amplitude(wfo)
#     # phase_afterdm = proper.prop_get_phase(wfo)
#     obj_map = obj_map/1e6
#     # print np.shape(obj_map)
#     # pyfits.writeto('dm.fits', obj_map)
#
#     proper.prop_dm(wfo, obj_map, tp.null_ao_act/2, tp.null_ao_act/2, N_ACT_ACROSS_PUPIL=tp.null_ao_act, FIT = True)
#     # quicklook_im(obj_map)
#     # quicklook_wf(wfo)
#     # after_dm = proper.prop_get_amplitude(wfo)
#     # phase_afterdm = proper.prop_get_phase(wfo)
#     proper.prop_lens(wfo, f_lens)
#     # quicklook_wf(wfo)
#     proper.prop_propagate(wfo, f_lens)
#     wfo.wfarr = np.roll(np.roll(np.rot90(wfo.wfarr, 2), 1, 0), 1, 1)
#
# def aper_phot(array,index,radius, show_region):
#     a,b = index
#     nx,ny = array.shape
#     y,x = np.ogrid[-a:nx-a,-b:ny-b]
#     mask = x*x + y*y <= radius*radius
#     if show_region:
#         plt.figure()
#         plt.imshow(array*mask, origin='lower')
#         plt.show()
#     return sum(array[mask])
#
# def get_speck_intensity(wfo, spec_loc, show_region):
#     after_dm = proper.prop_get_amplitude(wfo)
#     abs_loc = proper.prop_get_gridsize(wfo)/2-np.array(spec_loc)
#
#     fwhm = 3.37
#     # I = after_dm[abs_loc[1],abs_loc[0]]
#     print abs_loc
#
#     I = aper_phot(after_dm,[abs_loc[1],abs_loc[0]], fwhm, show_region)
#     # plt.imshow(masked)
#     # plt.figure()
#     # plt.plot(masked[128],'o-')
#     # plt.show()
#
#     print 'aper_phot', I
#
#     return I
#
# # def view_datacube(datacube):
# #     fig =plt.figure(figsize=(14,10))
# #     colors = len(datacube)
# #     width = 5
# #     height = colors/width + 1
# #     print height
#
# #     for w in range(colors):
# #         ax = fig.add_subplot(height,width,w+1)
# #         ax.imshow(np.log10(datacube[w]), interpolation='none', origin='lower', cmap="viridis")
# #     plt.tight_layout()
# #     plt.show()
#
# # def quicklook_wf(wfo, logAmp=True, show=True):
#
# #     after_dm = proper.prop_get_amplitude(wfo)
# #     phase_afterdm = proper.prop_get_phase(wfo)
#
# #     fig =plt.figure(figsize=(14,10))
# #     ax1 = plt.subplot2grid((3, 2), (0, 0),rowspan=2)
# #     ax2 = plt.subplot2grid((3, 2), (0, 1),rowspan=2)
# #     ax3 = plt.subplot2grid((3, 2), (2, 0))
# #     ax4 = plt.subplot2grid((3, 2), (2, 1))
# #     if logAmp:
# #         ax1.imshow(np.log10(after_dm), origin='lower', cmap="viridis")
# #     else:
# #         ax1.imshow(after_dm, origin='lower', cmap="viridis")
# #     ax2.imshow(phase_afterdm, origin='lower', cmap="viridis")#, vmin=-0.5, vmax=0.5)
#
# #     ax3.plot(after_dm[int(tp.grid_size/2)])
# #     ax3.plot(np.sum(np.eye(tp.grid_size)*after_dm,axis=1))
#
# #     # plt.plot(np.sum(after_dm,axis=1)/after_dm[128,128])
#
# #     ax4.plot(phase_afterdm[int(tp.grid_size/2)])
# #     plt.xlim([0,proper.prop_get_gridsize(wfo)])
# #     fig.set_tight_layout(True)
# #     if show==True:
# #         plt.show()
# #     # ans = raw_input('here')
#
# def FPWFS(wfo, f_lens, dm_z):
#
#     def add_speckle(wfo, spec_loc):
#
#         # spec_loc = [28,28]
#
#
#         speckle = np.roll(np.roll(wfo.wfarr, spec_loc[0],1),spec_loc[1],0)/5#[92,92]
#         wfo.wfarr = (wfo.wfarr+speckle)
#         # wfo.wfarr = speckle
#     spec_loc = [20,0]
#     angle = math.atan2(spec_loc[1],spec_loc[0])
#     print 'angle', angle
#     add_speckle(wfo, spec_loc)
#
#     # before_dm = proper.prop_get_amplitude(wfo)
#     # phase_b4dm = proper.prop_get_phase(wfo)
#     # plt.figure()
#     # plt.subplot(2,2,1)
#     # plt.imshow(before_dm)
#     # plt.subplot(2,2,2)
#     # plt.imshow(phase_b4dm)
#     # plt.subplot(2,2,3)
#     # plt.plot(before_dm[128])
#     # plt.subplot(2,2,4)
#     # plt.plot(phase_b4dm[128])
#
#     proper.prop_propagate(wfo, f_lens, "telescope pupil imaging lens")
#     proper.prop_lens(wfo, f_lens, "telescope pupil imaging lens")
#     proper.prop_propagate(wfo, f_lens, "DM")
#     nact = 100                       # number of DM actuators along one axis
#     nact_across_pupil = 100          # number of DM actuators across pupil
#     dm_xc = nact / 2
#     dm_yc = nact / 2
#     d_beam = 2 * proper.prop_get_beamradius(wfo)        # beam diameter
#     act_spacing = d_beam / nact_across_pupil     # actuator spacing
#     # map_spacing = proper.prop_get_sampling(wfo)         # map sampling
#
#     # amp_conj = proper.prop_get_amplitude(wfo)
#     # phase_conj = proper.prop_get_phase(wfo)
#     # plt.figure()
#     # plt.subplot(2,2,1)
#     # plt.imshow(amp_conj)
#     # plt.subplot(2,2,2)
#     # plt.imshow(phase_conj)
#     # plt.subplot(2,2,3)
#     # plt.plot(amp_conj[128])
#     # plt.subplot(2,2,4)
#     # plt.plot(phase_conj[128])
#     # plt.title(proper.prop_get_refradius(wfo)  )
#     # plt.show()
#
#     # obj_map = np.ones((100,100))*np.cos(np.linspace(0,28*np.pi,100))*0.01e-6# 1e-9 [78,128]
#     # obj_map = np.ones((100,100))*0.1e-6*np.cos(np.linspace(0,30*np.pi,100))*(0.54-0.46*np.cos(2*np.pi*np.linspace(0,100,100)/99))
#     # obj_map = np.ones((256,256))*np.concatenate((np.linspace(-np.pi,np.pi,64),np.linspace(-np.pi,np.pi,64),np.linspace(-np.pi,np.pi,64),np.linspace(-np.pi,np.pi,64)))*2*np.pi
#     # obj_map = np.ones((100,100))*np.cos(np.linspace(0,30*np.pi,100)+5*np.pi/4)*-0.04e-6 #+ np.ones((100,100))*0.5e-6*(-0.496040945304/(2*np.pi)) #2.1991 #.01e-6
#     # obj_map = np.ones((100,100))*np.cos(np.linspace(0,28*np.pi,100))*0.01e-6 + np.ones((100,100))*2*0.5e-6/4. #0.0848
#
#     def calc_k(pixel_coords=spec_loc):
#         fwhm = 3.37
#         dist = np.sqrt(pixel_coords[0]**2 + pixel_coords[1]**2)
#         k = dist/fwhm
#         return k
#
#     def create_obj_map(angle=0, k=5, nact=100, alpha_dm=np.pi, dm_z=0.246):#0.01e-6
#         theta = angle#(angle/180.) * np.pi
#         x_k = k*np.cos(theta) #higher freq on the sizes compared to diag
#         y_k = k*np.sin(theta)
#
#         x_phi = alpha_dm*np.cos(theta)
#         y_phi = alpha_dm*np.sin(theta)
#
#         obj_map = np.zeros((nact, nact))
#         y = np.linspace(0,y_k*2*np.pi,nact) +y_phi # first column
#         xmid = (nact/2)-1
#
#         y_noshift = np.linspace(0,y_k*2*np.pi,nact)
#         # a = np.cos(np.linspace(0,x_k*2*np.pi,nact)[xmid])
#         a = np.linspace(y_noshift[50], y_noshift[50]+x_k*2*np.pi, nact)[xmid]
#         x_test = np.cos(np.linspace(y_noshift[50], y_noshift[50]+x_k*2*np.pi, nact)+a)[xmid]
#
#         if x_test != 1:
#             a = -a
#
#         for row in range(len(y)):
#             x = np.cos(np.linspace(y[row],y[row]+x_k*2*np.pi,nact)+a+x_phi)
#             obj_map[row] = x
#         print alpha_dm, 'alpha_dm'
#
#         # plt.figure()
#         # a =  np.cos(np.linspace(0,x_k*2*np.pi,nact)[xmid])
#         # print np.arccos(a)
#         # print (nact/2)-1,a
#         # plt.plot((nact/2)-1,a, 'o')
#         # plt.plot(np.cos(np.linspace(0,x_k*2*np.pi,nact)))
#         # plt.figure()
#
#         # plt.subplot(2,1,1)
#         # plt.plot(obj_map[50])
#         # plt.subplot(2,1,2)
#         # plt.imshow(obj_map)
#         # plt.show()
#
#         lamda = proper.prop_get_wavelength(wfo)#0.5e-6
#         obj_map = obj_map * lamda*dm_z/(2*np.pi)
#
#         return obj_map
#
#     # phi_dm = 0.9234
#     dm_z = 0.246 #-2pi -> 2pi 0.5e-6#
#     # angle =45
#     k = calc_k()
#
#     # exit()
#     def propagate_DM(alpha_dm, k, use_DM=True, show_fig=False):
#         print angle
#         print 'alpha_dm', alpha_dm
#
#         obj_map = create_obj_map(angle, k, nact, alpha_dm, dm_z)
#
#         wf_temp = copy.copy(wfo)
#
#         if use_DM:
#             dmap = proper.prop_dm(wf_temp, obj_map, dm_xc, dm_yc, act_spacing, FIT = True)
#
#         proper.prop_lens(wf_temp, f_lens)
#         proper.prop_propagate(wf_temp, f_lens)
#
#         after_dm = proper.prop_get_amplitude(wf_temp)
#         phase_afterdm = proper.prop_get_phase(wf_temp)
#
#         abs_loc = proper.prop_get_gridsize(wf_temp)/2-np.array(spec_loc)
#
#         del wf_temp
#         I = after_dm[abs_loc[1],abs_loc[0]]
#
#         if show_fig:
#             plt.figure(figsize=(14,14))
#             plt.subplot(2,2,1)
#             plt.imshow(np.sqrt(after_dm))
#             plt.subplot(2,2,2)
#             plt.imshow(phase_afterdm)
#             plt.subplot(2,2,3)
#             plt.plot(after_dm[128])
#             # plt.plot(np.sum(np.eye(256)*after_dm,axis=1))
#             plt.subplot(2,2,4)
#             plt.plot(phase_afterdm[128])
#             plt.show()
#         # print 'flat phase', phase_afterdm[128,178]
#         # print 'flat int', after_dm[128,178]
#         p = phase_afterdm[abs_loc[1],abs_loc[0]]
#         print 'intensity', I
#         return I, p
#
#     # first get uneffected speckle intensity
#     # I_dm = propagate_DM(phi_dm=0,use_DM=False, show_fig=True)
#     # print 'speckle intensity', I_dm
#
#     def get_phi_alph_dm_calib():
#         # alphas = np.linspace(0,2*np.pi,10)
#         alphas = [0,0.2]
#         # ps = np.zeros(len(alphas))
#         # Is = np.zeros(len(alphas))
#         # ks = np.linspace(5,15,30)
#         ps = np.zeros(len(alphas))
#         # Is = np.zeros(len(ks))
#         for ia, a in enumerate(alphas):
#         # for ik, k in enumerate(ks):
#             # print k
#             # print 'a', a
#             # if ia % 3 == True:
#             #     show_fig=True
#             # else:
#             #     show_fig=False
#             _, p = propagate_DM(alpha_dm=a, k=k, show_fig=False)
#             ps[ia] = p
#             # Is[ik] = I
#         c = ps[0]
#         m = (ps[1] - c)/alphas[1]
#         print c, m
#
#         plt.plot(alphas, ps, 'o-')
#         # plt.plot(ks, Is, 'o-')
#
#         # plt.plot(np.linspace(0,2*np.pi,100), m*np.linspace(0,np.pi,100)+c)
#         plt.show()
#
#         return [m,c]
#
#     # phase_conv = get_phi_alph_dm_calib()
#     # def conv_alph_phi(alpha, coeffs):
#     #     phi = coeffs[0]*alpha + coeffs[1]
#     #     return phi
#
#     # # alphas = np.arccos(phis/(2*np.pi)) - 2*np.pi*spec_loc[0]/(256/k)
#
#     # # alphas = phis - np.pi/2 #
#     # # alphas = [4.83,3.29,1.69,0.142]
#     # alphas = conv_phi_alph(phis)#0.89-phis
#
#     # phi_dm = conv_alph_phis(0.5, phase_conv)
#     # print phi_dm
#     # exit()
#     # then iteratively probe the speckle
#     # propagate_DM(0, show_fig=False)
#     # exit()
#
#     # def get_phi_offset():
#     #     _, p = propagate_DM(alpha_dm=0, k=k, show_fig=False)
#     #     return p
#
#     # p = get_phi_offset()
#     # print 'p', p
#     coeffs = [-1.144,1.1156]
#     def conv_phi_alph(phi,coeffs):#p=0.8
#         alpha = (phi - coeffs[1])/coeffs[0]
#         # alpha = p-phi# - np.pi/2
#         return alpha
#
#     phis = np.arange(0,2*np.pi,np.pi/2)
#     alphas = conv_phi_alph(phis, coeffs)#0.519-phis #0.568
#
#     print 'phis', phis
#     print k
#     print alphas
#
#     # Is = np.zeros(4)
#     # # print phis
#     # for i in range(4):
#     #     alpha_dm = alphas[i]
#     #     print 'alpha_dm', alpha_dm
#     #     I,_ = propagate_DM(alpha_dm, k=k, show_fig=True)
#     #     # I = propagate_DM(alpha_dm, show_fig=False)
#     #     Is[i] = I
#
#     # fileDMz = "dm_zs.txt"
#
#     # print 'Is', Is
#
#
#
#     # print 'all this stuff is untested/incomplete!'
#     # def calc_phi_dm(Is):
#     #     phi_s = math.tan((Is[3]-Is[1])/ (Is[0]-Is[2]))
#     #     print 'phi_s', phi_s
#     #     phi_dm = phi_s-np.pi
#     #     return phi_dm
#
#     # def get_dm_z(file_dmz, I_dm):
#     #     with open(fileDMz, "a") as myfile:
#     #         print myfile.read()
#     #     # then interpolate dm_z vs I_dm
#     #     # then read off dm_z
#
#     # print 'until here'
#
#     # phi_dm = calc_phi_dm(Is)
#     # alpha_dm = conv_phi_alph(phi_dm, coeffs)#0.519-phi_dm# - np.pi/2
#     # # alpha_dm = np.arccos(phi_dm/(2*np.pi)) - 2*np.pi*k
#     # print phi_dm, 'phi_dm'
#     # propagate_DM(alpha_dm, k, use_DM=True, show_fig=True)
#
#     def brute_force():
#         phis = np.arange(0,2*np.pi,np.pi/2)
#         Is = np.zeros(4)
#         for i in range(4):
#             I,_ = propagate_DM(phis[i], k=k, show_fig=True)
#             Is[i] = I
#         iphi = np.argmin(Is)
#         print iphi, phis[iphi]
#         return
#
#     brute_force()
#
#     exit()
#
#     # if dm_z != None:
#     #     with open(fileDMz, "a") as myfile:
#     #         myfile.write(str(dm_z)+ ',' + str(after_dm[128,178])+'\n')
#
#     # plt.title(proper.prop_get_refradius(wfo)  )
#     # plt.figure()
#     # proper.prop_add_phase( wfo, -2*(phase_afterdm*0.5e-6/(2*np.pi)) )
#     # phase = proper.prop_get_phase(wfo)
#     # plt.imshow(phase)
#     # plt.figure()
#     # plt.plot(phase[128])
#
#     # plt.figure()
#     # plt.imshow(proper.prop_get_amplitude(old_wfo) - proper.prop_get_amplitude(wfo))
#     # print proper.prop_get_amplitude(old_wfo) - proper.prop_get_amplitude(wfo)
#
#     # hdulist = pyfits.open('psf.fits')
#     # psf = hdulist[0].data
#     # # plt.imshow(psf)
#     # # plt.show()
#
#     # errs = proper.prop_get_amplitude(wfo)
#     # plt.figure()
#     # plt.imshow(errs)
#
#     # # print np.shape(errs), np.shape(psf), type(errs), type(psf)
#     # xlocs, ylocs = vip.phot.detection(errs, psf, debug=False, mode='lpeaks', snr_thresh=2,
#     #                bkg_sigma=1, matched_filter=False, full_output=False)
#     # # for x, y in zip(xlocs, ylocs):
#     # #     print x
#     # #     print y
#     # #     print errs[int(x),int(y)]
#
#
#     plt.show()
#
#     return