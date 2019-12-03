import medis.save_photon_data as gpd

from medis.params import iop

iop.update("barebones/")

if __name__ == '__main__':
    simple_hypercube_1 = gpd.run_medis()

