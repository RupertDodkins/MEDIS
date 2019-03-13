import medis.Detector.readout as read
from medis.params import iop

iop.update("barebones/")

if __name__ == '__main__':
    simple_hypercube_1 = read.get_integ_obs_sequence(plot=False)
