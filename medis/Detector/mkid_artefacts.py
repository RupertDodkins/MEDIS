"""
This code handles the MKID-related distortions to the ideal wavefront
e.g. uncertainty in responsivity, R, dead pixels, hot pixels, missing feedlines
"""

import numpy as np
from matplotlib import pyplot as plt
from .distribution import *
import random
import pickle as pickle
from medis.params import mp, ap, tp, iop, dp, sp
from medis.Utils.misc import dprint
from . import spectral as spec
import medis.Detector.pipeline as pipe
from medis.Utils.plot_tools import quicklook_im


def remove_close(stem):
    dprint('removing close photons')
    for x in range(mp.array_size[1]):
        for y in range(mp.array_size[0]):
            print(x,y)
            if len(stem[x][y]) > 1:
                events = np.array(stem[x][y])
                timesort = np.argsort(events[:, 0])
                events = events[timesort]
                detected = [0]
                idx = 0
                while idx != None:
                    these_times = events[idx:, 0] - events[idx, 0]
                    detect, _ = next(((i, v) for (i, v) in enumerate(these_times) if v > mp.dead_time), (None, None))
                    if detect != None:
                        detect += idx
                        detected.append(detect)
                    idx = detect

                missed = [ele for ele in range(detected[-1] + 1) if ele not in detected]
                events = np.delete(events, missed, axis=0)
                stem[x][y] = events
    return stem


def makecube(packets, array_size):
    stem = pipe.arange_into_stem(packets, (array_size[0], array_size[1]))

    # if mp.remove_close:
    #     cube = remove_close_photons(cube)

    # Interpolating spectral cube from ap.nwsamp discreet wavelengths
    # if sp.show_cube or sp.return_spectralcube:
    spectralcube = pipe.make_datacube(stem, (array_size[0], array_size[1], ap.w_bins))

    return spectralcube

def initialize():
    # dp = device_params()
    dprint(f"dp.hot_pix set to {dp.hot_pix}")
    dp.platescale = mp.platescale
    dp.array_size = mp.array_size
    dp.dark_pix_frac = mp.dark_pix_frac
    dp.hot_pix = mp.hot_pix
    dp.lod = mp.lod
    dp.QE_map_all = array_QE(plot=False)
    dp.responsivity_error_map = responvisity_scaling_map(plot=False)
    if mp.pix_yield == 1:
        mp.bad_pix =False
    if mp.bad_pix == True:
        dp.QE_map = create_bad_pix(dp.QE_map_all)
        # dp.QE_map = create_hot_pix(dp.QE_map)
        # quicklook_im(dp.QE_map_all)
        if mp.dark_counts:
            dp.dark_locs = create_false_pix(mp, amount = int(mp.dark_pix_frac*mp.array_size[0]*mp.array_size[1]))
            dp.dark_per_step = int(np.round(ap.sample_time*mp.dark_bright))
        if mp.hot_pix:
            dp.hot_locs = create_false_pix(mp, amount = mp.hot_pix)
            dp.hot_per_step = int(np.round(ap.sample_time*mp.hot_bright))
            dprint(dp.hot_per_step)
        # dp.QE_map = create_bad_pix_center(dp.QE_map)
    dp.Rs = assign_spectral_res(plot=False)
    dp.sigs = get_R_hyper(dp.Rs, plot=False)
    dprint(f"dp.sigs.shape ={ dp.sigs.shape}")
    # get_phase_distortions(plot=True)
    if mp.phase_background:
        dp.basesDeg = assign_phase_background(plot=False)
    else:
        dp.basesDeg = np.zeros((mp.array_size))
    with open(iop.device_params, 'wb') as handle:
        pickle.dump(dp, handle, protocol=pickle.HIGHEST_PROTOCOL)
    return dp

def truncate_array(frames):
    """Make non-square array"""
    # orig_shape = np.shape(frames)[2:4]
    orig_shape = np.shape(frames)[1:3]

    diff = orig_shape - mp.array_size
    dprint(f"orig_shape = {orig_shape,}, mp.arrray_size = { mp.array_size}, diff = {diff}")
    resid = np.array([np.int_(np.ceil(diff/2.)), np.int_(np.floor(diff/2.))])

    if len(np.shape(frames)) == 4:
        frames = frames[:,:,resid[0,0]:orig_shape[0]-resid[1,0], resid[0,1]:orig_shape[1]-resid[1,1]]
    else:
        frames = frames[:,resid[0,0]:orig_shape[0]-resid[1,0], resid[0,1]:orig_shape[1]-resid[1,1]]
    print(f"Frame shape = {np.shape(frames)}")

    # frames = frames[:, :, 22:-23]
    return frames

def responvisity_scaling_map(plot=False):
    """Assigns each pixel a phase responsivity between 0 and 1"""
    dist = Distribution(gaussian(mp.r_mean, mp.r_sig, np.linspace(0, 2, mp.res_elements)), interpolation=True)
    responsivity = dist(mp.array_size[0] * mp.array_size[1])[0]/float(mp.res_elements) * 2
    if plot:
        plt.xlabel('Responsivity')
        plt.ylabel('#')
        plt.hist(responsivity)
        plt.show()
    responsivity = np.reshape(responsivity, mp.array_size[::-1])
    if plot:
        quicklook_im(responsivity)#plt.imshow(QE)
        # plt.show()

    return responsivity

def array_QE(plot=False):
    """Assigns each pixel a phase responsivity between 0 and 1"""
    dist = Distribution(gaussian(mp.g_mean, mp.g_sig, np.linspace(0, 1, mp.res_elements)), interpolation=True)
    QE = dist(mp.array_size[0] * mp.array_size[1])[0]/float(mp.res_elements)
    if plot:
        plt.xlabel('Responsivity')
        plt.ylabel('#')
        plt.hist(QE)
        plt.show()
    QE = np.reshape(QE, mp.array_size[::-1])
    if plot:
        quicklook_im(QE)#plt.imshow(QE)
        # plt.show()

    return QE

def assign_spectral_res(plot=False):
    """Assigning each pixel a spectral resolution (at 800nm)"""
    dist = Distribution(gaussian(0.5, 0.25, np.linspace(-0.2, 1.2, mp.res_elements)), interpolation=True)
    # dprint(f"Mean R = {mp.R_mean}")
    Rs = (dist(mp.array_size[0]*mp.array_size[1])[0]/float(mp.res_elements)-0.5)*mp.R_sig + mp.R_mean#
    if plot:
        plt.xlabel('R')
        plt.ylabel('#')
        plt.hist(Rs)
        plt.show()
    Rs = np.reshape(Rs, mp.array_size)

    if plot:
        plt.figure()
        plt.imshow(Rs)
        plt.show()
    return Rs

def get_R_hyper(Rs, plot=False):
    """Each pixel of the array has a matrix of probabilities that depends on the input wavelength"""
    print('Creating a cube of R standard deviations')
    m = (-1*Rs/10)/(ap.band[1] - ap.band[0]) # looses R of 10% over the 700 band
    # plt.plot(m[0])
    # plt.show()
    c = Rs-m*ap.band[0] # each c depends on the R @ 800
    # plt.plot(c)
    # plt.show()
    dprint(ap.w_bins)
    waves = np.ones((np.shape(m)[1],np.shape(m)[0],ap.w_bins+5))*np.linspace(ap.band[0],ap.band[1],ap.w_bins+5)
    waves = np.transpose(waves) # make a tensor of 128x128x10 where every 10 vector is 800... 1500
    R_spec = m * waves + c # 128x128x10 tensor is now lots of simple linear lines e.g. 50,49,.. 45
    # probs = np.ones((np.shape(R_spec)[0],np.shape(R_spec)[1],np.shape(R_spec)[2],
    #                 mp.res_elements))*np.linspace(0, 1, mp.res_elements)
    #                         # similar to waves but 0... 1 using 128 elements
    # R_spec = np.repeat(R_spec[:,:,:,np.newaxis], mp.res_elements, 3) # creat 128 repeats of R_spec so (10,128,128,128)
    # mp.R_probs = gaussian(0.5, R_spec, probs) #each xylocation is gaussian that gets wider for longer wavelengths
    sigs_w = (waves/R_spec)/2.35 #R = w/dw & FWHM = 2.35*sig

    # plt.plot(range(0,1500),spec.phase_cal(np.arange(0,1500)))
    # plt.show()
    sigs_p = spec.phase_cal(sigs_w) - spec.phase_cal(np.zeros_like((sigs_w)))

    if plot:
        plt.plot(R_spec[:, 0, 0])
        plt.plot(R_spec[:,50,15])
        plt.figure()
        plt.plot(sigs_w[:,0,0])
        plt.plot(sigs_w[:,50,15])
        plt.figure()
        plt.plot(sigs_p[:, 0, 0])
        plt.plot(sigs_p[:, 50, 15])
        plt.figure()
        plt.imshow(sigs_p[:,:,0], aspect='auto')
        # plt.imshow(mp.R_probs[:,0,0,:])
        plt.show()
    return sigs_p

def apply_phase_scaling(photons, ):
    """
    From things like resonator Q, bias power, quasiparticle losses

    :param photons:
    :return:
    """

def apply_phase_offset_array(photons, sigs):
    """
    From things like IQ phase offset noise

    :param photons:
    :param sigs:
    :return:
    """
    wavelength = spec.wave_cal(photons[1])

    # plt.xlabel('Photons')
    # plt.ylabel('#')
    # plt.title('Photons Distortion Histogram')
    # plt.hist(photons[1], bins=800)
    # plt.figure()
    idx = spec.wave_idx(wavelength)

    bad = np.where(np.logical_or(idx>=len(sigs), idx<0))[0]

    photons = np.delete(photons, bad, axis=1)
    idx = np.delete(idx, bad)

    # dprint((len(sigs), bad, np.shape(photons)))
    # plt.hist(wavelength, bins=800)
    # plt.xlabel('Wavelength')
    # plt.ylabel('#')
    # plt.title('Wavelength Distortion Histogram')
    # plt.figure()
    # plt.xlabel('Index')
    # plt.ylabel('#')
    # plt.title('Index Distortion Histogram')
    # plt.hist(idx, bins=800)
    # plt.show()
    # dprint((sigs[0,:25,:25],idx.shape,sigs.shape))#,sigs[idx].shape))
    # dprint(sigs.shape)

    distortion = np.random.normal(np.zeros((photons[1].shape[0])),
                                  sigs[idx,np.int_(photons[3]), np.int_(photons[2])])
    # plt.hist(distortion)
    # plt.show()
    # dprint((distortion[:25], distortion.shape,sigs[idx,np.int_(photons[3]), np.int_(photons[2])].shape))
    good_pix = np.logical_and(photons[1] != 0, idx < len(sigs))
    # plt.figure()
    # plt.hist(photons[1][good_pix])
    # plt.show()
    # plt.figure()
    # plt.hist(photons[1])
    # plt.show()
    photons[1][good_pix] += distortion[good_pix]
    # plt.figure()
    # plt.hist(photons[1][good_pix])
    # plt.show()
    # plt.figure()
    # plt.hist(photons[1])
    # plt.show()

    return photons

def apply_phase_distort(phase, loc, sigs):
    """
    Simulates phase height of a real detector system per photon
    proper will spit out the true phase of each photon it propagates. this function will give it
    a 'measured' phase based on the resolution of the detector, and a Gaussian distribution around
    the center of the resolution bin

    :param phase: real(exact) phase information from Proper
    :param loc:
    :param sigs:
    :return: distorted phase
    """
    # phase = phase + mp.phase_distortions[ip]
    wavelength = spec.wave_cal(phase)
    idx = spec.wave_idx(wavelength)

    if phase != 0 and idx<len(sigs):
        phase = np.random.normal(phase,sigs[idx,loc[0],loc[1]],1)[0]
    return phase


def assign_phase_background(plot=False):
    """assigns each pixel a baseline phase"""
    dist = Distribution(gaussian(0.5, 0.25, np.linspace(-0.2, 1.2, mp.res_elements)), interpolation=True)

    basesDeg = dist(mp.array_size[0]*mp.array_size[1])[0]/float(mp.res_elements)*mp.bg_mean/mp.g_mean
    if plot:
        plt.xlabel('basesDeg')
        plt.ylabel('#')
        plt.title('Background Phase')
        plt.hist(basesDeg)
        plt.show(block=True)
    basesDeg = np.reshape(basesDeg, mp.array_size)
    if plot:
        plt.title('Background Phase--Reshaped')
        plt.imshow(basesDeg)
        plt.show(block=True)
    return basesDeg


def create_bad_pix(QE_map_all, plot=False):
    amount = int(mp.array_size[0]*mp.array_size[1]*(1.-mp.pix_yield))

    bad_ind = random.sample(list(range(mp.array_size[0]*mp.array_size[1])), amount)

    dprint(f"Bad indices = {len(bad_ind)}, # MKID pix = { mp.array_size[0]*mp.array_size[1]}, "
           f"Pixel Yield = {mp.pix_yield}, amount? = {amount}")

    # bad_y = random.sample(y, amount)
    bad_y = np.int_(np.floor(bad_ind/mp.array_size[1]))
    bad_x = bad_ind % mp.array_size[1]

    # dprint(f"responsivity shape  = {responsivities.shape}")
    QE_map = np.array(QE_map_all)

    QE_map[bad_x, bad_y] = 0
    if plot:
        plt.xlabel('responsivities')
        plt.ylabel('?')
        plt.title('Something Related to Bad Pixels')
        plt.imshow(QE_map)
        plt.show()

    return QE_map


def create_bad_pix_center(responsivities):
    res_elements=mp.array_size[0]
    # responsivities = np.zeros()
    for x in range(mp.array_size[1]):
        dist = Distribution(gaussian(0.5, 0.25, np.linspace(0, 1, mp.res_elements)), interpolation=False)
        dist = np.int_(dist(int(mp.array_size[0]*mp.pix_yield))[0])#/float(mp.res_elements)*np.int_(mp.array_size[0]) / mp.g_mean)
        # plt.plot(dist)
        # plt.show()
        dead_ind = []
        [dead_ind.append(el) for el in range(mp.array_size[0]) if el not in dist]
        responsivities[x][dead_ind] = 0

    return responsivities

def get_hot_packets(dp, step):
    photons = np.zeros((4, dp.hot_per_step))
    phases = np.random.uniform(-120, 0, dp.hot_per_step)
    # print('**WARNING** adding photons in random locations with random phases between hardcoded values 0 and -120')
    meantime = step*ap.sample_time
    photons[0] = np.random.uniform(meantime-ap.sample_time/2, meantime+ap.sample_time/2, len(photons[0]))
    photons[1] = phases
    hot_ind = np.random.choice(range(len(dp.hot_locs[0])), dp.hot_per_step)
    hot_pix = dp.hot_locs[:, hot_ind]
    photons[2:] = hot_pix
    return photons

def get_dark_packets(dp, step):
    n_device_counts = dp.dark_per_step * dp.dark_pix_frac * mp.array_size[0] * mp.array_size[1]
    if n_device_counts % 1 > np.random.uniform(0,1,1):
        n_device_counts += 1

    n_device_counts = int(n_device_counts)
    # dprint((n_device_counts, dp.dark_per_step))
    photons = np.zeros((4, n_device_counts))
    if n_device_counts > 0:
        dist = Distribution(gaussian(0, 0.25, np.linspace(0, 1, mp.res_elements)), interpolation=False)
        # phases = (dist(dp.dark_per_step)[0]) / float(dp.dark_per_step - 0.5) * 45e3 - 120
        # dprint(dp.dark_per_step)
        phases = dist(n_device_counts)[0]
        max_phase = max(phases)
        phases = -phases*120/max_phase
        # dprint(phases)
        # phases = np.random.uniform(-120, 0, dp.dark_per_step) *
        # print('**WARNING** adding photons in random locations with random phases between hardcoded values 0 and -120')
        meantime = step*ap.sample_time
        photons[0] = np.random.uniform(meantime-ap.sample_time/2, meantime+ap.sample_time/2, len(photons[0]))
        photons[1] = phases

        # dprint(dp.dark_pix)
        bad_pix_options = create_false_pix(dp, dp.dark_pix_frac * dp.array_size[0]*dp.array_size[1])
        bad_ind = np.random.choice(range(len(bad_pix_options[0])),n_device_counts)
        # dprint((dp.dark_per_step, bad_ind, np.shape(bad_pix_options)))
        bad_pix = bad_pix_options[:,bad_ind]
        # dprint(bad_pix)
        photons[2:] = bad_pix

    # dprint(photons.shape)
    return photons


def create_false_pix(dp, amount):
    # dprint(f"amount = {amount}")
    bad_ind = random.sample(list(range(dp.array_size[0]*dp.array_size[1])), int(amount))
    bad_y = np.int_(np.floor(bad_ind / dp.array_size[1]))
    bad_x = bad_ind % dp.array_size[1]

    return np.array([bad_x, bad_y])


def remove_bad(frame, QE):
    bad_map = np.ones((ap.grid_size,ap.grid_size))
    bad_map[QE[:-1,:-1]==0] = 0
    # quicklook_im(QE, logAmp =False)
    # quicklook_im(bad_map, logAmp =False)
    frame = frame*bad_map
    return frame


# def remap_image(datacube):
#     print datacube.shape, mp.array_size
#     from scipy import interpolate
#     f= interpolate.interp2d(range(datacube.shape[0]), range(datacube.shape[0]), datacube)
#     dm_map = f(np.linspace(0,dm_map.shape[0],nact),np.linspace(0,dm_map.shape[0],nact))

# def apply_false_counts(QE):
#   return QE

# def sample_fake_cube(frames, num_events):
#     dist = Distribution(uniform, interpolation=False)
#     photons = dist(num_events)
#     print np.shape(photons)

#     return photons



# def get_phase_background(R, samples=1):
#     #dist = Distribution(gaussian(bg_mean*QE, bg_sig, np.linspace(bg_mean-bg_sig, bg_mean+bg_sig, res_elements)), interpolation=False)
#     dist = Distribution(gaussian(mp.g_mean, 0.4, np.linspace(0, 1, mp.res_elements)), interpolation=False)
#     plt.plot(gaussian(mp.g_mean, 0.4, np.linspace(0, 1, mp.res_elements)))
#     # plt.plot(gaussian(mp.bg_mean*mp.QE, mp.bg_sig, np.linspace(mp.bg_mean-mp.bg_sig, mp.bg_mean+mp.bg_sig, mp.res_elements)))


#     phase = dist(samples)[0]/float(mp.res_elements)*mp.bg_mean/mp.g_mean
#     print phase
#     # if distort_phase:
#     phase = distort_phase(phase, R)
#     print phase
#     plt.show()
#     # plt.plot(dist(1000)[0]* -bg_sig/1000.)
#     # plt.show()
#     return phase[0]

# def add_hot_pix(datacube, dp, step, plot=False):
#     # if dp.hot_pix == None:
#     #     dp.hot_pix = create_hot_pix(datacube)
#
#     # dprint(dp.hot_pix[0].shape)
#     # dprint(datacube.shape)
#     # quicklook_im(dp.hot_pix[0])
#
#     datacube += np.resize(dp.hot_pix[0], (datacube.shape[0],datacube.shape[1],datacube.shape[2]))
#     return datacube

# decided to add hot pixel packets rather than hot pixels to datacube since MKID array dithers
# def create_hot_pix(plot=True):
#     # extend this to have an evolving hot pix pattern
#     # hot_pix = np.zeros((ap.numframes,datacube.shape[1],datacube.shape[2]))
#
#     # hot_pix = np.zeros((1,mp.array_size[0],mp.array_size[1]))
#     # You're adding hot pix to the seed datacube so use those dimensions
#     hot_pix = np.zeros((1,mp.array_size[1], mp.array_size[0]))
#     # hot_counts = np.max(datacube)
#     hot_counts = 5e-4#1e-1#1e-3#10
#     x = np.arange(mp.array_size[1])
#     y = np.arange(mp.array_size[0])
#     amount = mp.hot_pix
#
#     dprint(amount)
#     bad_ind = random.sample(list(range(mp.array_size[0]*mp.array_size[1])), amount)
#     bad_y = np.int_(np.floor(bad_ind / mp.array_size[1]))
#     bad_x = bad_ind % mp.array_size[1]
#
#     dprint((bad_x, bad_y))
#     hot_pix[0,bad_x,bad_y] = hot_counts
#
#     if plot:
#         loop_frames(hot_pix)
#
#     return hot_pix


# def distort_phase(phase, R=10, Rs):
#     # for ip, p in enumerate(phase):
#     #     res_elements=100
#     #     dist = Distribution(gaussian(mp.g_mean, mp.g_mean/R, np.linspace(0, 1, res_elements)), interpolation=False)
#         # phase[ip] = dist(1)[0]/float(res_elements)*p / mp.g_mean
#     Rindx = ((R - np.min(Rs)) / np.max(Rs)) * mp.res_elements
#     Rindx = np.round(Rindx)
#     phase = mp.potench_R_matrix[Rindx]
#     # return phase

# def get_phase_distortions(plot=False):
#     print '**** this is untested! ****'
#     potench_R_matrix = np.zeros((mp.res_elements,mp.res_elements))
#     Rprofile = gaussian(0, 0.25, np.linspace(-0.7, 0.7, mp.res_elements))*mp.R_sig + mp.R_mean
#     for iR, R in enumerate(np.linspace(np.min(Rs), np.max(Rs), mp.res_elements)):
#         # each row is a Gaussian with each successive Gaussin is thinner
#         potench_R_matrix[iR] = gaussian(mp.g_mean, mp.g_mean/R, np.linspace(0, 1, mp.res_elements))
#         # normalise the PDF of each row
#         potench_R_matrix[iR] = potench_R_matrix[iR]/sum(potench_R_matrix[iR])
#         # mutliply each row by the PDF of the total R distribution so middle rows (middle R) have a greater probability
#         potench_R_matrix[iR] = potench_R_matrix[iR]*Rprofile[iR]

#     dist = Distribution(potench_R_matrix, interpolation=True)
#     mp.phase_distortions = dist(ap.star_photons_per_s)
#     if plot:
#         plt.plot(np.linspace(-0.7, 0.7, mp.res_elements), Rprofile)
#         plt.figure()
#         plt.imshow(potench_R_matrix, cmap='viridis')
#         plt.xlabel('Phase')
#         plt.ylabel('R')
#         plt.figure()
#         plt.hist(mp.phase_distortions)
#         plt.show()

