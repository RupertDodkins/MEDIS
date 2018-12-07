; $Id: img_gen_default.pro,v 7.0 2016/04/21 marcel.carbillet $
;+
; NAME:
;       img_gen_default
;
; PURPOSE:
;       img_gen_default generates the default parameter structure
;       for the IMG module and saves it in the rigth location.
;       The user doesn't need to use img_gen_default, it is used
;       only for developing and upgrading purposes.
;
; CATEGORY:
;       Utility
;
; CALLING SEQUENCE:
;       img_gen_default
; 
; MODIFICATION HISTORY:
;       program written: Jan 2000,
;                        B. Femenia (OAA) [bfemenia@arcetri.astro.it]
;       modifications  : Oct 2002,
;                        Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                       -"backgradd" tag added, in order to have the choice
;                        between adding or not the sky background in the
;                        PSFs and the images.
;                      : january 2003,
;                        Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                       -"mod_type"->"mod_name"
;                        (for version 4.0 of the whole Software System CAOS").
;                       -useless parameters "init_file" and "init_save" eliminated.
;                      : March 2003,
;                        B. Femenia (GTC) [bfemenia@ll.iac.es]
;                       -merging versions at OAA and GTC.
;                      : april 2016,
;                        Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                       -adapted to Soft. Pack. CAOS 7.0.
;-
;
PRO img_gen_default

info = img_info()                 ; obtain module info

module =                        $ ; generate module descrip.
  gen_def_module(info.mod_name, $ ; structure
                 info.ver)
                                  
npixel  = 8                       ; Nb. detector pixels along x- & y-axes
pxsize  = 2./npixel                ; Detector pixel size [arcsec]
foc_dist= !values.f_infinity

par = { IMG                 , $   ; Structure named IMG
        module    : module  , $   ; Standard module description structure
        time_integ: 1       , $   ; No. of iterations to integrate
        time_delay: 0       , $   ; No. of iterations to delay
        foc_dist  : foc_dist, $   ; Distance at which IMG detector is conjugated [m]
        npixel    : npixel  , $   ; Nb. detector pixels along x- & y-axes
        pxsize    : pxsize  , $   ; Detector pixel size [arcsec/pixel]
        qeff      : 1.      , $   ; Quantum efficiency
        lambda    : 550e-9  , $   ; Mean working wavelength [m]
        width     : 89e-9   , $   ; Bandwidth [m]
        backgradd : 0B      , $   ; add background ? [0=no, 1=yes]
        noise     : [1,0,0] , $   ; 0=no, 1=yes for Photon noise, read-out
                              $   ;       and dark current noises.
        read_noise: 3       , $   ; Read-out noise is Gaussian distributed
                              $   ;       with zero mean and 3 e- rms.
        dark_noise: 0.1     , $   ; Dark current noise is Poisson distributed
                              $   ;       with mean 0.1 e-/s
        increase  : 1       , $   ; Factor by which dimensions of arrays
                              $   ;   are enlarged to increase sampling of PSF
        seed_pn   : 123444  , $   ; SEED for generation of PHOTON NOISE
        seed_ron  : 456777  , $   ; SEED for generation of READ-OUT NOISE
        seed_dark : 789000    $   ; SEED for generation of DARK CURRENT NOISE
      }

SAVE, par, FILENAME=info.def_file

RETURN
END