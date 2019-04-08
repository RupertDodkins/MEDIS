"""
MEDIS run using the Subaru optics system

This code uses Subaru_optics.py instead of the basic optics_propagate.py.
This is currently specified in get_photon_data but future changes to the code will allow better user specification
of different Proper perscriptions.


This script is meant to override any Subaru/SCExAO-specific parameters specified in the user's params.py
"""

import os
from medis.params import ap, tp, iop
import medis.Detector.get_photon_data as gpd
import medis.Telescope.aberrations as aber

# Defining Subaru parameters

# Optics + Detector
# tp.d_primary = 8.2  # m
# tp.fn_primary = 1.83  # f# primary
# tp.fl_primary = 15 # m  focal length
# tp.dist_prim_second = 12.652  # m distance primary to secondary
# #---------------------------
# # According to Iye-et.al.2004-Optical_Performance_of_Subaru:AstronSocJapan, the AO188 uses the IR-Cass secondary,
# # but then feeds it to the IR Nasmyth f/13.6 focusing arrangement.
# tp.fn_secondary = 12.6  # f# secondary
# tp.fl_secondary = tp.fn_secondary * tp.d_secondary  # m  focal length
# tp.dist_second_nsmyth =   # m distance secondary to nasmyth focus
#----------------------------
# According to Iye-et.al.2004-Optical_Performance_of_Subaru:AstronSocJapan, the AO188 uses the IR-Cass secondary,
# but then feeds it to the IR Nasmyth f/13.6 focusing arrangement. So instead of simulating the full Subaru system,
# we can use the effective focal length at the Nasmyth focus, and simulate it as a single lens.
tp.d_nsmyth = 7.971  # m pupil diameter
tp.fn_nsmyth = 13.612  # f# Nasmyth focus
tp.fl_nsmyth = 108.512  # m focal length
tp.dist_nsmyth_ao1 = 0.015  # m distance nasmyth focus to AO188

tp.d_secondary = 1.265  # m diameter secondary, used for central obscuration

#----------------------------
# AO188 OAP1
tp.d_ao1 = 0.090  # m  diamater of AO1
tp.fn_ao1 = 6  # f# AO1
tp.fl_ao1 = 0.015  # m  focal length AO1
tp.dist_ao1_dm = 0.05  # m distance AO1 to DM (just a guess here, shouldn't matter for the collimated beam)

#----------------------------
# AO188 OAP2
tp.dist_dm_ao2 = 0.05  # m distance DM to AO2 (again, guess here)
tp.d_ao2 = 0.090  # m  diamater of AO2
tp.fn_ao2 = 13.6  # f# AO2
tp.fl_ao2 = 151.11  # m  focal length AO2


tp.obscure = True
tp.use_ao = True
tp.ao188_act = 188
tp.use_atmos = True
tp.use_zern_ab = True
tp.occulter_type = 'Vortex'  # 'None'

# Aberrations
tp.aber_params = {'CPA': True,
                    'NCPA': True,
                    'QuasiStatic': False,  # or 'Static'
                    'Phase': True,
                    'Amp': False,
                    'n_surfs': 1,
                    'OOPP': [1]}  # fraction of a focal length where mirror(s) is located

# astro_params
ap.numframes = 3

if __name__ == '__main__':
    # Rename Data Directory
    iop.aberdata = 'Subaru'
    iop.update("Subaru_example/")
    if os.path.exists(iop.int_maps):
        os.remove(iop.int_maps)

    # aber.generate_maps(tp.d_nsmyth, 'CPA', 'nasmyth')
    # aber.generate_maps(tp.d_ao1, 'CPA', 'AO188-OAP1')
    # aber.generate_maps(tp.d_ao2, 'NCPA', 'AO188-OAP2')

    tp.detector = 'ideal'

    # Starting the Simulation
    print("Starting Subaru Telescope ideal-detector example")
    ideal = gpd.run_medis()[0, :]
    print("finished Subaru Telescope run")
