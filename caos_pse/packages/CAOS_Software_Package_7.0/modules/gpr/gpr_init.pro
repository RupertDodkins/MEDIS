; $Id: gpr_init.pro,v 7.0 2016/04/21 marcel.carbillet@unice.fr $
;+
; NAME:
;    gpr_init
;
; PURPOSE:
;    gpr_init executes the initialization for the Geometrical PRopagation
;    (GPR) module, that is:
;       0- check the formal validity of the input/output structures,
;       1- initialize the output structure out_wfp_t.
;
; CATEGORY:
;    module's initialisation routine
;
; CALLING SEQUENCE:
;    error = gpr_init(inp_src_t, inp_atm_t, out_wfp_t, par, INIT=init)
;
; INPUTS/OUTPUTS/KEYWORDS/ETC.:
;    see module help for a detailed description.
;
; ROUTINE MODIFICATION HISTORY:
;    program written: october 1998,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it],
;                     Elise  Viard     (ESO) [eviard@eso.org].
;    modifications  : january 1999,
;                     Elise Viard (ESO) [eviard@eso.org]:
;                    -modifications made...
;                   : february-march 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -added coord_pup and count_pup to the initialisation
;                     structure (were computed but not saved to it).
;                    -a few adaptations for version 1.0.
;                    -stripes propagation is managed now.
;                    -number of photons calculations take now into account
;                     the obscuration ratio.
;                   : march 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it],
;                     Armando Riccardi (OAA) [riccardi@arcetri.astro.it]:
;                    -added checks on the screens' dimensions wrt the
;                     telescope diameter and the position of the source(s).
;                   : october 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -number of photons calculation corrected (pupil
;                     obstruction ratio was not taken into account properly).
;                   : december 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -enhanced and adapted to version 2.0 (CAOS).
;                   : january 2000,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it],
;                     Bruno  Femenia   (OAA) [bfemenia@arcetri.astro.it]:
;                    -tag "correction" added to out_wfp_t in order to recognise
;                     a correcting wf (e.g. from TTM or DMI) from a "normal" wf
;                     (e.g. from GPR or CFB) or a corrected wf (e.g. after TTM
;                     or DMI as well).
;                   : march 2001,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -tag "correction" can now be 1B if it comes from a
;                     reconstructed atmosphere (MCAO case).
;                   : january/february 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -**!!stupid IDL!!** precision problem about the difference
;                     between variables "length" and "par.D" fixed.
;                    -"mod_type"->"mod_name"
;                     (for version 4.0 of the whole Software System CAOS).
;                    -parameter "alt", and hence output tag "tel_alt" eliminated
;                     (was relevant only to obsolete module SHS).
;                   : may 2014,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -(annoying) error handling inside the routine commented.
;
;-
;
function gpr_init, inp_src_t, $
                   inp_atm_t, $
                   out_wfp_t, $
                   par,       $
                   INIT=init

; error code initialization
error = !caos_error.ok

; retrieve the module's informations
info = gpr_info()

; GPR CHECK
;
; check the telescope diameter wrt screens length
length = (size(inp_atm_t.screen))[1] * inp_atm_t.scale
if (par.D gt length) then begin
    if (abs(par.D-length) gt length/1E4) then begin
       message, "telescope diameter is larger than atmospheric screens"
;       message, "telescope diameter is larger than atmospheric screens", $
;                CONT= not !caos_debug
;       error = !caos_error.module_error
;       return, error
   endif
endif

; STANDARD CHECKS
;
; compute and test the requested number of gpr arguments
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
   message, 'GPR error: par must be a structure'
if n ne 1 then message, 'GPR error: par cannot be a vector of structures'
if strlowcase(tag_names(par, /STRUCTURE_NAME)) ne info.mod_name then $
   message, 'par must be a parameter structure for the module GPR'

; check the input arguments

; test if any optional input exists
if n_inp gt 0 then begin
   inp_opt = info.inp_opt
endif

dummy = test_type(inp_src_t, TYPE=type)
if type eq 0 then begin         ; undefined variable
   inp_src_t = $
      {        $
      data_type  : inp_type[0],         $
      data_status: !caos_data.not_valid $
      }
endif
if test_type(inp_src_t, /STRUC, N_EL=n, TYPE=type) then $
   message, 'GPR error: wrong definition for the first input.'
if n ne 1 then message, $
   'GPR error: first input cannot be a vector of structures'

; test the data type
if inp_type[0] ne 'gen_t' then begin
   if inp_src_t.data_type ne inp_type[0] then                $
      message, 'wrong input data type: '+inp_scr_t.data_type $
              +' ('+inp_type[0]+' expected).'
endif

if inp_src_t.data_status eq !caos_data.not_valid and not inp_opt[0] then $
      message, 'undefined input is not allowed'

dummy = test_type(inp_atm_t, TYPE=type)
if type eq 0 then begin                ; undefined variable
   inp_atm_t = $
      {        $
      data_type  : inp_type[1],         $
      data_status: !caos_data.not_valid $
      }
endif

if test_type(inp_atm_t, /STRUC, N_EL=n, TYPE=type) then $
   message, 'GPR error: wrong definition for the second input.'

if n ne 1 then message, $
   'GPR error: second input cannot be a vector of structures'

; test the data type
if inp_atm_t.data_type ne inp_type[1] then                $
   message, 'wrong input data type: '+inp_atm.data_type $
           +' ('+inp_type[1]+' expected).'
if inp_atm_t.data_status eq !caos_data.not_valid and not inp_opt[1] then $
   message, 'undefined input is not allowed'

; STRUCTURE "INIT" DEFINITION
;
dim_x = (size(inp_atm_t.screen))[1]
dim_y = (size(inp_atm_t.screen))[2]
if (size(inp_atm_t.screen))[0] eq 2 then n_layers = 1 else $
   n_layers = (size(inp_atm_t.screen))[3]

alt_GS = abs(inp_src_t.dist_z)*cos(inp_src_t.off_axis)         
                                      ; source distance from tel.

IF (alt_GS ne !VALUES.F_INFINITY) THEN $
   ratio=alt_GS/(alt_GS-inp_atm_t.alt) $
ELSE ratio=fltarr(n_layers)+1         ; altitude ratios for source
                                      ; (=0 if infinite distance)
np = 2*(ceil(par.D/inp_atm_t.scale)/2)
                                      ; even nb of sampling pts for the pupil
pupil = makepupil(np, np, par.eps, XC=(np-1)/2., YC=(np-1)/2.)
                                      ; telescope pupil

r_GS  = gpr_coord(par.dist, par.angle, inp_src_t.off_axis $
                 , inp_src_t.pos_ang, inp_atm_t.alt)
                                      ; r_GS=source coord. on each layer
r_GS = r_GS/inp_atm_t.scale           ; meter to pixels conversion

; check that the beam from the source to the telescope pass
; through the screens available.

projR = (par.D/ratio)/inp_atm_t.scale/2. ; projected telescope radius
                                         ; on each layer [px]
if (dim_x eq dim_y) then begin
    
    if (total(reform(r_GS[0,*]) + projR gt dim_x/2 ) ne 0) or $
       (total(reform(r_GS[0,*]) - projR lt -dim_x/2) ne 0) or $
       (total(reform(r_GS[1,*]) + projR gt dim_x/2 ) ne 0) or $
       (total(reform(r_GS[1,*]) - projR lt -dim_x/2) ne 0) then begin
       message,                                                            $ 
          "the beam from the source fall outside some atmospheric screen"
;       message,                                                            $ 
;          "the beam from the source fall outside some atmospheric screen", $
;          CONT= not !caos_debug
;       error = !caos_error.module_error
;       return, error
    endif

endif else begin

    if total(inp_atm_t.dir*!RADEG mod 90.) ne 0 then begin
        message, "in this case, wind directions for the turbulent "+ $
                 "layers MUST BE 0, 90, 180 or 270 deg."
;        message, "in this case, wind directions for the turbulent "+ $
;                 "layers MUST BE 0, 90, 180 or 270 deg.",            $
;                 CONT= not !caos_debug
;        error = !caos_error.module_error
;        return, error
    endif
    
    vec_dim_x = intarr(n_layers) & vec_dim_y = intarr(n_layers)
    for i=0, n_layers-1 do begin
        if (inp_atm_t.dir[i]*!RADEG/90. mod 2) eq 0 then begin
            vec_dim_x[i] = dim_x
            vec_dim_y[i] = dim_y
        endif else begin
            vec_dim_x[i] = dim_y
            vec_dim_y[i] = dim_x
        endelse
    endfor
    
    if (total(reform(r_GS[0,*]) + projR gt vec_dim_x/2 ) ne 0) or $
       (total(reform(r_GS[0,*]) - projR lt -vec_dim_x/2) ne 0) or $
       (total(reform(r_GS[1,*]) + projR gt vec_dim_y/2 ) ne 0) or $
       (total(reform(r_GS[1,*]) - projR lt -vec_dim_y/2) ne 0) then begin
       message,                                                            $ 
          "the beam from the source fall outside some atmospheric screen"
;       message,                                                            $ 
;          "the beam from the source fall outside some atmospheric screen", $
;          CONT= not !caos_debug
;       error = !caos_error.gpr.
;       return, error
   endif   

endelse     
    
IF (inp_src_t.dist_z lt 0) THEN begin ; upward propagation case
                                      ; (that is a 2D map case)
   expand, inp_src_t.map, np, np, map_e
   map = map_e*pupil & map = map/total(map)
   map_scale = 0.                 ; this map is the laser input intensity
                                  ; map on the telescope pupil. it has thus
                                  ; the same scale as the atmospheric 
                                  ; screen / pupil;  in NLS, it has to be 
                                  ; transformed to the focalised intensity  
                                  ; map by the fourier transform.
   off_axis   = inp_src_t.off_axis
   pos_ang    = inp_src_t.pos_ang
   n_phot     = inp_src_t.n_phot*(1-par.eps^2)
   background = inp_src_t.background*(1-par.eps^2)

ENDIF ELSE BEGIN                   ; downward propagation case

   map        = inp_src_t.map
   map_scale  = inp_src_t.scale_xy
   off_axis   = inp_src_t.off_axis
   pos_ang    = inp_src_t.pos_ang
   n_phot     = inp_src_t.n_phot*!pi/4*par.D^2*(1-par.eps^2)
                                   ; object nb of photons/s
   background = inp_src_t.background*!pi/4*par.D^2*(1-par.eps^2)
                                   ; sky bg nb of photons/s/arcsec^2
      
ENDELSE 

init = $
   {   $                      ; gpr init. structure
   n_phot     : n_phot,     $ ; source nb of photons [/s]
   background : background, $ ; sky bg nb of photons [/s/arcsec^2]
   map        : map,        $ ; map [px,px]
   map_scale  : map_scale,  $ ; source map scale [rd/px]
   n_layers   : n_layers,   $ ; nb of layers
   ratio      : ratio,      $ ; altitude ratios
   dim_x      : dim_x,      $ ; screen x-dim. [px]
   dim_y      : dim_y,      $ ; screen y-dim. [px]
   r_GS       : r_GS,       $ ; object coord. on each layer [px,px]
   pupil      : pupil,      $ ; pupil of the telescope
   np         : np,         $ ; pupil dim. [px]
   alreadydone: 0.          $ ;
   }

; INITIALIZE THE OUTPUT STRUCTURE
;
out_wfp_t = $ 
   {        $
   data_type  : info.out_type[0],      $
   data_status: !caos_data.valid,      $   
   screen     : fltarr(np,np),         $ ; phase screen  [px,px]
   pupil      : init.pupil,            $ ; pupil 
   eps        : par.eps,               $ ; obscuration ratio
   scale_atm  : inp_atm_t.scale,       $ ; spatial scale [m/px]
   delta_t    : inp_atm_t.delta_t,     $ ; base time     [s]

   lambda     : inp_src_t.lambda,      $ ; wavelength    [m]
   width      : inp_src_t.width,       $ ; bandwidth     [m]
 
   n_phot     : init.n_phot,           $ ; source nb(s) of photons/s [phot/s]
   background : init.background,       $ ; sky background(s) [phot/s/arcsec^2]

   map        : init.map,              $ ; source map [px,px]
   map_scale  : init.map_scale,        $ ; scale [rd/px]
                                         ; Source position
   dist_z     : abs(inp_src_t.dist_z), $ ; source distance [m]
   off_axis   : inp_src_t.off_axis,    $ ; source off-axis angle [rd]
   pos_ang    : inp_src_t.pos_ang,     $ ; source position angle  [rd]

                                         ; Parameters related to the 3D LGS map:
   coord      : inp_src_t.coord,       $ ; source coordinates relative to the
                                         ; point [0,0] ([rd,rd,m,m,m])
   scale_z    : inp_src_t.scale_z,     $ ; vertical scale [m]

                                         ; Parameters of the telescope: 
   dist       : par.dist,              $ ; telescope distance from [0,0] ([m])
   angle      : par.angle,             $ ; telescope pos. angle wrt [0,0] ([rd])

   constant   : inp_src_t.constant,    $ ; constant (wrt time) source ?
   correction : inp_atm_t.correction   $ ; does it come from a reconstructed
   }                                     ; atmosphere ? (1B=yes, 0B=no)

; back to calling program
return,error
end