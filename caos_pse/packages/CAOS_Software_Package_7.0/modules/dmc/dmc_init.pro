; $Id: dmc_init.pro,v 7.0 2016/04/29 marcel.carbillet $
;+
; NAME:
;    dmc_init
;
; PURPOSE:
;    dmc_init executes the initialization for the Deformable Mirror
;    Conjugated (DMC) module, that is:
;
;       0- check the formal validity of the input/output structure
;       1- initialize the output structures
;
;    (see dmc.pro's header --or file caos_help.html-- for details).
;
; CATEGORY:
;    module's initialisation routine
;
; CALLING SEQUENCE:
;    err = dmc_init(inp_atm_t, $
;                   inp_com_t, $
;                   out_atm_c, $
;                   out_atm_t, $
;                   par,       $
;                   INIT=init  )
;
; INPUTS/OUTPUTS/KEYWORDS/ETC.:
;    see dmc.pro's help for a detailed description.
;
; ROUTINE MODIFICATION HISTORY:
;    routine written: february 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it].
;                     (helped from modules DMI and ATA).
;    modifications  : april 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;
;-
;
FUNCTION dmc_init, inp_atm_t, $
                   inp_com_t, $
                   out_atm_c, $
                   out_atm_t, $
                   par,       $
                   INIT=init

; initialization of the error code
error = !caos_error.ok 

; retrieve the output information
info = dmc_info()

; get the individual output structure types
if info.out_type ne '' then out_type = str_sep(info.out_type,",")

; STANDARD CHECKS
;
; compute and test the requested number of dmc arguments
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
   message, 'DMC error: par must be a structure'
if n ne 1 then message, 'DMC error: par cannot be a vector of structures'
if strlowcase(tag_names(par, /STRUCTURE_NAME)) ne info.mod_name then $
   message, 'par must be a parameter structure for the module DMC'

; check the input arguments
; test if any optional input exists
if n_inp gt 0 then begin
   inp_opt = info.inp_opt
endif

dummy = test_type(inp_atm_t, TYPE=type)
if type eq 0 then begin         ; undefined variable
   inp_atm_t = $
      {        $
      data_type  : inp_type[0],         $
      data_status: !caos_data.not_valid $
      }
endif
if test_type(inp_atm_t, /STRUC, N_EL=n, TYPE=type) then $
   message, 'DMC error: wrong definition for the first input.'
if n ne 1 then message, $
   'DMC error: first input cannot be a vector of structures'

; test the data type
if inp_type[0] ne 'gen_t' then begin
   if inp_atm_t.data_type ne inp_type[0] then                $
      message, 'wrong input data type: '+inp_atm_t.data_type $
              +' ('+inp_type[0]+' expected).'
endif

if inp_atm_t.data_status eq !caos_data.not_valid and not inp_opt[0] then $
      message, 'undefined input is not allowed'

dummy = test_type(inp_com_t, TYPE=type)
if type eq 0 then begin                ; undefined variable
   inp_com_t = $
      {        $
      data_type  : inp_type[1],         $
      data_status: !caos_data.not_valid $
      }
endif

if test_type(inp_com_t, /STRUC, N_EL=n, TYPE=type) then $
   message, 'DMC error: wrong definition for the second input.'

if n ne 1 then message, $
   'DMC error: second input cannot be a vector of structures'

; test the data type
if inp_com_t.data_type ne inp_type[1] then                $
   message, 'wrong input data type: '+inp_com_t.data_type $
           +' ('+inp_type[1]+' expected).'
if inp_com_t.data_status eq !caos_data.not_valid and not inp_opt[1] then $
   message, 'undefined input is not allowed'

; STRUCTURE "INIT" DEFINITION AND INITIALISATION STRUCTURE DEFINITION
;
; the mirror deformations
if par.mirdef_file ne " " then begin
   restore, FILENAME=par.mirdef_file, /VERBOSE
   n_dm = 1
endif else begin
   DEF=0.
   n_dm = 0
endelse
np = (size(DEF))[1]
nm = (size(DEF))[3]
nx = (size(inp_atm_t.screen))[1]
ny = (size(inp_atm_t.screen))[2]
mirdef = fltarr(nx, ny, nm)
for k=0, nm-1 do $
mirdef[nx/2-np/2:nx/2+np/2-1,ny/2-np/2:ny/2+np/2-1,k] = DEF[*,*,k]

; the mirror coordinates (in pixels)
x_mir = -par.dist*cos(par.angle)/inp_atm_t.scale
y_mir = -par.dist*sin(par.angle)/inp_atm_t.scale

; the mirror deformations x- and y-positions
if abs(x_mir) gt 0.001 or abs(y_mir) gt 0.001 then begin
   xx = round(x_mir) & yy = round(y_mir)

   if (abs(x_mir-xx) gt 0.001) or (abs(y_mir-yy) gt 0.001) then begin
   ; apply ROT function for atmosphere shift
   ; interpolation only if it is necessary
      for k=0, nm-1 do mirdef[*,*,k] = $
                       rot(shift(temporary(mirdef[*,*,k]),-xx,-yy), $
                           0.,                $ ; no rotation
                           1.,                $ ; no magnification
                           (nx-1)/2+x_mir-xx, $ ; x-center of array
                           (ny-1)/2+y_mir-yy, $ ; y-center of array
                           CUBIC=-.5          ) ; interpolation method
      print, "DMC warning:=========================================+"
      print, "| a cubic interpolation is applied in order to take  |"
      print, "| into account the position of the correcting mirror.|"
      print, "+====================================================+"
   endif else for k=0, nm-1 do mirdef[*,*,k] = $
                               shift(temporary(mirdef[*,*,k]),-xx,-yy)
endif

; the INIT structure

n_layers = (size(inp_atm_t.alt))[1]

init = $
   {   $
   mirdef  : mirdef,   $ ; mirror deformations
   nm      : nm,       $ ; number of mirror deformations
   n_layers: n_layers, $ ; number of atmospheric layers
   n_dm    : n_dm      $ ; number of deformable mirrors
   }

; INITIALIZE THE OUTPUT STRUCTURE
;
; initialize corrected atmosphere output

out_atm_t = $
   {        $
   data_type  : out_type[0],                 $
   data_status: !caos_data.valid,            $
   screen     : fltarr(nx,ny,n_layers+n_dm), $
   scale      : inp_atm_t.scale,             $
   delta_t    : inp_atm_t.delta_t,           $
   alt        : [[inp_atm_t.alt,par.alt]],   $
   dir        : [[inp_atm_t.dir,     0.]],   $
   correction : 0B                           $
   }

; initialize correcting mirror shape output
out_atm_c = $
   {        $
   data_type  : out_type[1],      $
   data_status: !caos_data.valid, $
   screen     : fltarr(nx,ny),    $
   scale      : inp_atm_t.scale,  $
   delta_t    : inp_atm_t.delta_t,$
   alt        : par.alt,          $
   dir        : 0.,               $
   correction : 1B                $
   }

; back to calling program
return, error
end