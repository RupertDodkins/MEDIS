from .temporal import *
import numpy as np
from medis.params import mp, ap
from medis.Utils.misc import dprint
np.set_printoptions(threshold=np.inf)

def planck(T, l):
    from scipy.constants import codata
    import numpy as np
    import matplotlib.pyplot as plt

    D = codata.physical_constants

    h = D['Planck constant'][0]
    k = D['Boltzmann constant'][0]
    c = D['speed of light in vacuum'][0]
    wienConstant = 2.897e-3
    # calculate the Planck Law for a specific temperature and an array of wavelengths
    p = c*h/(k*l*T)
    result = np.zeros(np.shape(l))+1e-99
    # prevent underflow - compute only when p is "not too big"
    calcMe = np.where(p<700)
    result[calcMe] = (h*c*c)/(np.power(l[calcMe], 5.0) * (np.exp(p[calcMe])-1))
    return result


def read_obs_images(location):
    filenames = cubes.read_folder(location)
    wavelengths = []
    for filename in filenames:
        wavelength = filename[-12:-9]
        if wavelength not in wavelengths:
            wavelengths.append(wavelength)
    print(wavelengths)

    input_shape = np.shape(cubes.read_image(filenames[0]))
    frames=np.zeros((len(filenames)/len(wavelengths), len(wavelengths), input_shape[0], input_shape[1]))

    for ifn, filename in enumerate(filenames):
        # cube = cubes.datacube()
        it = ifn%len(wavelengths)
        iw = ifn/len(wavelengths)
        print(it, iw)
        frames[it,iw] = cubes.read_image(filename)

    return frames, wavelengths

def read_single_wavelength(location, wavelength):
    filenames = cubes.read_folder(location)
    use_files = []
    for filename in filenames:
        if wavelength == filename[-12:-9]:
            use_files.append(filename)

    input_shape = np.shape(cubes.read_image(filenames[0]))
    frames=np.zeros((len(use_files), 1, input_shape[0], input_shape[1]))

    for ifn, filename in enumerate(use_files):
        # cube = cubes.datacube()
        frames[ifn] = cubes.read_image(filename)

    return frames, [wavelength]

def change_spec_prof(frames):
    print('adjust relative aplitudes of wavelength frames here')
    # for example a blackbody
    return frames

def phase_cal(wavelengths):
    '''Wavelength in nm'''
    phase = mp.wavecal_coeffs[0]*wavelengths + mp.wavecal_coeffs[1]
    return phase

def wave_cal(phase):
    wave = (phase - mp.wavecal_coeffs[1])/(mp.wavecal_coeffs[0])
    return wave

def wave_idx(wavelength):
    m = float(ap.w_bins-1)/(ap.band[1] - ap.band[0])
    c = -m*ap.band[0]
    idx = wavelength*m + c
    # return np.int_(idx)
    return np.int_(np.round(idx))

def assign_phase(photons, wavelengths):
    wl_list = np.float_(wavelengths)[photons[1]]
    photons[1] = phase_cal(wl_list, wave_coeffs)
    return photons

def calibrate_phase(photons):
    photons = np.array(photons)
    # print photons[0,:5]
    c = ap.band[0]
    m = (ap.band[1] - ap.band[0])/ap.w_bins
    wavelengths = photons[0]*m + c
    # dprint(wavelengths[:5])
    # photons[0] = wavelengths*mp.wavecal_coeffs[0] + mp.wavecal_coeffs[1]
    photons[0] = phase_cal(wavelengths)
    # dprint(photons[0,:5])
    # exit()

    return photons

def eff_filter(cube, start = 0.8, exp=0.1):
    image = np.zeros((xnum,ynum))
    for x in range(xnum):
        for y in range(ynum):
            # print x, y,
            events=[]
            for d in cube[x][y]:
                events.append(d['phase'])
            events = wave_cal(np.array(events), wave_coeffs)
            # print events, start, exp
            # print np.where(events > start)[0], np.where(events > (start + exp))[0]
            # try:
            #     begin = np.where(events > start)[0][0]
            #     end = np.where(events > (start + exp))[0][0]
                # image[x,y] = end-begin
            try:
                image[x,y] = len(np.where(events >start)[0]) - len(np.where(events > (start+exp))[0])

            except IndexError:
                image[x,y] = 0
    print('sum', np.sum(image))
    return image



if __name__ == "__main__":
    frames, wavelengths = read_obs_images(datadir)
    print(np.shape(frames))
    # frames, wavelengths = read_single_wavelength(datadir, '1.2')
    frames = change_spec_prof(frames)
    # frames = uniform_cube()
    
    frames = detector.truncate_array(frames)

    # cubes.frame_look(frames, 0)

    response = detector.array_response()

    # cubes.loop_frames(frames)
    response = detector.create_bad_pix(response)
    response = detector.create_bad_pix_center(response)

    plt.imshow(response, interpolation='none')
    frames = detector.remove_bad(frames, response)  

    Rs = detector.assign_spectral_res()
    
   
    photons = sample_cube(frames, 100000)
    photons = assign_phase(photons, wavelengths)
    photons = assign_time(photons)
    print(photons)

    packets=[]
    for ip, photon in enumerate(photons.T):
        # print ip
        time = photon[0]
        phase = int(photon[1])
        x = int(photon[2])
        y = int(photon[3])
        
        R = Rs[x, y]
        pix_background = detector.get_phase_background(R, 1)
        # print(pix_background, end=' ') 
        pix_response = phase*response[x, y]
        # print(pix_response, end=' ')
        if pix_background + pix_response < threshold_phase:#photon[3]
            print('photon detected')
            packet = cubes.make_packet([x, y], time, phase)
            packets.append(packet)

    cube = cubes.arange_into_cube(packets)

    # cube = remove_close_photons(cube)

    # frames = np.zeros((1, xnum, ynum))
    # for f in range(1):
    #     frames[f] = eff_filter(cube, start = 1.1+f*0.1, exp=0.1)

    # cubes.loop_frames(frames)

    # cubes.plot_pix_time(cube)
    int_map = cubes.make_intensity_map(cube)
    # cubes.make_energy_map(cube)

    cubes.saveFITS(int_map)
    plt.show()
