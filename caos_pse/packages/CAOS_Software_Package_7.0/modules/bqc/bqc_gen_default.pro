; $Id: bqc_gen_default.pro,v 7.0 2016/04/27 marcel.carbillet $
;
;+
; NAME:
;       bqc_gen_default
;
; PURPOSE:
;       bqc_gen_default generates the default parameter structure for the BQC
;       module and save it in the rigth location. 
;
; CATEGORY:
;       Utility
;
; CALLING SEQUENCE:
;       bqc_gen_default
; 
; MODIFICATION HISTORY:
;       program written: Dec 2003,
;                        B. Femenia (GTC) [bfemenia@ll.iac.es].
;       modifications  : december 2003,
;                        Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                       -"mod_type"->"mod_name"
;                        (for compatibility with version 4.0+ of the whole Software System CAOS").
;
;                        December 2003,
;                        B. Femenia (GTC) [bfemenia@ll.iac.es].
;                       -Removing seldomly used tags and letting BQC a much simpler module to
;                        use when considering a Q-cell detector.
;
;                        September 2003,
;                        B. Femenia (GTC) [bfemenia@ll.iac.es].
;                       -Adding new parameters such as file storing Q-cell calibration
;                        constants for each subaperture and allowing same cte for all subap.
;
;                        September 2003,
;                        B. Femenia (GTC) [bfemenia@ll.iac.es].
;                       -Adding possibility to apply pixel weighting when computing barycenter.
;
;                        September 2004,
;                        B. Femenia   (GTC) [bfemenia@ll.iac.es].
;                       -adapted to version 5.0 of the Software Package CAOS.
;
;                      : april 2016,
;                        Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                       -adapted to Soft. Pack. CAOS 7.0.
;
;-
;
pro bqc_gen_default

   info   = bqc_info()                                 ;Get module info.

   module = gen_def_module(info.mod_name, info.ver)    ;Generate module description structure

   par = { BQC,            $     ; Structure named BQC.
           module: module, $     ; Standard module description structure.
           detector:    1, $     ; 0= Q-cell, 1=Barycenter.
           cal_cte:    1., $     ; Q-cell gain factor in units of [arcsec] obtained from a
                                 ;   previous calibration project or by other means.
           same_cal:   1B, $     ; If Q-cell, by setting this var all the subapertures use the same cal cte.
           cal_file:   '', $     ; If Q-cell and same_cal=0B, cal_file is the address of file storing ctes.
           weights:    0B, $     ; 0=does not apply any pixels weighting. 1= apply pixel weighting.
           filename:   ''}       ; Address of file storing pixel weights.

   SAVE, par, FILENAME=info.def_file

END