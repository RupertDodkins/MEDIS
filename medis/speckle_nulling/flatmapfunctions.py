import numpy as np
import scipy.io
# import ipdb
import os

#global variables
#actdir = os.path.join(os.getcwd(), 'matlab_code/reflatmapwafflepatterngeneration/')
#
#gaindir = os.path.join(os.getcwd(), 'matlab_code/')
#
#centoff_dir = os.path.join(os.getcwd(), 'matlab_code/cent_off_files/')
##This takes a while to load so make it a global variable
##influence_matrix = np.load(os.path.join(centoff_dir, 'infmat_np'))
#influence_matrix = scipy.io.loadmat(os.path.join(centoff_dir, '20140820_infs_calc.mat'))['infs']

def convert_flatmap_centoffs(x ):
    if x.shape[0] == 66:
        x = convert_hodm_telem(x)
    if x.shape[0] ==4096:
        x = x[0:3388]
    output_centoff= np.dot(influence_matrix,x)
    return np.squeeze(output_centoff)

def make_centoff_file(x, fname = 'test_centoff'):
    outstr = ''.join('  '+str(float(elem)) for elem in x)
    with open(fname, 'w') as f:
        print >> f, outstr
    return

def load_flatmap(fmapfile):
    """loads a flatmap file into an array"""
    return np.genfromtxt(fmapfile)

def load_centoff_file(fname):
    return np.genfromtxt(fname)

def get_gains(gainfile = None):
    """loads the gain file into a numpy array"""
    if gainfile is None:
        gainfile= os.path.join(gaindir, 'hodm_gain.mat')
        target = os.path.join(gaindir, gainfile)
    else:
        target = gainfile
    return scipy.io.loadmat(target)['hodm_gain']

def convert_hodm_telem(data):
    """same as matlab function, converts 66x66 to 3389x1 and vice versa"""
    map2d = np.genfromtxt(os.path.join(actdir, 'act.txt'))
    if np.shape(data)[0] == 66:
        mdata = np.zeros((4096, 1))
        for i in range(1, 3389):
            mdata[i-1] = data[np.where(map2d == i)]
        return mdata
    else:
        mdata = np.zeros((66, 66))
        for i in range(1,3389):
            mdata[np.where(map2d == i)] = data[i-1]
        return mdata

def make_hmap(fname, mapp):
    """write an hmap to file fname"""
    with open(fname, 'w') as f:
        for elem in mapp[0:3388]:
            print >>f, '%f'%float(elem)
    return

def add_waffle(twodflatmap, amp):
    """adds a waffle pattern of amplitude amp to an array"""
    w, h = np.shape(twodflatmap)
    coords = np.ogrid[0:w, 0:h]
    waffle = np.array(( (coords[0]+coords[1])%2 == 1))
    fullwaffle = (1.0-2.0*waffle)*amp
    return twodflatmap + fullwaffle
    
def add_waffle_to_flatmap(newflatmapfile, flatmapfile, amp):
   """adds a waffle pattern of amplitude amp to a 3388x1 flatmap"""
   fm = load_flatmap(flatmapfile)  #fm:3388x1
   h = convert_hodm_telem(fm)      #h:66x66
   ww = add_waffle(h, amp)          #ww:66x66
   mapp = convert_hodm_telem(ww)   #mapp: 4096x1
   make_hmap(newflatmapfile, mapp) #written to 3388x1
   print("new flatmap written to "+str(newflatmapfile))
   return ww



if __name__ == "__main__":
    print("hi")
     
