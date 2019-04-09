# Installation
### Setting the Path
After setting up a repo on your computer from GitHub, you should then export the repo to your python path. In your .bashrc (or similar), add something along the lines of:

```
export PYTHONPATH="/home/user/path/to/repo/MEDIS:$PYTHONPATH"
```

### The Conda Environment
As of yet, a (mostly) untested .yaml file of a conda environment can be found medis_env.yml. Information on how to set up a conda environment from a .yml file can be found here: https://docs.conda.io/projects/conda/en/latest/user-guide/tasks/manage-environments.html#creating-an-environment-from-an-environment-yml-file

```
$conda env create -f medis_env.yml
```

This will create an environment called medis (which you could change by editing the first line of the .yml file to be whatever you want). When you are done, activate the environment with

`$conda activate medis`
or 
`$conda activate your_name`

The version here may change as the code continues to be tested. If you notice that a package is missing while testing MEDIS, please contact user:KristinaDavis. Once we are confident the .yml contains all relevant info, we can try to make this a pip editable install, that will be updated through github.

### Setting IDE to Use the Conda Environment
Depending on which IDE you use to run Python, there are different methods to ensure that you use the medis_env when you run the code. If you open python from the command line and run everything in the terminal (or base-python PyPy) this is as simple as running 
`$ conda activate medis`
before running 
`$ python`
However, if you are using a more sophisticated IDE, you may need to link the env to the project settings. For example, in PyCharm, you can create a MEDIS project to contain all the medis code. You then need to go into the project settings, and set Project Interpreter to */path/to/anaconda3/envs/medis/bin/python3.6*. PyCharm then automatically uses the version of numpy, scipy, etc located in the same env folder. 

### Installing Modified PROPER
You will also have to install a modified verision of PROPER. Go to the MEDIS/Proper folder and run

```
python setup.py install --prefix=/path/to/anaconda3/envs/medis/lib/python3.6/site-packages/
````

### Edit VIP
One thing left to do is to make an edit to the current version of vip_hci. Go to the package directory on your computer (on my computer that is */home/captainkay/programs/anaconda3/envs/medis/lib/python3.6/site-packages/vip-hci)*.
in the vip_hci directory, go to *phot/snr.py*
and change the import statement from `get_annulus` to `get_annulus_segments`.


### Setting the Save Directory and the Atmosphere Maps
The default location for the save data will be *$HOME/medis_data/*. If you want the data to be saved to a different location then change the `iop.datadir` variable in *user_params.py*. Any default global parameter can be changed there and it should affect the remote repo

Also if you don't want to generate atmosphere maps yourself, then copy *MEDIS/caos_pse/180828.zip* to your `iop.atmosdata` and unzip

# Documentation
The documentation for `MEDIS` can be found at https://medis.readthedocs.io
