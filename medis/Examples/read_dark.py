import numpy as np
import sys
sys.path.append('D:/dodkins/MEDIS/MEDIS')
# import tables
# from darkObsFile import ObsFile
# import WaveCal
import h5py
# import os, struct
import matplotlib.pyplot as plt
from matplotlib.colors import LogNorm
from Utils.plot_tools import view_datacube, quicklook_wf, quicklook_im, quicklook_IQ, loop_frames
from Utils.misc import dprint
# from parsePacketDump2 import parsePacketData

# h = 4.135668e-15
# c = 2.998e8

folder = 'D:/dodkins/MEDIS/data/processed/180903/calibs/'
fname = folder + '1491907540_dark.h5'
with h5py.File(fname, 'r') as hf:
    darks = []
    for i in range(10):
        image = np.array(hf.get('Images/%i' % (1491907540 + i)))
        darks.append(image)
darks = np.array(darks)

print darks.shape
# loop_frames(darks)
dark = np.median(darks, axis=0)
# quicklook_im(dark)

fname = folder+ '1491886320_flat.h5'
with h5py.File(fname, 'r') as hf:
    flats = []
    for i in range(10):
        image = np.array(hf.get('Images/%i' % (1491886320 + i)))
        flats.append(image)
flats = np.array(flats)

# loop_frames(flats, vmin=0, vmax=40)
# loop_frames(flats - darks)
flat = np.median(flats[4:], axis=0)  - np.median(darks,axis=0)
# quicklook_im(flat, vmin=0, vmax=40)
dprint('flat')
flat[flat<=0] = 1
flat[68:82,31:44] = 1
quicklook_im(flat)
quicklook_im(flat, logAmp=True)

fname = folder+'1491896000.h5'
# ob = ObsFile(fname)
# print ob.photonTable, type(ob.photonTable)
# for row in ob.photonTable:
# 	for phot in row:
# 		print phot[:2]
# 	exit()

with h5py.File(fname, 'r') as hf:
    images = []
    for i in range(195):
        image = np.array(hf.get('Images/%i' % (1491896000 + i)))
        images.append(image)
images = np.array(images)

# images[images>40] = 0
dark_sub = images - dark
# loop_frames(images - dark, vmin=-0, vmax=40)
loop_frames(dark_sub, logAmp=True, vmin=1)
dark_sub[dark_sub>5] = 0
dark_sub[dark_sub<=0] = 1e-1
loop_frames(dark_sub, logAmp=True, vmin=1)
loop_frames(dark_sub/flat, logAmp=True, vmin=1)
quicklook_im(np.mean(dark_sub, axis=0), logAmp=True, vmin=1)
quicklook_im(np.mean(dark_sub/flat, axis=0), logAmp=True, vmin=1)

# loop_frames(dark_sub+1e-9, logAmp=True)

# quicklook_im((np.median(images, axis=0) - dark), vmin=-0, vmax=40)
# quicklook_im((np.median(images, axis=0) - dark) / flat, vmin=0, vmax=40)
# quicklook_im(np.median(images / flat, axis=0), vmin=0, vmax=40)
# quicklook_im(np.mean(images - dark / flat, axis=0), vmin=0, vmax=40)



# def loadStack(dataDir, start, stop, useImg = False, nCols=80, nRows=125):
#     frameTimes = np.arange(start, stop+1)
#     frames = []
#     for iTs,ts in enumerate(frameTimes):
#         print ts
#         try:
#             if useImg==False:
#                 imagePath = os.path.join(dataDir,str(ts)+'.bin')
#                 print imagePath
#                 with open(imagePath,'rb') as dumpFile:
#                     data = dumpFile.read()

#                 nBytes = len(data)
#                 nWords = nBytes/8 #64 bit words

#                 #break into 64 bit words
#                 words = np.array(struct.unpack('>{:d}Q'.format(nWords), data),dtype=object)
#                 parseDict = parsePacketData(words,verbose=False)
#                 image = parseDict['image']

#             else:
#                 imagePath = os.path.join(dataDir,str(ts)+'.img')
#                 print imagePath
#                 image = np.fromfile(open(imagePath, mode='rb'),dtype=np.uint16)
#                 image = np.transpose(np.reshape(image, (nCols, nRows)))

#         except (IOError, ValueError):
#             print "Failed to load ", imagePath
#             image = np.zeros((nRows, nCols),dtype=np.uint16)
#         frames.append(image)
#     stack = np.array(frames)
#     return stack

# stack = loadStack('/Data/DARKNESS/ScienceData/PAL2017a/20170410', 1491896000, 14918960001)
# print stack.shape
# loop_frames(stack, vmax=200, logAmp=False)
# waveCal_fname = '/Data/DARKNESS/CalibrationFiles/PAL2017a/20170410/waveCalSolnFiles/calsol_1491870376.h5'

# with h5py.File(waveCal_fname, 'r') as hf:
# 	calsoln = np.array(hf.get('wavecal/calsoln'))
# 	print calsoln[0]
# 	print calsoln.shape
# 	# calsoln=np.array([[xk[0],xk[1],xk[2][0],xk[2][1],xk[2][2]] for xk in calsoln], ndmin=2)
# 	poly=np.array([[xk[2]] for xk in calsoln], ndmin=2)
# 	resid = np.array([[xk[3]] for xk in calsoln], ndmin=2)
# 	locs = np.array([[xk[0],xk[1]] for xk in calsoln], ndmin=2)
# 	print calsoln.shape, poly.shape, resid.shape, locs.shape
# # poly = calsoln['polyfit'][index]
# # photon_list = self.getPixelPhotonList(row, column)
# # phases = photon_list['Wavelength']
# print np.argsort(resid[:,0])

# poly = poly[np.argsort(resid[:,0])]




# with h5py.File(fname, 'r') as hf:
# 	beammap = np.array(hf.get('BeamMap/Map'))
# 	print beammap
# 	packets = []
# 	# all_photons = np.empty((4,1))
# 	for pix_idx in range(1000):
# 		pixel_data= np.asarray(hf.get('Photons/%i' % pix_idx))
# 		loc = np.where(beammap==pix_idx)
# 		print loc
# 		try:
# 			if len(pixel_data) > 0:
# 				pixel_data=np.array([[coord for coord in xk] for xk in pixel_data], ndmin=2) #this case for N=2
# 				print pixel_data.shape
# 				for photon in pixel_data[::10]:

# 					Time, Phase = photon[:2]

# 					# energy = np.polyval(poly[pix_idx,0], Phase)
# 					# wavelength = h * c / energy * 1e9  # wavelengths in nm
# 					# print Phase, poly[pix_idx], energy, wavelength
# 					# packets.append([wavelength, Time, loc[0], loc[1], pix_idx])
# 					packets.append([Phase, Time, loc[0], loc[1], pix_idx])
# 		except TypeError:
# 			print pixel_data

# 			# poly = poly.flatten()
# 	packets = np.array(packets)

# 			# packets[:,0] = wavelengths
# 			# all_photons = np.vstack(all_photons, packets)
# 			# print all_photons.shape
# 	print packets, packets.shape



