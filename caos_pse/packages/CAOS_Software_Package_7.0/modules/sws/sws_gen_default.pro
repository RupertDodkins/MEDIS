; $Id: sws_gen_default.pro,v 7.0 2016/05/19 marcel.carbillet $
;+
; NAME:
;    sws_gen_default
;
; PURPOSE:
;    sws_gen_default generates the default parameter structure
;    for the "sws" module and saves it in the rigth location.
;
; CATEGORY:
;    Utility routine
;
; CALLING SEQUENCE:
;    sws_gen_default
;
; MODIFICATION HISTORY:
;    program written: December 2003,
;                     Bruno Femenia (GTC) [bfemenia@ll.iac.es]:
;    modifications  : december 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -"mod_type"->"mod_name"
;                     (for version 4.0+ of the whole Software System CAOS").
;                    -tags "init_save" and "init_file" eliminated.
;                   : may 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;-
;
PRO sws_gen_default

   info     = sws_info()                              ;;Obtain module info
   module   = GEN_DEF_MODULE(info.mod_name, info.ver) ;;Generate module description structure 
   foc_dist = !values.f_infinity
                                                            
   par = {SWS,                 $   ;Structure named SWS
          module:      module, $   ;Standard module description structure
          time_integ:       1, $   ;Nb. of iterations to integrate
          time_delay:       0, $   ;Nb. of iterations to delay
          foc_dist:  foc_dist, $   ;Distance at which Shack-Hartman CCD is conjugated [m]
          nsubap:          20, $   ;Linear number of sub-apertures along pupil diameter.
          npixel:           6, $   ;Linear number of pixels per subaperture.
          pxsize:        0.25, $   ;Detector pixel size [arcsec/pixel]
          subapFoV:      1.50, $   ;Subaperture Field Stop diameter projected onto CCD. 
          fvalid:         .65, $   ;Fractional illumination for a subaperture to be a valid one.
          lambda:      800e-9, $   ;Mean working wavelength [m]
          width:       400e-9, $   ;Bandwidth [m]
          qeff:            1., $   ;Quantum efficiency
          threshold:        0, $   ;Threshold on WFS in counts (>=0)
          noise:     [0,0,0] , $   ;0/1=no/yes, for Photon noise, read-out and dark current noises, respectively
          read_noise:     3.0, $   ;Read-out noise is Gaussian distributed with zero mean and 3 e- rms.
          dark_noise:     1.0, $   ;Dark current noise is Poisson distributed  with mean 0.1 e-/s
          seed_pn:     123444, $   ;Value to get **INITIAL SEED** for generation of PHOTON NOISE
          seed_ron:    456777, $   ;Value to get **INITIAL SEED** for generation of READ-OUT NOISE
          seed_dark:   789000  $   ;Value to get **INITIAL SEED** for generation of DARK CURRENT NOISE
      }


   SAVE, par, FILENAME=info.def_file
   
   RETURN

END