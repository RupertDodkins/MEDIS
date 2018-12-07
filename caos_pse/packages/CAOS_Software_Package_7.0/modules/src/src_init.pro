; $Id: src_init.pro,v 7.0 2016/04/21 marcel.carbillet $
;+
; NAME:
;       src_init
;
; PURPOSE:
;       src_init executes the initialization for the Calibration FiBer
;       (SRC) module, that is:
;
;         0- check the formal validity of the output structure.
;         1- initialize the output structure(s) out_wfp_t.
;
;       (see src.pro's header --or file caos_help.html-- for details
;       about the module itself).
;
; CATEGORY:
;       module's initialisation routine 
;
; CALLING SEQUENCE:
;       error = src_init(out_src_t, $
;                        par,       $
;                        INIT=init  $
;                       )
;
; INPUTS/OUTPUTS/KEYWORDS/ETC.:
;       see src.pro's help for a detailed description. 
;
; MODIFICATION HISTORY:
;       program written: february 1999,
;                        Marcel Carbillet (OAA) [marcel@arcetri.astro.it].
;       modifications  : march 1999,
;                        Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                       -the parameters n_phot (the source nb of photons)
;                        and background (the sky background nb of photons)
;                        are now always vectors with the Johnson bands
;                        (+ Na-band, see .../lib/n_phot) as index, even in
;                        the LGS case.
;                      : march 1999,
;                        Marcel Carbillet (OAA) [marcel@arcetri.astro.it],
;                        Simone Esposito  (OAA) [esposito@arcetri.astro.it]:
;                       -added 2D-objects calculation feature.
;                      : december 1999,
;                        Bruno Femenia (OAA) [bfemenia@arcetri.astro.it]:
;                       -adapted to new version CAOS (v 2.0).
;                      : september 2001,
;                        Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                       -star magnitudes in all bands are now defined within the GUI.
;                      : june 2002,
;                        Christophe Verinaud (OAA) [verinaud@arcetri.astro.it],
;                        Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                       -background was the same for all bands (the one of the first
;                        band defined !!): bug corrected.
;                      : january 2003,
;                        Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                       -"mod_type"->"mod_name"
;                        (for version 4.0 of the whole Software System CAOS).
;                      : april 2016,
;                        Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                       -adapted to Soft. Pack. CAOS 7.0.
;-
;
function src_init, out_src_t, par, INIT=init

; STANDARD CHECKS
;================

error = !caos_error.ok                                      ;Init error code: no error as default
info = src_info()                                           ; Retrieve the Input & Output info.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Compute and test the requested number of src arguments
n_par = 1                       ; the parameter structure is always
                                ; present within the arguments

if info.inp_type ne '' then begin
   inp_type = str_sep(info.inp_type,",")
   n_inp = n_elements(inp_type)
endif else n_inp = 0

if info.out_type ne '' then begin
   out_type = str_sep(info.out_type,",")
   n_out = n_elements(out_type)
endif else n_out = 0

n_par = n_par + n_inp + n_out

; test the number of passed parameters
if n_params() ne n_par then message, 'wrong number of parameters'

; test the parameter structure
if test_type(par, /STRUCTURE, N_ELEMENTS=n) then $
   message, 'SRC: par must be a structure'
if n ne 1 then message, 'SRC: par cannot be a vector of structures'
if strlowcase(tag_names(par, /STRUCTURE_NAME)) ne info.mod_name then $
   message, 'par must be a parameter structure for the module src'


; NO INPUT => no test on the input argument !!
;--------------------------------------------

; extended source or not...
if (par.extended eq 1) then begin       ; extended object case

   scale_xy = par.mapscale              ; map scale [rd/px]

   case par.map_type of

      0: begin                          ; uniform disc map case
         np  = 2*(ceil(2*par.disc/scale_xy)/2)
                                        ; even nb of pixels
	 map = makepupil(np, np, 0., XC=(np-1)/2., YC=(np-1)/2.)
                                        ; compute uniform disc
      end

      1: begin                          ; gaussian map case
	 np      = 2*(ceil(par.gauss_size/scale_xy)/2)
                                        ; even nb of pixels
         waist_x = par.gauss_xwaist/scale_xy
         waist_y = par.gauss_ywaist/scale_xy
                                        ; x- and y-waists [px]
	 map = make_elong_gauss(np, waist_x, waist_y)
                                        ; compute 2D-gaussian map
      end

      2: restore, FILE=par.map          ; user-defined map case
                                        ;(map-file MUST be named "map",
                                        ;and must be written using SAVE)
   endcase 

   map = map/total(map)                 ; normalize map (integral=1)

endif else begin                        ; point-like source case
   map = 0.                             ;=> no map and no map scale
   scale_xy = 0.
endelse

; general stuff about Jonhson bands for nb of photons calculus:
;

; retrieve lambdas, widths and bands.
dummy   = n_phot(0., BAND=band, LAMBDA=lambda, WIDTH=width)
n_bands = n_elements(band)

; nb of photon and background vectors
n_phot     = fltarr(n_bands)
background = fltarr(n_bands)

; sky background nb of photons per band
for i = 0, n_bands-1 do $
      background[i]= (n_phot(0., BAND=band[i], BACK_MAG=par.skymag[i]))[1]

; pt-like LGS nb of photons
if (par.natural eq 0) then begin
   n_phot[n_bands-1] = (n_phot(par.starmag, BAND='V'))[0]
                                  ; BAND is 'V' and not 'Na'
                                  ;because starmag is an
                                  ;equivalent V-band mag.

; natural object nb of photons
endif else begin

   ; magnitudes => nb of photons for the natural object
   for i = 0, n_bands-1 do begin
      n_phot[i] = (n_phot(par.allstarmag[i], BAND=band[i]))[0]
   endfor

endelse

; init structure
init =                      $
   {                        $
   off_axis  : par.off_axis,$ ; [rd] ;angular pos. of
   pos_ang   : par.angle,   $ ; [rd] ;source wrt main tel.
   dist_z    : par.dist_z,  $ ; [m] dist. main tel.-object
                              ;(infinity if astro. object)
   map       : map,         $ ; source map (if any)
   scale_xy  : scale_xy,    $ ; map scale (if any) [rd/px]
   coord     : 0.,          $ ; [not used]
   scale_z   : 0.,          $ ; [not used]

   n_phot    : n_phot,      $ ; nbs of photons  [/s/m^2]
   background: background,  $ ; sky backgrounds [/s/m^2/arcsec^2]

   lambda    : lambda,      $ ; wavelengths [m]
   width     : width,       $ ; band-widths [m]
   constant  : par.constant $ ; constant (wrt time) source ?
   }

; output structure initialisation
out_src_t =                       $
   {                              $
   data_type  : info.out_type[0], $
   data_status: !caos_data.valid, $
   off_axis   : init.off_axis,    $
   pos_ang    : init.pos_ang,     $
   dist_z     : init.dist_z,      $
   map        : init.map,         $
   scale_xy   : init.scale_xy,    $
   coord      : init.coord,       $
   scale_z    : init.scale_z,     $
   n_phot     : init.n_phot,      $
   background : init.background,  $
   lambda     : init.lambda,      $
   width      : init.width,       $
   constant   : init.constant     $
   }

return, error
end