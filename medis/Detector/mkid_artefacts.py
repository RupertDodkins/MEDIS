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


def remove_close_photons(cube):
    # TODO test this
    dprint('**** this is untested! ****')
    # ind = np.argsort( photons[0,:] )
    # photons = photons[:,ind]
    image = np.zeros((mp.xnum, mp.ynum))
    for x in range(mp.xnum):
        for y in range(mp.ynum):
            events = np.array(cube[x][y])
            print(events, np.shape(events))
            try:
                diff = events[0, 0] - np.roll(events[0, 0], 1)
                print(x, y, diff)
            except IndexError:
                pass

    # missed =
    raise NotImplementedError
    return photons

def makecube(packets, array_size):
    cube = pipe.arange_into_cube(packets, (array_size[0], array_size[1]))

    if mp.remove_close:
        cube = remove_close_photons(cube)

    # Interpolating spectral cube from ap.nwsamp discreet wavelengths
    # if sp.show_cube or sp.return_spectralcube:
    spectralcube = pipe.make_datacube(cube, (array_size[0], array_size[1], ap.w_bins))

    return spectralcube

def initialize():
    # dp = device_params()
    dprint(f"dp.hot_pix set to {dp.hot_pix}")
    dp.response_map = array_response(plot=False)
    if mp.pix_yield == 1:
        mp.bad_pix =False
    if mp.bad_pix == True:
        dp.response_map = create_bad_pix(dp.response_map)
        # dp.response_map = create_hot_pix(dp.response_map)
        if mp.hot_pix:
            dp.hot_locs = create_hot_pix(mp)
            dp.hot_per_step = int(np.round(ap.sample_time*mp.hot_bright))
        # dp.response_map = create_bad_pix_center(dp.response_map)
    # quicklook_im(dp.response_map)
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


def array_response(plot=False):
    """Assigns each pixel a phase responsivity between 0 and 1"""
    dist = Distribution(gaussian(mp.g_mean, mp.g_sig, np.linspace(0, 1.2, mp.res_elements)), interpolation=True)
    response = dist(mp.array_size[0] * mp.array_size[1])[0]/float(mp.res_elements)
    if plot:
        plt.xlabel('Responsivity')
        plt.ylabel('#')
        plt.hist(response)
        plt.show()
    response = np.reshape(response, mp.array_size[::-1])
    if plot:
        quicklook_im(response)#plt.imshow(response)
        # plt.show()

    return response


def assign_spectral_res(plot=False):
    """Assigning each pixel a spectral resolution (at 800nm)"""
    dist = Distribution(gaussian(0.5, 0.25, np.linspace(-0.2, 1.2, mp.res_elements)), interpolation=True)
    dprint(f"Mean R = {mp.R_mean}")
    Rs = (dist(mp.array_size[0]*mp.array_size[1])[0]/float(mp.res_elements)-0.5)*mp.R_sig + mp.R_mean#
    if plot:
        plt.xlabel('R')
        plt.ylabel('#')
        plt.hist(Rs)
        plt.show()
    Rs = np.reshape(Rs, mp.array_size)
    # plt.imshow(Rs)
    # plt.show()
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
    waves = np.ones((np.shape(m)[1],np.shape(m)[0],ap.w_bins))*np.linspace(ap.band[0],ap.band[1],ap.w_bins)
    waves = np.transpose(waves) # make a tensor of 128x128x10 where every 10 vector is 800... 1500
    R_spec = m* waves + c # 128x128x10 tensor is now lots of simple linear lines e.g. 50,49,.. 45
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


def apply_phase_distort_array(photons, sigs):

    wavelength = spec.wave_cal(photons[1])

    plt.xlabel('Photons')
    plt.ylabel('#')
    plt.title('Photons Distortion Histogram')
    plt.hist(photons[1], bins=800)
    plt.figure()
    idx = spec.wave_idx(wavelength)
    bad = np.where(idx<0)[0]
    plt.hist(wavelength, bins=800)
    plt.xlabel('Wavelength')
    plt.ylabel('#')
    plt.title('Wavelength Distortion Histogram')
    plt.figure()
    plt.xlabel('Index')
    plt.ylabel('#')
    plt.title('Index Distortion Histogram')
    plt.hist(idx, bins=800)
    plt.show()
    # dprint((sigs[0,:25,:25],idx.shape,sigs.shape))#,sigs[idx].shape))

    distortion = np.random.normal(np.zeros((photons[1].shape[0])),
                                  sigs[idx,np.int_(photons[3]), np.int_(photons[2])])
    # dprint((distortion[:25], distortion.shape,sigs[idx,np.int_(photons[3]), np.int_(photons[2])].shape))
    good_pix = np.logical_and(photons[1] != 0, idx < len(sigs))
    photons[1][good_pix] += distortion[good_pix]

    return photons

def apply_phase_distort(phase, loc, sigs):
    """
    simulates phase height of a real detector system per photon
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
        plt.show()
    basesDeg = np.reshape(basesDeg, mp.array_size)
    if plot:
        plt.xlabel('basesDeg')
        plt.ylabel('#')
        plt.title('Background Phase--Reshaped')
        plt.imshow(basesDeg)
        plt.show()
    return basesDeg


def create_bad_pix(responsivities, plot=False):
    x = np.arange(mp.array_size[0])
    y = np.arange(mp.array_size[1])
    amount = int(mp.array_size[0]*mp.array_size[1]*(1.-mp.pix_yield))

    bad_ind = random.sample(list(range(mp.array_size[0]*mp.array_size[1])), amount)

    dprint(f"Bad indices = {len(bad_ind)}, # MKID pix = { mp.array_size[0]*mp.array_size[1]}, "
           f"Pixel Yield = { mp.pix_yield}, amount?? = {amount}")

    # bad_y = random.sample(y, amount)
    bad_y = np.int_(np.floor(bad_ind/mp.array_size[1]))
    bad_x = bad_ind % mp.array_size[1]

    # dprint(f"responsivity shape  = {responsivities.shape}")

    responsivities[bad_x, bad_y] = 0
    if plot:
        plt.xlabel('responsivities')
        plt.ylabel('?')
        plt.title('Something Related to Bad Pixels')
        plt.imshow(responsivities)
        plt.show()

    return responsivities


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


def get_hot_packets(dp):

    photons = np.zeros((3, dp.hot_per_step))
    phases = np.random.uniform(-120, 0, dp.hot_per_step)
    print('**WARNING** adding photons in random locations with random phases between hardcoded values 0 and -120')
    photons[0, :] = phases
    # dprint((photons[:,0:],np.transpose(dp.hot_locs)*np.ones((dp.hot_per_step,2))))
    photons[1:,:] = dp.hot_locs
    # dprint(photons)

    return photons


def create_hot_pix(mp):
    amount = mp.hot_pix

    # dprint(f"amount = {amount}")
    bad_ind = random.sample(list(range(mp.array_size[0]*mp.array_size[1])), amount)
    bad_y = np.int_(np.floor(bad_ind / mp.array_size[1]))
    bad_x = bad_ind % mp.array_size[1]

    return [bad_x, bad_y]


def remove_bad(frame, response):
    bad_map = np.ones((ap.grid_size,ap.grid_size))
    bad_map[response[:-1,:-1]==0] = 0
    # quicklook_im(response, logAmp =False)
    # quicklook_im(bad_map, logAmp =False)
    frame = frame*bad_map
    return frame


# def remap_image(datacube):
#     print datacube.shape, mp.array_size
#     from scipy import interpolate
#     f= interpolate.interp2d(range(datacube.shape[0]), range(datacube.shape[0]), datacube)
#     dm_map = f(np.linspace(0,dm_map.shape[0],nact),np.linspace(0,dm_map.shape[0],nact))

# def apply_false_counts(response):
#   return response

# def sample_fake_cube(frames, num_events):
#     dist = Distribution(uniform, interpolation=False)
#     photons = dist(num_events)
#     print np.shape(photons)

#     return photons



# def get_phase_background(R, samples=1):
#     #dist = Distribution(gaussian(bg_mean*response, bg_sig, np.linspace(bg_mean-bg_sig, bg_mean+bg_sig, res_elements)), interpolation=False)
#     dist = Distribution(gaussian(mp.g_mean, 0.4, np.linspace(0, 1, mp.res_elements)), interpolation=False)
#     plt.plot(gaussian(mp.g_mean, 0.4, np.linspace(0, 1, mp.res_elements)))
#     # plt.plot(gaussian(mp.bg_mean*mp.response, mp.bg_sig, np.linspace(mp.bg_mean-mp.bg_sig, mp.bg_mean+mp.bg_sig, mp.res_elements)))


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

