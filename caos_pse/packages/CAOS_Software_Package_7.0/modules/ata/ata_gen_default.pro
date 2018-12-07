; $Id: ata_gen_default.pro,v 7.0 2016/04/15 marcel.carbillet $
;+
; NAME:
;       ata_gen_default
;
; PURPOSE:
;       ata_gen_default generates the default parameter structure for the ATA
;       module and save it in the rigth location. (see ata.pro's header --or
;       file caos_help.html-- for details about the module itself). 
; 
; CATEGORY:
;       module's utility routine
;
; CALLING SEQUENCE:
;       ata_gen_default 
; 
; MODIFICATION HISTORY:
;       program written: march 2001,
;                        Bruno Femenia (OAA) [bfemenia@arcetri.astro.it].
;
;       modifications  ; june 2002,
;                        Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                       -default is now that 2nd atmosphere (top input) is a correcting one,
;                        and that its weight assigned is -1.
;                      : january 2003,
;                        Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                       -"mod_type" --> "mod_name"
;                        (for version 4.0 of the whole Software System CAOS).
;                       -useless parameters "init_file" and "init_save" eliminated.
;                   : april 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;-
;
pro ata_gen_default

info = ata_info()                                 ; obtain module infos

module = gen_def_module(info.mod_name, info.ver)  ; generate module descrip. structure

par = { ATA                  , $                  ; Structure named ATA
        module    : module   , $                  ; Standard module description structure
        wb        :  1.0     , $                  ; Weight assigned to first input 
                               $                  ;     (in AppBuilder, bottom box!!)
        wt        : -1.0     , $                  ; Weight assigned to second input 
                               $                  ;     (in AppBuilder, top box!!)
        threshold : 50.      , $                  ; Minimum altitude difference between two screens to be 
                               $                  ;     assumed at different layers
        atm1_corr : 0B       , $                  ; 0B Flags this is not a correction atm_t
        atm2_corr : 1B       , $                  ; 1B Flags this is a correction atm_t
        nlay_corr : 1        , $                  ; In case there is a correction atm_t, nb of layers.
        alt_corr  : FLTARR(6)  $                  ; In case there is a correction atm_t the altitudes.
      }

SAVE, par, FILENAME=info.def_file

RETURN
END