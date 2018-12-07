; $Id: mds_init.pro,v 7.0 2016/04/29 marcel.carbillet $
;+
; NAME: 
;    mds_init 
; 
; PURPOSE: 
;    mds_init executes the initialization for the MDS module,
;    that is:
;
;       0- check the formal validity of the input structure
;       1- initialize some useful parameters
;
;    (see mds.pro's header --or file caos_help.html-- for details
;    about the module itself).
; 
; CATEGORY: 
;    module's initialisation routine 
; 
; CALLING SEQUENCE: 
;    error = mds_init(out_atm_t, $ ; atm_t output
;                     par,       $ ; MDS parameters structure
;                     INIT=init)   ; initialisation data structure
; 
; INPUTS/OUTPUTS/KEYWORDS/ETC.: 
;       see mds.pro's help for a detailed description. 
;
; ROUTINE MODIFICATION HISTORY: 
;       program written: june 2002,
;                        Marcel Carbillet (OAA) [marcel@arcetri.astro.it],
;                        Christophe Verinaud (OAA) [verinaud@arcetri.astro.it].
;       modifications  : june 2002,
;                        Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                       -bug on dim (was taken as par.dim always in init and
;                        so was not a priori adapted if user-defined mirror
;                        deformations were taken).
;                      : july 2002
;                        Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                       -Zernike and user-defined deformations are now both well
;                        ordered (piston is defined for iter 0 and then the
;                        usefull deformations are sent).
;                      : january/february 2003,
;                        Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                       -"mod_type"->"mod_name"
;                       (for version 4.0 of the whole Software System CAOS).
;                       -PZT influence functions case added.
;                       -structure INIT simplified.
;                      : april 2016,
;                        Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                       -adapted to Soft. Pack. CAOS 7.0.
;-
;
function mds_init, out_atm_t, $
                   par,       $
                   INIT=init

; CAOS global common block
common caos_block, tot_iter, this_iter

; initialization of the error code: no error as default
error = !caos_error.ok

; retrieve the input and output information
info = mds_info()

; get the individual output structure types
if info.out_type ne '' then out_type = str_sep(info.out_type,",")

; STANDARD CHECKS
;
; compute and test the requested number of zat arguments
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
   message, 'MDS error: par must be a structure'
if n ne 1 then message, 'MDS error: par cannot be a vector of structures'

if strlowcase(tag_names(par, /STRUCTURE_NAME)) ne info.mod_name then $
   message, 'par must be a parameter structure for the module MDS'

; STRUCTURE "INIT" DEFINITION AND INITIALISATION DATA FILE MANAGEMENT
;
if par.mirdef_choice eq 0B then begin

   restore, FILENAME=par.mirdef_file, /VERBOSE
   nmodes = (size(DEF))[3]+1   ; +1 in order to add piston for iter.0
   dim    = (size(DEF))[1]
   mirdef = fltarr(dim, dim, nmodes)
   for k=0, nmodes-2 do mirdef[*,*,k+1] = DEF[*,*,k] 

   pupil  = makepupil(dim, dim, 0., XC=(dim-1)/2., YC=(dim-1)/2.)

   coeff  = fltarr(nmodes)
   coeff[1:nmodes-1] = par.mirdef_amplitude   ; piston coeff. set to 0.

   tot_iter = nmodes-1

endif else if par.mirdef_choice eq 1B then begin

   dim    = par.dim
   pupil  = makepupil(dim, dim, 0., XC=(dim-1)/2., YC=(dim-1)/2.)
   xx     = (findgen(dim)-(dim-1)/2.)/(dim/2.+1)
   xxx    = rebin(xx, dim, dim)
   yyy    = transpose(xxx)
   nmodes = long((par.zern_rad_degree+1)*(par.zern_rad_degree+2)/2.)
   mirdef = fltarr(dim, dim, nmodes)

   tot_iter = nmodes-1 ; a piston=zero (flat null screen) corresponds to the
                       ; iteration zero (initialisation), while each following
                       ; mode corresponds to Noll nb (this_iter+1), i.e. from
                       ; 2 (tip) to tot_iter+1 (mode nb "nmodes")

   for i=0, nmodes-1 do mirdef[*,*,i] = zern(i+1, xxx, yyy)

   coeff = fltarr(nmodes)
   for i=1, nmodes-1 do begin
      nm = zernumero(i+1) & nm = nm[0] > 1
      coeff[i] = 1./nm         ; coeff[0] (corr. to piston) is equal to zero
   endfor

   coeff = par.mirdef_amplitude * temporary(coeff)

endif else if par.mirdef_choice eq 2B then begin

   dim = par.dim
   pupil = makepupil(dim, dim, par.eps, XC=(dim-1)/2., YC=(dim-1)/2.)

   ; building the mirror geometry (piezo-electric mirror)
   mir_geom = sqmir_geom(par.nb_act, dim, par.eps)

   ; building the influence functions
   nmodes = mir_geom.nact+1
   mirdef = fltarr(dim,dim,nmodes)
   print, 'Building the influence functions ... Please wait ...'
   print, ''
   mirdef[*,*,1:nmodes-1] = infl_fct_pzt(mir_geom, dim, pupil)

   coeff = fltarr(nmodes)
   coeff[1:nmodes-1] = par.mirdef_amplitude

   tot_iter = nmodes-1

endif else if par.mirdef_choice eq 2B then begin
   message, "not yet implemented... wanna do it ?? ;-)"
endif

init = $
  {    $
  coeff  : coeff,     $ ; mirror deformation coefficients
  pupil  : pupil,     $ ; pupil
  mirdef : mirdef     $ ; PZT influence functions or Zernike polynomials
                        ; or user-defined mirror modes
  }

; INITIALIZE THE OUTPUT STRUCTURE
;
out_atm_t = $                       ; output structure init.
  {         $
  data_type  : info.out_type[0],  $ ; data type
  data_status: !caos_data.valid,  $ ; data status
  screen     : fltarr(dim, dim),  $ ; current mirror deformation
  scale      : par.length/dim,    $ ; scale [m/px]
  delta_t    : 1.,                $ ; evolution/integration time
                                    ; is set to 1 second
  alt        : par.alt,           $ ; mirror conjugation alt. [m]
  dir        : 0.,                $ ; [NOT USED]
  correction : 0B                 $ ; this is NOT a corr. atm.
  }

; back to calling program
return, error
end