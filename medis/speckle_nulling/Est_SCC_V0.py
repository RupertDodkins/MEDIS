# -*- coding: utf-8 -*-
"""
Created on Mon May  4 21:05:31 2015

@author: J-R
"""

import numpy as np
import ipdb
import scipy.ndimage.interpolation as shiftsub

# permet de faire des plots
import matplotlib.pyplot as plt

from configobj import ConfigObj
from validate import Validator

def subshift(image,shift_x,shift_y):
    """Returns a shifted image"""
    return shiftsub.shift(image,[shift_y,shift_x], output=None, order=1, mode='constant', cval=0.0, prefilter=True)    

def shift(image,shift_x,shift_y):
    """Returns a shifted image"""
    return np.roll(np.roll(image,int(shift_y),axis=0),int(shift_x),axis=1)



def Est_SCC_V0(Im_SCC_tmp,Filtre_I,directory,cx = None, cy=None):
    

    # complex
    compl = 0+1j    
    
    #config file 
    configfilename = 'SCC_config.ini'
    configspecfile = 'SCC_config.spec'
    
    #read the Config file
    config = ConfigObj(configfilename, configspec=configspecfile)
    val = Validator()
    #checks to make sure all the values are correctly typed in
    check = config.validate(val)

    #load the value of the Threshold
    Thresholdmin = config['Estimator']['Thresholdmin']
    Thresholdmax = config['Estimator']['Thresholdmax']    
    
    # dimensions des images réduites
    dim_s    = 300  
 
    # We define a filter for the images in detector plane
    #Im_Filter = pf.open(directory + 'DH_butterworth.fits')[0].data
    
    # Si pas de cx ou cy en keyword on les télécharge
    #shift_val = pf.open(directory + 'Position_beam_subpixel.fits')[0].data
    # position du centre de la psf sur le detecteur en x
    #if cx == None:
    #    cx       = shift_val[0]
    # position du centre de la psf sur le detecteur en y    
    #if cy == None:
    #    cy       = shift_val[1]

    # position du pic lateral n°1 dans le plan de fourier dans la direction x
    xi0_x1   = 64.4 #49
    # position du pic lateral n°1 dans le plan de fourier dans la direction y    
    xi0_y1   = 40.65 #51
    # Diamètre du pic lateral n°1 dans le plan de fourier
    ray_c1   = 20. #23

    # position du pic lateral n°2 dans le plan de fourier dans la direction x
    xi0_x2   = 261.1 #49 
    # position du pic lateral n°2 dans le plan de fourier dans la direction y    
    xi0_y2   = 59.5# 250
    # Diamètre du pic lateral n°2 dans le plan de fourier
    ray_c2   = 20# 23


    dim_fourier = 8*ray_c1
    dim_dh_x    = 128
    dim_dh_y    = 128

    if np.shape(Filtre_I) == ():
        Filtre_I = np.ones((dim_dh_x,dim_dh_y))

    # We define a central circle of radius of "ray_c1" centered on (xi0_x1,xi0_y1)
    x, y = np.meshgrid(np.arange(dim_s)-xi0_x1, np.arange(dim_s)-xi0_y1)
    r = np.sqrt(x**2.+y**2.)
    Filtre_Fourier_ref1 = np.zeros((dim_s,dim_s))
    Filtre_Fourier_ref1[np.where(r < ray_c1)] = 1.
    FFR1 = Filtre_Fourier_ref1

    # We define a central circle of radius of "ray_c2" centered on (xi0_x2,xi0_y2)    
    x, y = np.meshgrid(np.arange(dim_s)-xi0_x2, np.arange(dim_s)-xi0_y2)
    r = np.sqrt(x**2.+y**2.)
    Filtre_Fourier_ref2 = np.zeros((dim_s,dim_s))
    Filtre_Fourier_ref2[np.where(r < ray_c2)] = 1.    
    FFR2 = Filtre_Fourier_ref2        

    # on centre l'image en cx, cy et on la coupe en une image dim_s*dim_s
    #Im_SCC_tmp = shift(Im_SCC_tmp[cx-dim_s/2:cx+dim_s/2,cy-dim_s/2:cy+dim_s/2],-dim_s/2,-dim_s/2)    
    #ipdb.set_trace()
    # On recentre l'image pour la découpe

    Im_SCC_tmp = subshift(Im_SCC_tmp,dim_s/2-cx,dim_s/2-cy)
        #A = subshift(Im_SCC_tmp,dim_s/2-cx,dim_s/2-cy)     
        #plt.imshow(A**0.1)
        
    # On coupe l'image
    Im_SCC_tmp = Im_SCC_tmp[0:dim_s,0:dim_s]
        #B = A[0:dim_s,0:dim_s]
        #plt.imshow(B**0.1)
    
    # On multiplie l'image par le filtre image
    #Im_SCC_tmp *= Im_Filter
        #C = B * Im_Filter
        #plt.imshow(C**0.1)   
    
    # on recentre l'image en 0,0
    Im_SCC_tmp = shift(Im_SCC_tmp,-dim_s/2,-dim_s/2)
        #D = shift(C,-dim_s/2,-dim_s/2)
        #plt.imshow(D**0.1)
    
    # On passe dans le plan de Fourier
    Im_SCC_FFT = np.fft.fft2(Im_SCC_tmp) 
        #E = np.fft.fft2(D)
        #plt.imshow(np.abs(E)**0.1)

    #Référence 1
    # On multiplie par le masque filtre_fourier (on selectionne un des piques de correlation)
    Ref_1 = Im_SCC_FFT*FFR1
        #F1 = E*FFR1
        #plt.imshow(np.abs(F1)**0.1)
        
    # on recentre le pique
    Ref_1 = subshift(Ref_1.real,-xi0_x1+dim_fourier/2,-xi0_y1+dim_fourier/2) + subshift(Ref_1.imag,-xi0_x1+dim_fourier/2,-xi0_y1+dim_fourier/2)*compl                
        #G1 = (subshift(F1.real,-xi0_x1+dim_fourier/2,-xi0_y1+dim_fourier/2) + subshift(F1.imag,-xi0_x1+dim_fourier/2,-xi0_y1+dim_fourier/2)*compl)
        #plt.imshow(np.abs(G1)**0.1)

    # on coupe une zone de dim_fourier autour
    Ref_1 = Ref_1[0:dim_fourier,0:dim_fourier]
        #H1 = G1[0:dim_fourier,0:dim_fourier]
        #plt.imshow(np.abs(H1)**0.1)

    # On recentre le pique
    Ref_1 = shift(Ref_1,-dim_fourier/2,-dim_fourier/2)
        #I1 = shift(H1,-dim_fourier/2,-dim_fourier/2)
        #plt.imshow(np.abs(I1)**0.1)    
    
    # On fait la TF inverse du pique
    I_minus_1 = np.fft.ifft2(Ref_1)
        #J1 = np.fft.ifft2(I1)
        #plt.imshow(np.abs(J1)**0.1)            
    
    # On le décale pour reduire la taille de l'image
    I_minus_1 = shift(I_minus_1,dim_dh_x/2,dim_dh_y/2)    
        #K1 = shift(J1,dim_dh_x/2,dim_dh_y/2)
        #plt.imshow(np.abs(K1)**0.1)     
    
    # On coupe l'image pour concerver l'information utile
    I_minus_1 = I_minus_1[0:dim_dh_x,0:dim_dh_y]
        #L1 = K1[0:dim_dh_x,0:dim_dh_y]
        #plt.imshow(np.abs(L1)**0.1)     
    
    # On filtre
    I_minus_1 *= Filtre_I
        #M1 = L1*Filtre_I
        #plt.imshow(np.abs(M1)**0.1)  

    # On construit l'estimateur
    Est_SCC_1 = np.concatenate((np.reshape(I_minus_1.real,dim_dh_y**2),np.reshape(I_minus_1.imag,dim_dh_y**2)),axis=0)
    
    # On ajoute une dimension pour pouvoir le mettre sous forme de cube
    Est_SCC_1 = Est_SCC_1[np.newaxis,:]
            
    #Référence 2
    # On multiplie par le masque filtre_fourier (on selectionne un des piques de correlation)
    Ref_2 = Im_SCC_FFT*FFR2
    
    # on recentre le pique
    Ref_2 = subshift(Ref_2.real,-xi0_x2+dim_fourier/2,-xi0_y2+dim_fourier/2) + subshift(Ref_2.imag,-xi0_x2+dim_fourier/2,-xi0_y2+dim_fourier/2)*compl                

    # on coupe une zone de dim_fourier autour
    Ref_2 = Ref_2[0:dim_fourier,0:dim_fourier]
    
    # On recentre le pique
    Ref_2 = shift(Ref_2,-dim_fourier/2,-dim_fourier/2)
  
    # On fait la TF inverse du pique
    I_minus_2 = np.fft.ifft2(Ref_2)
    
    # On le décale pour reduire la taille de l'image
    I_minus_2 = shift(I_minus_2,dim_dh_x/2,dim_dh_y/2)
    
    # On coupe l'image pour concerver l'information utile
    I_minus_2 = I_minus_2[0:dim_dh_x,0:dim_dh_y]      

    # On filtre
    I_minus_2 *= Filtre_I 
    
    # On construit l'estimateur
    Est_SCC_2 = np.concatenate((np.reshape(I_minus_2.real,dim_dh_y**2),np.reshape(I_minus_2.imag,dim_dh_y**2)),axis=0)
    
    # On ajoute une dimension pour pouvoir le mettre sous forme de cube
    Est_SCC_2 = Est_SCC_2[np.newaxis,:]

#    Est_SCC_2[Est_SCC_2 > Thresholdmax] = Thresholdmax
#    Est_SCC_2[Est_SCC_2 < Thresholdmin] = Thresholdmin
#    Est_SCC_1[Est_SCC_1 > Thresholdmax] = Thresholdmax
#    Est_SCC_1[Est_SCC_1 < Thresholdmin] = Thresholdmin
    
    # Estimateur MRSCC
    Est_MRSCC = np.concatenate((Est_SCC_1,Est_SCC_2),axis=1)  


    # seuil sur les 3 est
    
    Estimateurs  = {'Est_SCC_1':Est_SCC_1,'Est_SCC_2':Est_SCC_2,'Est_MRSCC':Est_MRSCC}

    
    return Estimateurs
