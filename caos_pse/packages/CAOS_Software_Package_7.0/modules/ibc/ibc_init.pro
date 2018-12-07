; $Id: ibc_init.pro,v 7.0 2016/04/29 marcel.carbillet $
;+ 
; NAME: 
;    ibc_init 
; 
; PURPOSE: 
;    ibc_init executes the initialization for the Interferometric
;    Beam Combiner (IBC) module.
; 
; CATEGORY: 
;    module's initialisation routine 
; 
; CALLING SEQUENCE: 
;    error = ibc_init(in1_wfp_t, $ ; wfp_t input structure
;                     in2_wfp_t, $ ; wfp_t input structure
;                     out_wfp_t, $ ; wfp_t output structure
;                     par,       $ ; parameters structure
;                     INIT=init  ) ; initialisation structure
; 
; INPUTS/OUTPUTS/KEYWORDS/ETC.: 
;    see module help for a detailed description. 
; 
; ROUTINE MODIFICATION HISTORY: 
;    routine written: april-october 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it],
;                     Serge Correia    (OAA) [correia@arcetri.astro.it].
;    modifications  : december 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -adapted to version 2.0 (CAOS).
;                   : january 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -pupil better calculated (pupil1+pupil2).
;                    -"mod_type"->"mod_name"
;                     (for version 4.0 of the whole Software System CAOS).
;                    -output tag "tel_alt" eliminated (was useful only to
;                     obsolete module SHS).
;                    : march 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -now gives as an output the position of the
;                     interferometer (useful!) instead of its baseline and
;                     parallactic angle (useless!) --> output tags "dist" and
;                     "angle".
;                    : march 2005,
;                     Marcel Carbillet (LUAN) [marcel.carbillet@unice.fr],
;                     Olivier Lardiere (LISE) [lardiere@obs-hp.fr]:
;                    -densification feature added (for modelling the
;                     "densified pupil" case).
;                   : april 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;
;- 
; 
function ibc_init, in1_wfp_t, $
                   in2_wfp_t, $ 
                   out_wfp_t, $
                   par,       $
                   INIT=init 

; initialization of the error code
error = !caos_error.ok 

; retrieve the module's informations
info = ibc_info()

; get the individual output structure types
if info.out_type ne '' then out_type = str_sep(info.out_type,",")

; STANDARD CHECKS
;
; compute and test the requested number of ibc arguments
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
   message, 'IBC error: par must be a structure'
if n ne 1 then message, 'IBC error: par cannot be a vector of structures'
if strlowcase(tag_names(par, /STRUCTURE_NAME)) ne info.mod_name then $
   message, 'par must be a parameter structure for the module IBC'

; check the input arguments

; test if any optional input exists
if n_inp gt 0 then begin
   inp_opt = info.inp_opt
endif

dummy = test_type(in1_wfp_t, TYPE=type)
if type eq 0 then begin         ; undefined variable
   in1_wfp_t = $
      {        $
      data_type  : inp_type[0],         $
      data_status: !caos_data.not_valid $
      }
endif
if test_type(in1_wfp_t, /STRUC, N_EL=n, TYPE=type) then $
   message, 'IBC error: wrong definition for the first input.'
if n ne 1 then message, $
   'IBC error: first input cannot be a vector of structures'

; test the data type
if inp_type[0] ne 'gen_t' then begin
   if in1_wfp_t.data_type ne inp_type[0] then                $
      message, 'wrong input data type: '+in1_wfp_t.data_type $
              +' ('+inp_type[0]+' expected).'
endif

if in1_wfp_t.data_status eq !caos_data.not_valid and not inp_opt[0] then $
      message, 'undefined input is not allowed'

dummy = test_type(in2_wfp_t, TYPE=type)
if type eq 0 then begin                ; undefined variable
   in2_wfp_t = $
      {        $
      data_type  : inp_type[1],         $
      data_status: !caos_data.not_valid $
      }
endif

if test_type(in2_wfp_t, /STRUC, N_EL=n, TYPE=type) then $
   message, 'IBC error: wrong definition for the second input.'

if n ne 1 then message, $
   'IBC error: second input cannot be a vector of structures'

; test the data type
if in2_wfp_t.data_type ne inp_type[1] then                $
   message, 'wrong input data type: '+in2_wfp_t.data_type $
           +' ('+inp_type[1]+' expected).'
if in2_wfp_t.data_status eq !caos_data.not_valid and not inp_opt[1] then $
   message, 'undefined input is not allowed'

; STRUCTURE "INIT" DEFINITION
;

; pupil construction
np1   = (size(in1_wfp_t.pupil))[1]                 ; size of pupil 1 [px]
np2   = (size(in2_wfp_t.pupil))[1]                 ; size of pupil 2 [px]
scale = in1_wfp_t.scale_atm                        ; scale [m/px]

x1 = in1_wfp_t.dist * cos(in1_wfp_t.angle)         ; telescopes' positions 
y1 = in1_wfp_t.dist * sin(in1_wfp_t.angle)         ; wrt point [0, 0]
x2 = in2_wfp_t.dist * cos(in2_wfp_t.angle)         ; [m]
y2 = in2_wfp_t.dist * sin(in2_wfp_t.angle)

;modif for densified pupils
densification=par.densification
x0=(x1+x2)/2.
y0=(y1+y2)/2.
x1=x0+(x1-x0)/densification
y1=y0+(y1-y0)/densification
x2=x0+(x2-x0)/densification
y2=y0+(y2-y0)/densification


dim = (np1+np2)/2 + max([abs(x2-x1), abs(y2-y1)])/scale
dim = 2*(ceil(dim)/2)                              ; even number of pixels
                                                   ; for the diluted pupil

x = [(x1/scale)+np1/2, (x1/scale)-np1/2, $
     (x2/scale)+np2/2, (x2/scale)-np2/2]
y = [(y1/scale)+np1/2, (y1/scale)-np1/2, $
     (y2/scale)+np2/2, (y2/scale)-np2/2]

xc = min(x) + (max(x)-min(x))/2	   		   ; position of the center of
yc = min(y) + (max(y)-min(y))/2			   ; the diluted pupil [m]
		    
x1 = x1 / scale + (dim-1)/2. - xc
y1 = y1 / scale + (dim-1)/2. - yc                  ; telescopes' positions
x2 = x2 / scale + (dim-1)/2. - xc                  ; in the new wf array [px]
y2 = y2 / scale + (dim-1)/2. - yc

; initialize the diluted pupil
pupil1 = fltarr(dim, dim)
pupil2 = fltarr(dim, dim)

; put the pupil from the 1st telescope in the whole interferometer pupil
x0 = fix(x1 - np1/2.)
y0 = fix(y1 - np1/2.)
pupil1[x0, y0] = in1_wfp_t.pupil

; put the pupil from the 2d telescope in the whole interferometer pupil
x0 = fix(x2 - np2/2.)
y0 = fix(y2 - np2/2.)
pupil2[x0, y0] = in2_wfp_t.pupil

; initialisation structure itself
init = $
   {   $
   pupil: pupil1+pupil2, $
   x    : x, 	 $
   y    : y, 	 $
   scale: scale, $
   xc   : xc, 	 $
   yc   : yc,	 $
   x1   : x1,    $
   y1   : y1,    $
   np1  : np1,   $
   x2   : x2,    $
   y2   : y2,    $
   np2  : np2    $
   }
 
; INITIALIZE THE OUTPUT STRUCTURE
;
; number of photons
n_phot     = in1_wfp_t.n_phot     + in2_wfp_t.n_phot
background = in1_wfp_t.background + in2_wfp_t.background

;; interferometer baseline and parallactic angle
;;baseline = in1_wfp_t.scale_atm*sqrt((init.x1-init.x2)^2+(init.y1-init.y2)^2)
;;paral_angle = atan(init.y1-init.y2/(init.x1-init.x2))
; compute and give as an output the position of the interferometer (useful!)
; instead of its baseline and parallactic angle (useless!).
distance = sqrt(init.xc^2+init.yc^2)*in1_wfp_t.scale_atm
angle    = atan(init.yc, init.xc)

; output structure itself
out_wfp_t = $
   {        $
   data_type  : out_type[0],           $
   data_status: !caos_data.valid,      $

   screen     : fltarr(dim, dim),      $ ; phase screen [px,px]
   pupil      : init.pupil,            $ ; pupil [px, px]
   eps        : 0.,                    $ ; [NOT USED]

   scale_atm  : in1_wfp_t.scale_atm,   $ ; spatial scale [m/px]
   delta_t    : in1_wfp_t.delta_t,     $ ; base time     [s]
   lambda     : in1_wfp_t.lambda,      $ ; wavelength    [m]
   width      : in1_wfp_t.width,       $ ; bandwidth     [m]
   n_phot     : n_phot,                $ ; source nb(s) of photons/s [phot/s]
   background : background,            $ ; sky background(s) [phot/s/arcsec^2]

   map        : in1_wfp_t.map,         $ ; source map [px,px]
   map_scale  : in1_wfp_t.map_scale,   $ ; scale [rd/px]
                                         ; Source position related to:
                                         ; -the main telescope in case of
                                         ; use of SRC module.
   dist_z     : in1_wfp_t.dist_z,      $ ; source distance [m]
   off_axis   : in1_wfp_t.off_axis,    $ ; source off_axis [rd]
   pos_ang    : in1_wfp_t.pos_ang,     $ ; source pos_ang  [rd]

                                         ; Parameters related to the 3D LGS map:
   coord      : in1_wfp_t.coord,       $ ; source coordinates relative to the
                                         ; MAIN TELESCOPE [rd,rd,m,m,m]
   scale_z    : in1_wfp_t.scale_z,     $ ; vertical scale [m]

   dist       : distance,              $ ; baseline [m]
   angle      : angle,                 $ ; parallactic angle [rd]
                                         ; (baseline orientation)

   constant   : in1_wfp_t.constant,    $ ; constant (wrt time) source ?
   correction : in1_wfp_t.correction   $ ; corr. wf ?
   }

; back to calling program
return, error 
end