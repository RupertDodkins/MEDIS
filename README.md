You should then export the repo to your python path. In your .bashrc (or similar), add something along the lines of:

export PYTHONPATH="/home/user/path/to/repo/MEDIS:$PYTHONPATH"

As of yet, an untested .yaml file of a conda environment can be found medis_env.yml. Information on how to set up a conda environment from a .yml file can be found here.

$conda env create -f medis_env.yml

This will create an environment called medis (which you could change by editing the first line of the .yml file to be whatever you want). When you are done, activate the environment with

$conda activate medis.

The version here may change as the code continues to be tested. If you notice that a package is missing while testing MEDIS, please contact user:KristinaDavis. Once we are confident the .yml contains all relevant info, we can try to make this a pip editable install, that will be updated through github.

One thing left to do is to make an edit to the current version of vip_hci. Go to the package directory on your computer (on my computer that is /home/captainkay/programs/anaconda3/envs/medis/lib/python3.6/site-packages/vip-hci).

in the vip_hci directory, go to phot/snr.py

and change the import statement from get_annulus to get_annulus_segments.
