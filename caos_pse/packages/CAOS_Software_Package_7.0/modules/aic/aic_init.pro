; $Id: aic_init.pro,v 7.0 2016/04/15 marcel.carbillet $
;+ 
; NAME: 
;    aic_init 
; 
; PURPOSE: 
;    aic_init executes the initialization for the Achrom. Interf. Coronagraph
;    (AIC) module, that is:
;
;       0- check the formal validity of the input/output structure
;       1- initialize the output structure(s) out_wfp_t and out_wfp_t
;
;    (see wfp.pro's header --or file caos_help.html-- for details
;    about the module itself).
; 
; CATEGORY: 
;    module's initialisation routine 
; 
; CALLING SEQUENCE: 
;    error = aic_init(inp_wfp_t,  $ ; wfp_t input structure
;                     out_img_t,  $ ; img_t output structure 
;                     par,        $ ; parameters structure
;                     INIT=init   $ ; initialisation data structure
;                     ) 
; 
; INPUTS/OUTPUTS/KEYWORDS/ETC.: 
;    see aic.pro's help for a detailed description. 
;
; ROUTINE MODIFICATION HISTORY: 
;    routine written: september 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it],
;                     Christophe Verinaud (ESO) [cverinau@eso.org].
;    modifications  : december 2004,
;                     Marcel Carbillet (LUAN) [marcel.carbillet@unice.fr]:
;                    -stupid one-value-vector IDL6+ bug corrected
;                     (lambda->lambda[0] & width -> width[0]).
;                   : april 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;- 
; 
function aic_init, inp_wfp_t, $ ; input struc.
                   out_img_t, $ ; output struc.
                   par,       $ ; AIC parameters structure
                   INIT=init    ; AIC initialization data structure

; CAOS global common block
common caos_block, tot_iter, this_iter

; error code initialization
error = !caos_error.ok

; retrieve the module's informations
info = aic_info()

; get the individual output structure types
if info.out_type ne '' then out_type = str_sep(info.out_type,",")

; STANDARD CHECKS
;
; compute and test the requested number of aic arguments
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
   message, 'AIC error: par must be a structure'
if n ne 1 then message, 'AIC error: par cannot be a vector of structures'
if strlowcase(tag_names(par, /STRUCTURE_NAME)) ne info.mod_name then $
   message, 'par must be a parameter structure for the module AIC'

; check the input arguments

; test if any optional input exists
if n_inp gt 0 then begin
   inp_opt = info.inp_opt
endif

dummy = test_type(inp_wfp_t, TYPE=type)
if type eq 0 then begin         ; undefined variable
   inp_wfp_t = $
      {        $
      data_type  : inp_type[0],         $
      data_status: !caos_data.not_valid $
      }
endif
if test_type(inp_wfp_t, /STRUC, N_EL=n, TYPE=type) then $
   message, 'AIC error: wrong definition for the first input.'
if n ne 1 then message, $
   'AIC error: first input cannot be a vector of structures'

; test the data type
if inp_type[0] ne 'gen_t' then begin
   if inp_wfp_t.data_type ne inp_type[0] then                $
      message, 'wrong input data type: '+inp_wfp_t.data_type $
              +' ('+inp_type[0]+' expected).'
endif

if inp_wfp_t.data_status eq !caos_data.not_valid and not inp_opt[0] then $
      message, 'undefined input is not allowed'

;
; END OF STANDARD CHECKS

; STRUCTURE "INIT" DEFINITION
;

; structure INIT definition

; some more general parameters...
npup        = (size(inp_wfp_t.screen))[1]
dim         = par.psf_sampling*npup

; new pupil definition
pupil          = fltarr(dim,dim)
xx1            = dim/2 - dim/(2*par.psf_sampling)
pupil[xx1,xx1] = inp_wfp_t.pupil

; additional tip-tilt definition for companion contribution
off_axis    = par.off_axis/3600.*!DTOR
pos_ang     = par.pos_ang*!DTOR
decal       = dblarr(dim,dim)
tt          = dblarr(dim,dim,2)
xx          = (findgen(dim)-(dim-1)/2.)/(dim/2.+1)
xxx         = rebin(xx, dim, dim)
yyy         = transpose(xxx)
for i=0,1 do tt[*,*,i] = zern(i+2, xxx, yyy)
tt          = tt/(minmax(tt))[1]/2.
diam_tel    = inp_wfp_t.scale_atm * npup
decal       = (cos(pos_ang)*tt[*,*,0]+sin(pos_ang)*tt[*,*,1])*sin(off_axis)*diam_tel
decal       = decal*float(dim)/float(npup)

; INIT structure definition
init = $
   {   $
   dim         : dim,        $ ;
   decal       : decal,      $ ;
   xx1         : xx1,        $ ;
   pupil       : pupil       $ ;
   }


; INITIALIZE THE OUTPUT STRUCTURE(S)
;

; initialize (1st) output [bottom box] : the host star complex amplitude
;
dummy = n_phot(0., BAND=band)
lambda= inp_wfp_t.lambda[where(band eq par.band)]
lambda=lambda[0]
width = inp_wfp_t.width[where(band eq par.band)]
width=width[0]

resolution = lambda/diam_tel/par.psf_sampling*!RADEG*3600.

out_img_t= $
   {       $
   data_type  : out_type[0],               $
   data_status: !caos_data.valid,          $
   image      : fltarr(init.dim,init.dim), $
   npixel     : init.dim,                  $
   resolution : resolution,                $ ; spatial scale [m/px]

   lambda     : lambda,                    $ ; wavelength    [m]
   width      : width,                     $ ; bandwidth     [m]

   time_integ : 1.,                        $
   time_delay : 0.,                        $

   psf        : 1B,                        $
   background : 0.,                        $
   snr        : 0.                         $
   }

; back to calling program
return, error 
end