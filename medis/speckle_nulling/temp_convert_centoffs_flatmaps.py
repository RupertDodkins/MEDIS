import medis.speckle_nulling.dm_functions as DM
import os
import ipdb
import scipy.io
import flatmapfunctions as fmf
import matplotlib.pyplot as plt
import numpy as np

def convert_flatmap_centoff(x ):
    output_centoff= np.dot(influence_matrix,x)
    return output_centoff

def make_centoff_file(x, fname = 'test_centoff'):
    outstr = ''.join('  '+str(elem) for elem in x)
    with open(fname, 'w') as f:
        print >> f, outstr
    return

def load_centoff_file(fname):
    return np.genfromtxt(fname)

if __name__ == "__main__":
    centoff_dir = '/data1/home/aousr/Desktop/speckle_nulling/matlab_code/cent_off_files'
    input_flatmapfile= os.path.join(centoff_dir, 'hodm_sn_test')
    targ_outputfile = os.path.join(centoff_dir, 'co_p1640cal')
    influence_matrixfile = os.path.join(centoff_dir, 'infmat_np')
    
    input_flatmap = (fmf.load_flatmap(input_flatmapfile))
    target_output = np.genfromtxt(targ_outputfile)
    #influence_matrix = scipy.io.loadmat(influence_matrixfile)['infs']
    influence_matrix = np.load(influence_matrixfile)
    tt = make_centoff_file(target_output)
    test_out = np.genfromtxt('test_centoff')
