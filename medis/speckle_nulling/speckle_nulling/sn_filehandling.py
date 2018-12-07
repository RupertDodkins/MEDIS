import glob
# import ipdb
import warnings
import sys
import pyfits as pf
# from astropy.extern import configobj as co
# import configobj as co
import os
import numpy as np
import time
import datetime

class Printer():
    """ 
    Print things to stdout on one line dynamically
    """
    def __init__(self,data):
 
        sys.stdout.write("\r\x1b[K"+data.__str__())
        sys.stdout.flush()

class Timer():
    """
    Time something like a for loop
    only argument is max_iterations
    Ex:
    tt = Timer(100)
    for i in range(100):
        Printer(tt.timeleft())
    """
    def __init__(self, imax):
        self.t0 = time.time()
        self.i  = 0
        self.imax = imax
    def timeleft(self):
        telapsed =time.time()-self.t0
        pctdone = 100.0*(self.i+1)/self.imax
        tleft = (1-pctdone/100)/(pctdone/100/telapsed)
        percentstr= (format(pctdone, '.2f')+
                       "% done.  ") 
        if tleft > 120:
            timestr = str(datetime.timedelta(
                            seconds=int(tleft)))
        else:
            timestr   = (format(tleft, '.1f')+" seconds")
        self.i = self.i+1
        return ("  "+percentstr+timestr + " remaining")

    def timeelapsed(self):
        timestr = "  "+(format(time.time-self.t0, '.1f'))+" time  elapsed"
        return timestr

def parsenums(linestring):
    """converts strings like '1-10; 15-17' into a list of ph0001.fits, ph0002.fits, etc"""
    ans = []
    first=linestring.split(';')
    for thing in first:
        ans= ans + (list(range(
                    int(thing.split('-')[0]), 
                    int(thing.split('-')[1])+1)))

    return ['ph'+str(x).zfill(4)+'.fits' for x in ans] 

def int_if_possible(value):
    try: return int(value)
    except: return value

def float_if_possible(value):
    try: return float(value)
    except: return value

def intdict(dicty):
    """Converts values in dictionary to integers"""
    return dict((k, int_if_possible(v)) for (k, v) in list(dicty.items()))

def floatdict(dicty):
    """Converts values in dictionary to floats"""
    return dict((k, float_if_possible(v)) for (k, v) in list(dicty.items()))

def check_exptime(filelist, t=1416):
    outputlist = []
    for fitsfile in filelist:
        hdulist= pf.open(fitsfile)
        header = hdulist[0].header
        #replace this with a global check of all parameters
        if header['T_INT'] != t:
            print(("\nWarning: "+fitsfile+ 
               " has different exposure time of "+
               str(header['T_INT'])+
               " instead of "+str(t)+
               ", skipping it"))
        else:
            outputlist.append(fitsfile)
        hdulist.close()
    return outputlist

def check_equal(iterator):
    #checks if everything in list, etc is equal
    return len(set(iterator)) <= 1

def sameheadervals(db):
    """returns a list of header keys which
    all have the same values in the db"""
    keys = list(db.keys())
    passedkeys=[]
    for x in keys:
        if validate(db,x):
           passedkeys.append(x) 
    return passedkeys

def diffheadervals(db):
    """returns a list of header keys which
    have the different values in the db"""
    keys = list(db.keys())
    passedkeys=[]
    for x in keys:
        if not validate(db,x):
           passedkeys.append(x) 
    return passedkeys

def stripheader(header, keys):
    headercopy = header.copy()
    for key in keys:
        headercopy[key]=-99999
    return headercopy

def setup_bgd_dict(config):
    """creates a dictionary of 'bkgd', 'masterflat', 'badpix' with the correct images as the values.  this makes for easy 'dereferencing' when using equalize_image(image, **bgd)"""
    bgddir = config['BACKGROUNDS_CAL']['dir']
    bgds = {
    'bkgd': pf.open(os.path.join(bgddir, 'medbackground.fits'))[0].data,
    'masterflat': pf.open(os.path.join(bgddir, 'masterflat.fits'))[0].data,
    'badpix': pf.open(os.path.join(bgddir, 'badpix.fits'))[0].data}
    return bgds

def validate(databasesubset, fieldstocheck=None):
    """>>>validate(db[db['Type']=='flats'], ['FILTER','T_INT'])
    checks to see if all files of type flats in the db have the
    same t_int and filter"""
    if not isinstance(fieldstocheck,list):
        fieldstocheck=[fieldstocheck]
    passed = True
    for field in fieldstocheck:
        if check_equal(databasesubset[field]):
            pass
        else:
            passed = False
            print("WARNING. NOT ALL "+field+" THE SAME")
            #print databasesubset[field]
    return passed

def ds9(data):
    writeout(data, 'temp.fits')
    os.system('/Applications/ds9/ds9 temp.fits &')
    pass

def get_paths_dir(directory, numstr):
    filelist = parsenums(numstr)
    returndict=[os.path.join(directory, x) for x in filelist]
    return returndict

def formattoarray(string):
    t1 = string.replace('[', '').replace(']', '').split(' ')
    l1=[]
    for x in t1:
        try:
            l1.append(float(x))
        except:
            pass
    return np.array(l1)
            

def formatnum(string):
    temp="".join([x if x in ['1','2','3','4','5','6','7','8','9','0','.', '-'] else '' for x in string])
    return temp 

def dictfromfile(filename, **kwargs):
    """Usage: dict = dictfromfile("myfile.txt", delim=" ")"""
    lines= np.genfromtxt(filename, **kwargs)
    dicty = {}
    for i in range(len(lines[0,:])):
        try:
            dicty[str(lines[0,i]).strip(" ")]=np.array(
                lines[1:, i], dtype=float)
        except:
            dicty[str(lines[0,i]).strip(" ")]=np.array(
                lines[1:, i], dtype=str)
    return dicty

def get_paths_conf(configobj, directory = None):
    returndict={}
    """returns a dict of {'targ':[/users/me/ph0001.fits,...], 'cal':[/users/me/ph0003.fits"""
    for item in list(configobj['Dirs']['Input'].keys()):
        try:
            filelist = parsenums(configobj['Dirs']['InputFileNums'][item])
            if directory is not None:
                returndict[item]=[os.path.join(
                   directory,  x) for x in filelist]
            else:
                returndict[item]=[os.path.join(
                    configobj['Dirs']['Input'][item], x) for x in filelist]
        except:
            print("Warning! "+item+" SKIPPED")
    return returndict

def write2columnfile(A, B, 
                    filename = 'twocols.txt', 
                    header = None):
    with open(filename,  'w') as f:
        if header is not None:
            print(header, file=f)
        for f1, f2 in zip(A, B):
            print(f1, f2, file=f)
    pass
     
def writeout(data, outputfile, header=None, comment=None):
    pf.writeto(outputfile, data, header=header, clobber=True)
    # writtenfile = pf.open(outputfile)
    # print outputfile, comment
    # # if comment is not None:
    # #     writtenfile[0].header.set('COMMENT', comment)
    # # with warnings.catch_warnings():
    # #     warnings.simplefilter('ignore')
    # writtenfile.writeto(outputfile, output_verify='ignore', clobber=True)
    # writtenfile.close()

def find_all_fits(rootdir):
    files=[] 
    for dirpath,_,filenames in os.walk(rootdir):
        for f in filenames:
            if f.endswith('.fits'):
                files.append(os.path.abspath(os.path.join(dirpath, f)))
    return files

def get_latest_file(filetype = None, directory = None):
    searchstring = os.path.join(directory, '*'+filetype)
    return max(glob.iglob(searchstring), key=os.path.getctime)

def get_latest_fitsfile(directory):
    return get_latest_file(directory =directory, filetype='fits')
