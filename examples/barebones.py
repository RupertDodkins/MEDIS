import medis.Detector.readout as read
from medis.params import iop

iop.update("barebones/")

if __name__ == '__main__':
    simple_hypercube_1 = run_medis(plot=False)
