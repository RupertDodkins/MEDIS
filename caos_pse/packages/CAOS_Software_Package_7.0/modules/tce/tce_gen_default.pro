; $Id: tce_gen_default.pro,v 7.0 2016/05/19 marcel.carbillet $
;+
; NAME:
;       tce_gen_default
;
; PURPOSE:
;       tce_gen_default generates the default parameter structure for the TCE
;       module and save it in the rigth location. 
;
; CATEGORY:
;       Utility
;
; CALLING SEQUENCE:
;       tce_gen_default
; 
; MODIFICATION HISTORY:
;       program written: Feb 1999,
;                        B. Femenia (OAA) [bfemenia@arcetri.astro.it]
;                       -rewritten to match general style and requirements on
;                        how to manage initialization process, calibration
;                        procedure and time management according to  released
;                        templates on Feb 1999.
;       modifications  : Jun 1999,
;                        B. Femenia (OAA) [bfemenia@arcetri.astro.it]
;                       -possibility to use a THRESHOLD value. Pixels exhibiting a
;                        number of detected photons < threshold => not used.
;                      : Nov 1999,
;                        B. Femenia   (OAA) [bfemenia@arcetri.astro.it]
;                       -adapted to new version CAOS (v 2.0).
;                      : April 2001,
;                        B. Femenia (OAA) [bfemenia@arcetri.astro.it]
;                       -possibility to introduce directly constant of calibration
;                        from TCE_GUI.
;                      : january 2003,
;                        Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                       -"mod_type"->"mod_name"
;                        (for version 4.0 of the whole Software System CAOS").
;                       -useless call to mk_par_name eliminated.
;                       -parameter "calibration" added in order to avoid use of a
;                        common variable.
;                      : may 2016,
;                        Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                       -adapted to Soft. Pack. CAOS 7.0.
;-
;
pro tce_gen_default

info = tce_info()                ; obtain module infos

module = gen_def_module(info.mod_name, info.ver)
                                 ; generate module descrip.
                                 ; structure

par = { TCE                , $   ; Structure named TCE
        module     : module, $   ; Standard module description structure
        calibration: 0B,     $   ; is it a calibration project ? [0B=no, 1B=yes]
        calib_file : ''    , $   ; If Q-cell, file where calibration data are stored.
        detector   : 1     , $   ; 0= Q-cell, 1=Barycenter.
        method     : 0     , $   ; By default, interpolate linearly calib curve to
                                 ; find tilt from Q-cell signal. Other values are
                                 ; 1 to perform spline interpolation to calibration curve
                                 ; and 2 to use calibration constant provided from within GUI.
        cal_cte    : 1.    , $   ; Calibration cte to be used if method=2.
        range      : 0.5   , $   ; Method=0 => linear fit to calibration curve from
                                 ; Signal range [-range,+range]
        threshold  : 0       $   ; Number of photons for a pixel to be considered.
      }

SAVE, par, FILENAME=info.def_file

RETURN

END