'''
reads, formats, and saves data products, including obs_sequence

This module is really two different modules, smushed together.
The first part of the module has something to do with a readout system.
  It has the relevant code to convert from a obs_sequence to a  photon list, for the case of MKIDs
The second half of the module has little/nothing to do with a readout system
  This deals with reading, opening, and saving obs_sequences, either hdf5 or ?? format


'''
import os
import numpy as np
from copy import copy
import tables as pt
import h5py
import pickle as pickle
from medis.params import ap, cp, tp, mp, hp, sp, iop, dp, fp
from . import mkid_artefacts as MKIDs
import proper
from medis.Utils.plot_tools import view_datacube, loop_frames, quicklook_im
from . import temporal as temp
from . import spectral as spec
from . import pipeline as pipe
# import matplotlib.pyplot as plt
from . import H2RG

from medis.Utils.misc import dprint
from medis.Utils.rawImageIO import clipped_zoom
from scipy import interpolate
from scipy.interpolate import RegularGridInterpolator as rgi
from scipy.interpolate import interpn


####################################################################################################
## Modules Relating to Formatting Data in Photon Lists ##
####################################################################################################

def get_packets(datacube, step, dp, mp, plot=False):
    # view_datacube(datacube, logAmp=True)

    if mp.resamp:
        nyq_sampling = ap.band[0]*1e-9*360*3600/(4*np.pi*tp.diam)
        sampling = nyq_sampling*tp.beam_ratio*2  # nyq sampling happens at tp.beam_ratio = 0.5
        x = np.arange(-ap.grid_size*sampling/2, ap.grid_size*sampling/2, sampling)
        xnew = np.arange(-dp.array_size[0]*dp.platescale/2, dp.array_size[0]*dp.platescale/2, dp.platescale)
        mkid_cube = np.zeros((len(datacube), dp.array_size[0], dp.array_size[1]))
        for s, slice in enumerate(datacube):
            f = interpolate.interp2d(x, x, slice, kind='cubic')
            mkid_cube[s] = f(xnew, xnew)
        mkid_cube = mkid_cube*np.sum(datacube)/np.sum(mkid_cube)
        # view_datacube(mkid_cube, logAmp=True, show=False)
        datacube = mkid_cube

    datacube[datacube < 0] *= -1
    # if (dp.array_size != datacube[0].shape + np.array([1,1])).all():
    #     left = int(np.floor(float(ap.grid_size-mp.array_size[0])/2))
    #     right = int(np.ceil(float(ap.grid_size-mp.array_size[0])/2))
    #     top = int(np.floor(float(ap.grid_size-mp.array_size[1])/2))
    #     bottom = int(np.ceil(float(ap.grid_size-mp.array_size[1])/2))
    #
    #     dith_duration = np.floor(ap.numframes/len(tp.pix_shift))
    #     dith_idx = np.floor(step/dith_duration).astype(np.int32)
    #
    #     dprint(f"left={left},right={right},top={top},bottom={bottom}")
    #     datacube = datacube[:, tp.pix_shift[dith_idx][0]+bottom:tp.pix_shift[dith_idx][0]-top,
    #                tp.pix_shift[dith_idx][1]+left:tp.pix_shift[dith_idx][1]-right]

    if mp.QE_var:
        datacube *= dp.QE_map[:datacube.shape[1],:datacube.shape[1]]
    # if mp.hot_pix:
    #     datacube = MKIDs.add_hot_pix(datacube, dp, step)

    # quicklook_im(dp.QE_map)
    if plot: view_datacube(datacube, logAmp=True, show=False)
    num_events = int(ap.star_photons_per_s * ap.sample_time * np.sum(datacube))

    # dprint((np.sum(datacube), num_events))
    # import matplotlib.pylab as plt
    # plt.figure()
    # plt.plot(np.sum(datacube, axis=(1,2)))
    # plt.show(block=True)
    photons = temp.sample_cube(datacube, num_events)

    photons = spec.calibrate_phase(photons)

    photons = temp.assign_calibtime(photons, step)
    # dprint(photons[:,5])

    if plot:
        cube = pipe.make_datacube_from_list(photons.T, (ap.w_bins, dp.array_size[0], dp.array_size[1]))
        dprint(cube.shape)
        view_datacube(cube, logAmp=True)

    if mp.dark_counts:
        dark_photons = MKIDs.get_dark_packets(dp, step)
        # cube = pipe.make_datacube_from_list(dark_photons.T, (ap.w_bins, dp.array_size[0], dp.array_size[1]))
        # view_datacube(cube, logAmp=False)
        # plt.hist(dark_photons[3], bins=25)
        # plt.yscale('log')
        # plt.show(block=True)
        photons = np.hstack((photons, dark_photons))
        # photons = MKIDs.add_dark(photons)

    if mp.hot_pix:
        hot_photons = MKIDs.get_hot_packets(dp, step)
        photons = np.hstack((photons, hot_photons))
        # stem = MKIDs.add_hot(stem)

    # plt.hist(photons[3], bins=25)
    # plt.yscale('log')
    # plt.show(block=True)
    # stem = pipe.arange_into_stem(photons.T, (dp.array_size[0], dp.array_size[1]))
    # cube = pipe.make_datacube(stem, (dp.array_size[0], dp.array_size[1], ap.w_bins))
    # view_datacube(cube, logAmp=True, vmin=0.01)

    if mp.phase_uncertainty:
        photons = MKIDs.apply_phase_offset_array(photons, dp.sigs)
        # stem = pipe.arange_into_stem(photons.T, (dp.array_size[0], dp.array_size[1]))
        # cube = pipe.make_datacube(stem, (dp.array_size[0], dp.array_size[1], ap.w_bins))
        # view_datacube(cube, logAmp=True, vmin=0.01)
        photons[1] *= dp.responsivity_error_map[np.int_(photons[2]), np.int_(photons[3])]

    # stem = pipe.arange_into_stem(photons.T, (dp.array_size[0], dp.array_size[1]))
    # cube = pipe.make_datacube(stem, (dp.array_size[0], dp.array_size[1], ap.w_bins))
    # view_datacube(cube, vmin=0.01, logAmp=True)
    # plt.figure()
    # plt.imshow(cube[0], origin='lower', norm=LogNorm(), cmap='inferno', vmin=1)
    # plt.show(block=True)

    thresh =  photons[1] < dp.basesDeg[np.int_(photons[3]),np.int_(photons[2])]
    photons = photons[:, thresh]
    # print(thresh)

    # stem = pipe.arange_into_stem(photons.T, (mp.array_size[0], mp.array_size[1]))
    # cube = pipe.make_datacube(stem, (mp.array_size[0], mp.array_size[1], ap.w_bins))
    # quicklook_im(cube[0], vmin=1, logAmp=True)
    # plt.figure()
    # plt.imshow(cube[0], origin='lower', norm=LogNorm(), cmap='inferno', vmin=1)
    # plt.show(block=True)

    # dprint(photons.shape)

    # This step was taking a long time
    # stem = pipe.arange_into_stem(photons.T, (mp.array_size[0], mp.array_size[1]))
    # cube = pipe.make_datacube(stem, (mp.array_size[0], mp.array_size[1], ap.w_bins))
    # # ax7.imshow(cube[0], origin='lower', norm=LogNorm(), cmap='inferno', vmin=1)
    # cube /= dp.QE_map
    # photons = pipe.ungroup(stem)

    # dprint(photons.shape)


    # dprint("Measured photons with MKIDs")

    return photons.T


def get_packets_old(datacube, step, dp,mp):
# def get_packets(fields, step, dp,mp):
    # print 'Detecting photons with an MKID array'
    # print(fields.shape)

    # packets = np.empty(5)
    # for o in range(len(ap.contrast) + 1):
    # datacube = np.abs(fields[-1, o, :])**2
    # moves = np.shape(tp.pix_shift)[0]

    # iteration = step % moves
    print(datacube.shape)
    if (mp.array_size != datacube[0].shape + np.array([1,1])).all():
        left = int(np.floor(float(ap.grid_size-mp.array_size[0])/2))
        right = int(np.ceil(float(ap.grid_size-mp.array_size[0])/2))
        top = int(np.floor(float(ap.grid_size-mp.array_size[1])/2))
        bottom = int(np.ceil(float(ap.grid_size-mp.array_size[1])/2))

        dprint(f"left={left},right={right},top={top},bottom={bottom}")
        datacube = datacube[:, bottom:-top, left:-right]

    if mp.QE_var:
        datacube *= dp.QE_map[:datacube.shape[1],:datacube.shape[1]]
    # if mp.hot_pix:
    #     datacube = MKIDs.add_hot_pix(datacube, dp, step)

    num_events = int(ap.star_photons_per_s * ap.sample_time * np.sum(datacube))
    dprint(f"# events ={num_events}, star photons = {ap.star_photons_per_s}, "
           f"sum(datacube) = {np.sum(datacube),}, Exposure Time ={ap.sample_time}")
    if num_events * sp.num_processes > 1.0e9:
        dprint(num_events)
        dprint('Possibly too many photons for memory. Are you sure you want to do this? Remove exit() if so')
        exit()

    # if datacube.shape[2] != mp.array_size[0]-1:
    #     import scipy
    #     # datacube  = scipy.interpolate.interpn((np.arange(datacube.shape[0]),
    #     #                                        np.arange(datacube.shape[1]),
    #     #                                        np.arange(datacube.shape[2])), datacube, (np.arange(datacube.shape[0]),
    #     #                                                                                  np.arange(mp.array_size),
    #     #                                                                                  np.arange(mp.array_size)))
    #     # loop_frames(datacube)
    #     datacube = scipy.ndimage.zoom(datacube, (1, (mp.array_size[0]-1)/datacube.shape[2], (mp.array_size[0]-1)/datacube.shape[2]))

    photons = temp.sample_cube(datacube, num_events)

    photons = spec.calibrate_phase(photons)

    if mp.hot_pix:
        hot_photons = MKIDs.get_hot_packets(dp)
        photons = np.hstack((photons, hot_photons))

    photons = temp.assign_calibtime(photons, step)

    if mp.phase_uncertainty:
        photons = MKIDs.apply_phase_offset_array(photons, dp.sigs)
    thresh = dp.basesDeg[np.int_(photons[3]),np.int_(photons[2])] < -1 * photons[1]
    photons = photons[:, thresh]

    # todo implement flatcal and wavecal here
    # photons = assign_id(photons, obj_ind=o)

    # print(photons.shape)
    # packets = np.vstack((packets, np.transpose(photons)))
    packets = np.transpose(photons)

    # dprint("Completed Readout Loop")

    return packets  #[1:]  #first element from empty would otherwise be included

def assign_id(photons, obj_ind):
    return np.vstack((photons, np.ones_like(photons[0])*obj_ind))

def get_obs_command(packets, t, o):
    """
    For reatime saving of photon data together with handle_output

    :param packets:
    :param t:
    :param o:
    :return:
    """
    command = ('create_array', ('/t%i' % t, 'o%i' % o, packets))
    return command

def handle_output(output, filename):
    """
    For reatime saving of photon data together with get_obs_command

    :param output:
    :param filename:
    :return:
    """
    with pt.open_file(filename, mode='a') as hdf:
        while True:
            args = output.get()
            if args:
                method, args = args
                getattr(hdf, method)(*args)
            else:
                break

def write_obs(packets):
    '''Saving the packets in a pseudo h5 obsfile'''
    packets = np.array(packets)
    print(f"Shape of Packets is {np.shape(packets)}")

    pixIds = np.int_(packets[:,3]) * mp.xnum + np.int_(packets[:,4])
    packets = {'basesDeg':packets[:,0], 'phases':packets[:,1], 'timestamps':packets[:,2], 'pixIds':pixIds}#, 'image':image, 'xCoords':packets[:,3], 'yCoords':packets[:,4]}

    if not os.path.exists(iop.obs_table):
        h5file = h5py.File(iop.obs_table, 'w')
        d = h5file.create_dataset('photons', (len(packets),5), maxshape=(None,5), dtype='f', chunks=True)
        d[:] = packets
        h5file.flush()
        h5file.close()
    else:
        with h5py.File(iop.obs_table, 'a') as hf:
            hf["photons"].resize((hf["photons"].shape[0] + len(packets)), axis = 0)
            hf["photons"][-len(packets):] = packets


def convert_to_wfo(image, wfo):
    wf_temp = copy(wfo)
    wf_temp.wfarr = proper.prop_shift_center(image +0j)

    return wf_temp


####################################################################################################
## Functions Relating to Reading, Loading, and Saving Data ##
####################################################################################################


def save_obs_sequence(obs_sequence, obs_seq_file='hyper.pkl'):
    dprint((obs_seq_file, obs_seq_file[-3:], obs_seq_file[-3:] == '.h5'))
    if obs_seq_file[-3:] == 'pkl':
        with open(obs_seq_file, 'wb') as handle:
            pickle.dump(obs_sequence, handle, protocol=pickle.HIGHEST_PROTOCOL)
    elif obs_seq_file[-3:] == 'hdf' or obs_seq_file[-3:] == '.h5':
        f = pt.open_file(obs_seq_file, 'w')
        # atom = pt.Atom.from_dtype(hypercube.dtype)
        # ds = f.createCArray(f.root, 'data', atom, hypercube.shape)
        ds = f.create_array(f.root, 'data', obs_sequence)
        # ds[:] = hypercube
        f.close()
    else:
        print('Extension not recognised')


def save_fields(e_fields_sequence, fields_file='hyper.pkl'):

    dprint((fields_file, fields_file[-3:], fields_file[-3:] == '.h5'))
    if fields_file[-3:] == 'pkl':
        with open(fields_file, 'wb') as handle:
            pickle.dump(e_fields_sequence, handle, protocol=pickle.HIGHEST_PROTOCOL)
    elif fields_file[-3:] == 'hdf' or fields_file[-3:] == '.h5':
        with h5py.File(fields_file, 'w') as hf:
            hf.create_dataset('data', data=e_fields_sequence)
            # for param in [iop, cp, tp, mp, sp, iop, dp, fp]:
            #     for key, value in dict(param).items():
            #         if type(value) == str or value is None:
            #             value = np.string_(value)
            #         try:
            #             hf.attrs.create(f'{param.__name__()}.{key}', value)
            #         except TypeError:
            #             print('WARNING skipping some attributes - probably the aber dictionaries or save locs')
    else:
        print('Extension not recognised')


def save_rt(filename, e_fields_sequence):
    with open(filename, 'wb') as handle:
        # field_tup = (obs_sequence, e_fields_sequence)
        pickle.dump(e_fields_sequence, handle, protocol=pickle.HIGHEST_PROTOCOL)
    dprint('saved')


def check_exists_fields(plot=False):
    """
    This code checks to see if there is already
    an observation sequence saved with the output of the run in the
    location specified by the iop. If none exists, it passes all
    the parameters to get_photon_data.

    :return: the obs_sequence (timeseries of data cubes)
        data is saved in location specified in iop
        data can be saved as obs_table (photon table) if detector type is MKIDs
    """
    import os
    if os.path.isfile(iop.fields):
        print(f"File already exists at {iop.fields}")
        return True
    else:
        return False

def open_obs_sequence(obs_seq_file = 'hyper.pkl'):
    with open(obs_seq_file, 'rb') as handle:
        obs_sequence =pickle.load(handle)

    return obs_sequence

def open_rt_save(savename, t):
    with open(savename, 'rb') as handle:
        field_tup = pickle.load(handle)
    return field_tup

def open_obs_sequence_hdf5(obs_seq_file = 'hyper.h5'):
    # hdf5_path = "my_data.hdf5"
    read_hdf5_file = pt.open_file(obs_seq_file, mode='r')
    # Here we slice [:] all the data back into memory, then operate on it
    obs_sequence = read_hdf5_file.root.data[:]
    # hdf5_clusters = read_hdf5_file.root.clusters[:]
    read_hdf5_file.close()
    return obs_sequence

# def open_pseudo_obs():
#     with pt.open_file(iop.obs_table, mode='r') as f:

def open_fields(fields_file):
    with h5py.File(fields_file, 'r') as hf:
        data = hf['data'][:]
    return data

def take_exposure(obs_sequence):
    factor = ap.exposure_time/ ap.sample_time
    num_exp = int(len(obs_sequence)/factor)
    downsample_cube = np.zeros((num_exp,obs_sequence.shape[1],obs_sequence.shape[2], obs_sequence.shape[3]))
    for i in range(num_exp):
        # print np.shape(downsample_cube[i]), np.shape(obs_sequence), np.shape(np.sum(obs_sequence[i * factor : (i + 1) * factor], axis=0))
        downsample_cube[i] = np.sum(obs_sequence[int(i*factor):int((i+1)*factor)],axis=0)#/float(factor)
    return downsample_cube

def take_fields_exposure(fields):
    factor = ap.exposure_time/ ap.sample_time
    dprint(factor)
    num_exp = int(len(fields)/factor)
    downsample_fields = np.zeros((num_exp,fields.shape[1],fields.shape[2],fields.shape[3],fields.shape[4],fields.shape[5]))
    for i in range(num_exp):
        # print np.shape(downsample_cube[i]), np.shape(obs_sequence), np.shape(np.sum(obs_sequence[i * factor : (i + 1) * factor], axis=0))
        downsample_fields[i] = np.sum(fields[int(i*factor):int((i+1)*factor)],axis=0)#/float(factor)
    return downsample_fields

def med_collapse(obs_sequence):
    downsample_cube = np.median(obs_sequence,axis=0)
    return downsample_cube



