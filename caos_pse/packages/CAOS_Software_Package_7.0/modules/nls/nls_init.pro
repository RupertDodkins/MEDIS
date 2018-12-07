; $Id: nls_init.pro,v 7.0 2016/04/29 marcel.carbillet $
;+
; NAME:
;    nls_init
;
; PURPOSE:
;    nls_init executes the initialization for the Na Layer Spot
;    (NLS) module that is:
;       0- check the formal validity of the input/output structure
;       1- initialize the output structure
;
; CATEGORY:
;    module's initialisation routine
;
; CALLING SEQUENCE:
;    error = nls_init(inp_wfp_t, $
;                     out_src_t, $
;                     par,       $
;                     INIT=init  )
;
; INPUTS/OUTPUTS/KEYWORDS/ETC.:
;    see module help for a detailed description.
;
; ROUTINE MODIFICATION HISTORY:
;    routine written: january 1999,
;                     Elise Viard (ESO) [eviard@eso.org].
;    modifications  : march 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -debugging.
;                    -the parameters n_phot (the source nb of photons)
;                     and background (the sky background nb of photons)
;                     are now always vectors with the Johnson bands
;                     (+ Na-band, see .../lib/n_phot) as index.
;                    -parameter coord defined in the output structure
;                     (was not).
;                    -nb of photons computation adapted to new version
;                     of the lib-routine n_phot.
;                   : december 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -adapted to version 2.0 (CAOS).
;                   : may 2000,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -the effective Na backscatter cross section (ecs)
;                     parameter and the atmosphere transmission (trans)
;                     parameter have no more a value fixed within this routine
;                     but are freely chosen by the user within the NLS GUI.
;                   : january 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -"mod_type"->"mod_name"
;                     (for version 4.0 of the whole Software System CAOS).
;                   : april 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;-
;
function nls_init, inp_wfp_t, $
                   out_src_t, $
                   par,       $
                   INIT=init

error = !caos_error.ok
info = nls_info()
if info.out_type ne '' then out_type = str_sep(info.out_type,",")

; STANDARD CHECKS
;
; compute and test the requested number of nls arguments
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
   message, 'NLS error: par must be a structure'
if n ne 1 then message, 'NLS error: par cannot be a vector of structures'
if strlowcase(tag_names(par, /STRUCTURE_NAME)) ne info.mod_name then $
   message, 'par must be a parameter structure for the module NLS'

; check the input arguments
;
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
   message, 'NLS error: wrong definition for the first input.'
if n ne 1 then message, $
   'NLS error: first input cannot be a vector of structures'

; test the data type
if inp_type[0] ne 'gen_t' then begin
   if inp_wfp_t.data_type ne inp_type[0] then                $
      message, 'wrong input data type: '+inp_wfp_t.data_type $
              +' ('+inp_type[0]+' expected).'
endif

if inp_wfp_t.data_status eq !caos_data.not_valid and not inp_opt[0] then $
      message, 'undefined input is not allowed'


; STRUCTURE "INIT" DEFINITION
;
IF  (par.own EQ 1) THEN BEGIN

;Sodium profile file loading
   IF ((findfile(par.Na))[0] EQ '') THEN BEGIN
      print, "the file cannot be found. "
      return, 111
   ENDIF
   IF strpos(par.Na, 'fits') NE -1 THEN BEGIN
      profile_Na = readfits(par.Na)
   ENDIF ELSE IF strpos(par.Na, 'sav') NE -1 THEN BEGIN
      restore, filename = par.Na
      IF  ((size(profile))[0] EQ 0) THEN BEGIN 
         print, 'Profile variable name, used when storing it with SAVE, ' $
               +'is not correct. It must be "profile".'
         return, 112
      ENDIF ELSE profile_Na = profile
   ENDIF ELSE BEGIN 
      print, 'The type of the sodium profile file must be either .FITS or .SAV.'
      return, 113
   ENDELSE
   Na_prof = profile_Na[0,*]
   n_sub = (size(profile_Na))[2]
   width = profile_Na[1,n_sub-1]-profile_Na[1,0]
   delta_z = width/(n_sub-1)      
   alt = profile_Na[1,0]+width/2.
   dummy = profile_Na[1,0] +findgen(n_sub)* delta_z
   FOR i=0,n_sub-1 DO BEGIN
      IF (profile_Na[1,i]-dummy[i]) NE 0. THEN BEGIN
         print,'Sub layers must be equally spaced.'
         return, 114
      ENDIF 
   ENDFOR
   
ENDIF ELSE BEGIN

   n_sub = par.n_sub
   width = par.width
   alt = par.alt
   error = nls_density(Na_prof, n_sub, width, inp_wfp_t.off_axis)
                                ; integrated density of Na in each sub-layer
                                ; of the Na layer
ENDELSE 
   
dim  = (size(inp_wfp_t.screen))[1]

; retrieve defined bands.
dummy   = n_phot(0., BAND=band)
n_bands = n_elements(band)

; nb of photon and background vectors
n_phot     = fltarr(n_bands)
background = fltarr(n_bands)

; sky background nb of photons per band
for i = 0, n_bands-1 do $
      background[i]= (n_phot(0., BAND=band[i], BACK_MAG=par.skymag))[1]
                                ; sky backgr. nb of photons/s/m^2

ecs = par.ecs                   ; effective Na backscatter
                                ; cross section [m^2]

trans = par.trans               ; atmosphere transmission
                                ;(during upward propagation
                                ;and then downward propagation)
delta_z = width/(n_sub-1)
                                ; distance between two successive
                                ; sub-layers in the Na layer [m]

dz = (findgen(n_sub)*delta_z-width/2)/cos(inp_wfp_t.off_axis)
                                ; projected distance [m]

for i = 0, n_bands-1 do $
   n_phot[i] = inp_wfp_t.n_phot[i] * trans * ecs $
               * total(Na_prof*(1+dz/inp_wfp_t.dist_z)^(-2))
                                ; integrated number of photons/s (over  
                                ; each sub-layer of the Na layer).

n_phot = n_phot/(4*!pi*inp_wfp_t.dist_z^2) * trans
                                ; nb of photons/s/m^2

error = nls_defocus(defocus, n_sub, dim, inp_wfp_t.scale_atm,  $
                    inp_wfp_t.pupil, inp_wfp_t.dist_z, alt, width, $
                    inp_wfp_t.lambda)
                                ; defocus additive phase

np        = (size(inp_wfp_t.map))[1] 
map3D     = fltarr(2*np,2*np,n_sub)
map_scale = 1/inp_wfp_t.scale_atm * inp_wfp_t.lambda[n_bands-1]/(size(map3D))[1]

; init structure 
init = $      ; NLS init structure
   {   $
   dim        : dim,        $
   Na_prof    : Na_prof,    $
   n_sub      : n_sub,      $
   width      : width,      $
   map        : map3D,      $ ; lgs 3D-map
   scale_xy   : map_scale,  $ ; map scale [rd/px]
   alt        : alt,        $
   defocus    : defocus,    $
   n_phot     : n_phot,     $
   background : background, $
   alreadydone: 0           $
   }


; INITIALIZE THE OUTPUT STRUCTURE
;
; define coord
error = nls_coord(coord, inp_wfp_t.dist, inp_wfp_t.angle, inp_wfp_t.off_axis, $
                  inp_wfp_t.pos_ang, init.alt, init.n_sub, init.width,        $
                  inp_wfp_t.dist_z                                            )

;output structure
out_src_t = $ 
   {        $
   data_type  : info.out_type[0],      $
   data_status: !caos_data.valid,      $
   off_axis   : inp_wfp_t.off_axis,    $ ; angular pos. of lgs [rd]
   pos_ang    : inp_wfp_t.pos_ang,     $ ; spot wrt main tel. [rd]
   dist_z     : inp_wfp_t.dist_z,      $ ; altitude of focalisation
   map        : init.map,              $ ; lgs 3D-map
   scale_xy   : init.scale_xy,         $ ; map scale [rd/px]
   coord      : coord,                 $ 
   scale_z    : init.width/init.n_sub, $ ; altitude scale [m]
   n_phot     : init.n_phot,           $ ; nb of photons/s/m^2
   background : init.background,       $ ; sky background [phot./s/arcsec^2/m^2]
   lambda     : inp_wfp_t.lambda,      $ ; wavelengths [m]
   width      : inp_wfp_t.width,       $ ; bandwidths [m]
   constant   : inp_wfp_t.constant     $
   }

END