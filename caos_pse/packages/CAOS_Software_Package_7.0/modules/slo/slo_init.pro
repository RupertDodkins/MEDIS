; $Id: slo_init.pro,v 7.0 2016/05/19 marcel.carbillet $
;+
; NAME:
;    slo_init
;
; PURPOSE:
;    slo_init executes the initialization for the slotroid computation
;    (slo) module.
;
; CATEGORY:
;    module's initialisation routine
;
; CALLING SEQUENCE:
;    error = slo_init(inp_mim_t, out_mes_t, par, INIT=init)
;
; INPUTS/OUTPUTS/KEYWORDS/ETC.:
;    see slo.pro's help for a detailed description.
;
; ROUTINE MODIFICATION HISTORY:
;    routine written: june 2001,
;                     Christophe Verinaud (OAA) [verinaud@arcetri.astro.it].
;    modifications  : october 2002,
;                     Christophe Verinaud (OAA) [verinaud@arcetri.astro.it]:
;                    -normalization alternative added.
;                   : january 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -"mod_type"->"mod_name"
;                     (for version 4.0 of the whole Software System
;                     CAOS).
;                   : february 2003,
;                     Christophe Verinaud (ESO) [cverinau@eso.org]:
;                    - slight modification of out_mim_t.nxsub/npixpersub
;                      for permitting display of slo measurements
;                   : may 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;-
;
function slo_init, inp_mim_t, $
                   out_mes_t, $
                   par,   $
                   INIT=init

; initialization of the error code: no error as default
error = !caos_error.ok 

; retrieve the input and output information
info = slo_info()

; get the individual output structure types
if info.out_type ne '' then out_type = str_sep(info.out_type,",")

; STANDARD CHECKS
;
; compute and test the requested number of slo arguments
n_par = 1  ; the parameter structure is always present within the arguments
if info.inp_type ne '' then begin
   inp_type = str_sep(info.inp_type,",")
   n_inp    = n_elements(inp_type)
endif else n_inp = 0
if info.out_type ne '' then begin
   out_type = str_sep(info.out_type,",")
   n_out    = n_elements(out_type)
endif else n_out = 0
n_par = n_par + n_inp + n_out
if n_params() ne n_par then message, 'wrong number of arguments'

; test the parameter structure
if test_type(par, /STRUCTURE, N_ELEMENTS=n) then $
   message, 'slo error: par must be a structure'
if n ne 1 then message, 'slo error: par cannot be a vector of structures'
if strlowcase(tag_names(par, /STRUCTURE_NAME)) ne info.mod_name then $
   message, 'par must be a parameter structure for the module slo'

; check the input arguments

; test if any optional input exists
if n_inp gt 0 then begin
   inp_opt = info.inp_opt
endif

dummy = test_type(inp_mim_t, TYPE=type)
if type eq 0 then begin         ; undefined variable
   inp_mim_t = $
      {        $
      data_type  : inp_type[0],         $
      data_status: !caos_data.not_valid $
      }
endif
if test_type(inp_mim_t, /STRUC, N_EL=n, TYPE=type) then $
   message, 'slo error: wrong definition for the first input.'
if n ne 1 then message, $
   'slo error: first input cannot be a vector of structures'

; test the data type
if inp_type[0] ne 'gen_t' then begin
   if inp_mim_t.data_type ne inp_type[0] then                $
      message, 'wrong input data type: '+inp_mim_t.data_type $
              +' ('+inp_type[0]+' expected).'
endif

if inp_mim_t.data_status eq !caos_data.not_valid and not inp_opt[0] then $
      message, 'undefined input is not allowed'

; structure INIT definition


error = slope(inp_mim_t, ref_mes,par.algo_type)

IF error NE 0 THEN return, error

init =  $
   {    $
   ref_mes: ref_mes $
   }


; INITIALIZE THE OUTPUT STRUCTURE
;
out_mes_t = $
   {        $
   data_type  : out_type[0],          $ ;\ standard
   data_status: !caos_data.valid,     $ ;/ stuff

   npixpersub : 1                   , $ ; nb of px per subap
   pxsize     : inp_mim_t.pxsize,     $ ; px size [non relevant]
   nxsub      : inp_mim_t.nxsub,      $ ; linear nb of subap
   nsp        : inp_mim_t.nsp,        $ ; nb of active subap
   xspos_CCD  : inp_mim_t.xspos_CCD,  $ ; x-coord. of the subap sloters [px]
   yspos_CCD  : inp_mim_t.yspos_CCD,  $ ; y-coord. of the subap sloters [px]
   convert    : inp_mim_t.convert,    $ ; convertion displacement->tilt
   geom       : inp_mim_t.type,       $ ; WFS geometry type
   lambda     : inp_mim_t.lambda,     $ ; wavelenght [m]
   width      : inp_mim_t.width,      $ ; bandwidth  [m]

   meas       : init.ref_mes,         $ ; initialisation ref. measurements
   type       : 0                     $ ; Shack-Hartmann wfs type
   }

return, error
end