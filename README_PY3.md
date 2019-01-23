The speckle nulling package has been slightly adapted from code courtesy of Michael Bottom for Palomar and Keck

framework python install
conda = "~/minconda3/bin/conda"

<go in PyCharm Preferences and set Python to miniconda3/bin/python>
<do the rest of the commands in that terminal>

conda install python.app

conda install numpy

conda install -c conda-forge matplotlib

pip install Cython

% pip install PyFITS # This should be redundant now

Fortran Compiler gFortran and Xcode follow instruction

pip install astropy

pip install h5py

pip install PyYAML

% <cd to downloaded and unzipped proper directory> python setup.py install
pip install /path/to/proper3.6.tar.gz # pip install https://sourceforge.net/projects/proper-library/files/proper_v3.0d1_python_3.x_30jul18.tar.gz

conda install pytables

have multiprocessing.set_start_method('spawn') in part of the code

pip install configobj

pip install PyQt5

% in matplotlibrc: backend: Qt5Agg # This has been added to __init__

pip install vip_hci (may have to change get_annulus to get_annulus_segments in snr.py)

pip install --upgrade --no-deps statsmodels