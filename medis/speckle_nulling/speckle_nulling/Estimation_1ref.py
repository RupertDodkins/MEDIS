# -*- coding: utf-8 -*-
"""
Created on Thu Apr 16 22:02:51 2015

@author: J-R
"""

import numpy as np

def Estimation_1ref(Image_freq,Filtre_Image,Filtre_Fourier,ray,Alpha,Xi):
    
    Image_FFT  = shift(np.fft.fft2(Image_freq*Filtre_Image)*Filtre_Fourier,int(np.around(-np.cos(Alpha)*Xi)+2*ray),int(np.around((np.sin(Alpha)*Xi)+2*ray)))   
    #plt.imshow(np.abs(Image_FFT)**(0.2))    
    #plt.imshow(Image_FFT.imag)    

        
    Lat_pic    = shift(Image_FFT[0:4*ray,0:4*ray],2*ray,2*ray)
    #plt.imshow(np.abs(Lat_pic)**(0.2))    

        
    Estimateur = shift(np.fft.ifft2(Lat_pic),int(np.ceil(ray*np.sqrt(2))),int(np.ceil(ray*np.sqrt(2))))    
    Estimateur = Estimateur[0:int(np.ceil(ray*np.sqrt(2))*2),0:int(np.ceil(ray*np.sqrt(2))*2)]
    #plt.imshow(np.abs(Estimateur)**(0.2))
        
    Estimateur = np.concatenate((np.reshape(Estimateur.real,int(np.ceil(ray*np.sqrt(2))*2)**2),np.reshape(Estimateur.imag,int(np.ceil(ray*np.sqrt(2))*2)**2)),axis=0)    
    return Estimateur[:,np.newaxis]