; $Id: src_gen_default.pro,v 7.0 2016/05/19 marcel.carbillet $
;+
; NAME:
;    src_gen_default
;
; PURPOSE:
;    src_gen_default generates the default parameter structure
;    for the SRC module and save it in the rigth location.
;    (see src.pro's header --or file caos_help.html-- for details
;     about the module itself).
;
; CATEGORY:
;    module's utility routine
;
; CALLING SEQUENCE:
;       src_gen_default
;
; ROUTINE MODIFICATION HISTORY:
;    program written: june 1998,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it].
;    modifications  : february 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -a few modifications for version 1.0.
;                   : march 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -fixed sky background stuff.
;                   : march 1999,
;                     Bruno Femenia (OAA) [bfemenia@arcetri.astro.it]:
;                    -all angles in double precision.
;                   : march 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -added new 2D-object calculation feature.
;                   : may 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -fixed default file address problem.
;                   : december 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -adapted to version 2.0 (CAOS).
;                   : september 2001,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -tag "starmagall" added
;                     (permitting to consider each band source mag separately,
;                     as for the sky background)
;                   : january 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -"mod_type"->"mod_name"
;                     (for version 4.0 of the whole Software System CAOS").
;                   : may 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;-
;
pro src_gen_default

info   = src_info()
module = gen_def_module(info.mod_name, info.ver)

; get the sky background default magnitude in each pre-defined band
; (see .../lib/n_phot.pro)
dummy = n_phot(0., BACK_MAG=skymag)

; get the source default magnitudes in each pre-defined band
; (see .../lib/n_phot.pro and .../lib/spec2mag)
dummi        = n_phot(0., BAND=band_table)
spec_type_nb = 12   ; A0 spectral type
Vmag         = 10.
n_bands      = n_elements(band_table)
starmagall   = fltarr(n_bands)
dummy        = spec2mag('A0', 0., band_table[0], SPEC_TAB=spec_type)
for i=0,n_bands-1 do starmagall[i]=spec2mag(spec_type[spec_type_nb], Vmag, band_table[i])

; get the map file address
map = filepath("my_spot.sav", ROOT=!caos_env.modules,        $
               SUB=[info.pack_name+!caos_env.delim+"modules" $
                  +!caos_env.delim+"src"+!caos_env.delim+"src_data"])

; parameter structure
par =   $
   {    $
   src, $
   module      : module,           $
   off_axis    : 0D,               $ ; off-axis angle [rd]
   angle       : 0D,               $ ; position angle [rd]
   dist_z      : 90E3,             $ ; source distance [m]
   starmag     : Vmag,             $ ; source V-magnitude
   allstarmag  : starmagall,       $ ; all source magnitudes
   skymag      : skymag,           $ ; sky magnitudes
   spec_type   : spec_type_nb,     $ ; spectral type
   extended    : 0,                $ ; 0=point-like object, 1=2D-object.
   map_type    : 0,                $ ; 0=uniform disc map, 1=gaussian map,
			             ;3=user-defined map.
   disc        : 1D/3600*!DtoR,    $ ; uniform disc radius [rd]
   gauss_size  : 6D/3600*!DtoR,    $ ; gaussian map angular size [rd]
   gauss_xwaist: 1D/3600*!DtoR,    $ ; gaussian x-waist [rd]
   gauss_ywaist: 1D/3600*!DtoR,    $ ; gaussian y-waist [rd]
   natural     : 1,                $ ; 0=LGS, 1=natural object.
   map         : map,              $ ; user-defined map file address
   mapscale    : .1D/3600*!DtoR,   $ ; map file scale [rd/px]
   constant    : 1B                $ ; constant (wrt time) source
   }

save, par, FILENAME=info.def_file

end