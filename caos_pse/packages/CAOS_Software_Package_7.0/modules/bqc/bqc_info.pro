; $Id: bqc_info.pro,v 7.0 2016/04/27 marcel.carbillet $
;+
; NAME:
;       bqc_info
;
; PURPOSE:
;       bqc_info is the routine that returns the basic informations about
;       the module BQC.
;
; CATEGORY:
;       Utility
;
; CALLING SEQUENCE:
;       info_structure = bqc_info()
;
; OUTPUTS:
;       info_structure: structure containing the module's basic informations.
;
; MODIFICATION HISTORY:
;       program written: Dec 2003,
;                        Bruno Femenia (GTC) [bfemenia@ll.iac.es]
;       modifications  : december 2003,
;                        Marcel Carbillet (OAA) [marcel@arcetri.astro.it]
;                       -adapted to version 4.0+ of the whole Software System CAOS
;                        (variable "pack_name" added, and variable "mod_type"
;                        changed into "mod_name").
;                       -useless variable "calib" eliminated.
;                       -variable "info.help" added (instead of !caos_env.help).
;
;                        December 2003,
;                        Bruno Femenia (GTC) [bfemenia@ll.iac.es]
;                       -this module does not require INIT structure.
;
;                      : September 2004,
;                        Bruno Femenia (GTC) [bfemenia@ll.iac.es]
;                       -adapted to version 5.0 of the Software Package CAOS.
;
;                      : april 2016,
;                        Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                       -adapted to Soft. Pack. CAOS 7.0.
;
;-
;
FUNCTION bqc_info

   mod_name = 'bqc'
   pack_name='CAOS_Software_Package_7.0'
   help_file='caos_help.html'
   help     = !caos_env.modules+pack_name+!caos_env.delim+'help'+!caos_env.delim+help_file

   descr    = 'Barycenter/Quad-cell Centroiding'
   ver      = FIX(7)

   def_file = MK_PAR_NAME(mod_name, PACK_NAME=pack_name, /DEFAULT)

   init     = 1B                                ;INIT STRUCTURE REQUIRED.
   time     = 0B                                ;MODULE NOT ALLOWED TO DELAY OR INTEGRATE.

   inp_type = 'mim_t'
   out_type = 'mes_t'

   inp_opt  = 0B                                            ;INPUT is not optional.

; convert in low case format and eliminate all the blanks
   mod_name = STRLOWCASE(STRCOMPRESS(mod_name, /REMOVE_ALL))
   inp_type = STRLOWCASE(STRCOMPRESS(inp_type, /REMOVE_ALL))
   out_type = STRLOWCASE(STRCOMPRESS(out_type, /REMOVE_ALL))

   info = { pack_name: pack_name,$
            help     : help,     $
            ver      : ver,      $

            mod_name : mod_name, $
            descr    : descr,    $
            def_file : def_file, $

            inp_type : inp_type, $
            inp_opt  : inp_opt,  $
            out_type : out_type, $

            init     : init,     $
            time     : time      }

   RETURN, info
END