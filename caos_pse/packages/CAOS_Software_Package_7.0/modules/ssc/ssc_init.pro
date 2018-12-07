; $Id: ssc_init.pro, Soft.Pack.CAOS v 7.0 2016/05/19 marcel.carbillet
;+ 
; NAME: 
;    ssc_init 
; 
; PURPOSE: 
;    ssc_init executes the initialization for the State-Space Control
;    (SSC) module, that is:
;
;       0- check the formal validity of the input/output structure
;       1- initialize the output structure out_com_t
;**
;** DESCRIBE HERE WHAT KIND OF OTHER INITIALISATION OPERATIONS SSC_INIT PERFORMS
;**
;
;    (see ssc.pro's header --or file xyz_help.html-- for details
;    about the module itself).
; 
; CATEGORY: 
;    module's initialisation routine 
; 
; CALLING SEQUENCE: 
;    error = ssc_init(inp_mes_t,  $ ; com_t input structure
;                     out_com_t,  $ ; com_t output structure
;                     par,        $ ; parameters structure
;                     INIT=init   $ ; initialisation data structure
;                     ) 
; 
; INPUTS/OUTPUTS/KEYWORDS/ETC.: 
;    see ssc.pro's help for a detailed description. 
;
; ROUTINE MODIFICATION HISTORY: 
;    routine written: february 2012,
;                     Marcel Carbillet (Lagrange) [emarcel.carbillet@unice.fr].
;    modifications  : may 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;- 
; 
function ssc_init, inp_mes_t,  $ ; input struc.
                   out_com_t,  $ ; output struc.
                   par,        $ ; SSC parameters structure
                   INIT=init     ; SSC initialization data structure

; CAOS global common block
common caos_block, tot_iter, this_iter

; error code initialization
error = !caos_error.ok

; retrieve the module's informations
info = ssc_info()

; get the individual output structure types
if info.out_type ne '' then out_type = str_sep(info.out_type,",")

; STANDARD CHECKS
;
; compute and test the requested number of ssc arguments
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
   message, 'SSC error: par must be a structure'
if n ne 1 then message, 'SSC error: par cannot be a vector of structures'
if strlowcase(tag_names(par, /STRUCTURE_NAME)) ne info.mod_name then $
   message, 'par must be a parameter structure for the module SSC'

; check the input arguments

; test if any optional input exists
if n_inp gt 0 then begin
   inp_opt = info.inp_opt
endif

dummy = test_type(inp_mes_t, TYPE=type)
if type eq 0 then begin         ; undefined variable
   inp_mes_t = $
      {        $
      data_type  : inp_type[0],         $
      data_status: !caos_data.not_valid $
      }
endif
if test_type(inp_mes_t, /STRUC, N_EL=n, TYPE=type) then $
   message, 'SSC error: wrong definition for the first input.'
if n ne 1 then message, $
   'SSC error: first input cannot be a vector of structures'

; test the data type
if inp_type[0] ne 'gen_t' then begin
   if inp_mes_t.data_type ne inp_type[0] then                $
      message, 'wrong input data type: '+inp_mes_t.data_type $
              +' ('+inp_type[0]+' expected).'
endif

if inp_mes_t.data_status eq !caos_data.not_valid and not inp_opt[0] then $
      message, 'undefined input is not allowed'
;
; END OF STANDARD CHECKS

; STRUCTURE "INIT" DEFINITION
;
A=readfits(par.dir+'/'+'K_A.fits')
B=readfits(par.dir+'/'+'K_B.fits')
C=readfits(par.dir+'/'+'K_C.fits')
D=readfits(par.dir+'/'+'K_D.fits')

Nstate=(size(C))[1]
Ncomm =(size(C))[2]
Nmeas =n_elements(inp_mes_t.meas)

init = $
   {   $
   A    : A,                       $
   B    : B,                       $
   C    : C,                       $
   D    : D,                       $
   x    : fltarr(Nstate),          $
   Ncomm: Ncomm,                   $
; just to keep history of what is done:
   xx   : fltarr(Nstate,tot_iter), $
   yy   : fltarr(Nmeas ,tot_iter), $
   uu   : fltarr(Ncomm ,tot_iter)  $
   }


; INITIALIZE THE OUTPUT STRUCTURE
;
out_com_t = $
   {          $
   data_type  : out_type[0],       $
   data_status: !caos_data.valid,  $
   command    : fltarr(Ncomm),     $ ; command vector
   flag       : 0,                 $ ; -1=wf, 0=act. commands, 1=mode coeff.
   mod2com    : 0.,                $ ; mode->act. command matrix
   mode_idx   : 0                  $ ; index list of modes in command
   }

; back to calling program
return, error 
end