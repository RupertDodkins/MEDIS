
def do_SDI(datacube, plot=False):
    wsamples = np.linspace(tp.band[0], tp.band[1], tp.nwsamp)
    scale_list = tp.band[0]/wsamples
    print scale_list
    fr_pca1 = np.abs(vip.pca.pca(datacube, angle_list = np.zeros((len(scale_list))), scale_list=scale_list, mask_center_px=None))
    if plot:
        plots(fr_pca1)

    return fr_pca1

def SDI_each_exposure(obs_sequence):
    shape = obs_sequence.shape
    timecube = np.zeros_like(obs_sequence[0])
    for t in range(shape[0])[:1]:
        timecube[t] = do_SDI(obs_sequence[t], plot=True)
    # loop_frames(timecube)
    return timecube