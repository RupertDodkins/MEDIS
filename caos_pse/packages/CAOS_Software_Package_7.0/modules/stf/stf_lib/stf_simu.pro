; $Id: stf_simu.pro,v 7.0 2016/05/19 marcel.carbillet $
;+
; NAME:
;    stf_simu.pro
;
; PURPOSE:
;    function for the STF module that computes the simulated structure function.
;
; CATEGORY:
;    ...
;
; CALLING SEQUENCE:
;    ...
;
; INPUTS/OUTPUTS/KEYWORDS/ETC.:
;    ...
;
; ROUTINE MODIFICATION HISTORY: 
;    routine written: july 1998,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it].
;    modifications  : may 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -modified.
;                   : december 1999-may 2000,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -adapted to version 2.0 (CAOS).
;                   : may 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;-
;
function stf_simu, screen, PUPIL=pupil

dim = (size(screen))[1]                       ; screen dim. [px]

if keyword_set(pupil) then begin
   np    = (size(pupil))(1)                   ; pupil dim. [px]
   npobs = floor(total(pupil[np/2, *] eq 0.)) ; obstruction dim. [px]
endif else begin
   np = dim & npobs = 0                       ; null obstruction
   pupil = fltarr(np,np)+1.                   ; make square pupil
endelse

npstruc = (np-npobs)/2

scre  = screen[(dim-np)/2:(dim+np)/2-1, (dim-np)/2:(dim+np)/2-1] * pupil
                                              ; take usefull part of screen
scre  = (scre - total(scre)/total(pupil ne 0.)) * pupil
                                              ; screen's mean to zero
struc = .125 * (                                                              $
    (scre[0         , np/2-1    ] - scre[0:npstruc-1    , np/2-1         ])^2 $
   +(scre[0         , np/2      ] - scre[0:npstruc-1    , np/2           ])^2 $
   +(scre[np-npstruc, np/2-1    ] - scre[np-npstruc:np-1, np/2-1         ])^2 $
   +(scre[np-npstruc, np/2      ] - scre[np-npstruc:np-1, np/2           ])^2 $
   +(scre[np/2-1    , 0         ] - scre[np/2-1         , 0:npstruc-1    ])^2 $
   +(scre[np/2      , 0         ] - scre[np/2           , 0:npstruc-1    ])^2 $
   +(scre[np/2-1    , np-npstruc] - scre[np/2-1         , np-npstruc:np-1])^2 $
   +(scre[np/2      , np-npstruc] - scre[np/2           , np-npstruc:np-1])^2 $
               )
                                              ; compute structure function on a
                                              ; cross of the pupiled screen.
                                              ; (example of where is made the
                                              ;  calculus on a 16*16 screen with
                                              ;  a 4*4 obscuration:
                                              ;
                                              ;  . . . . . . . 1 2 . . . . . . .
                                              ;  . . . . . . . 1 2 . . . . . . .
                                              ;  . . . . . . . 1 2 . . . . . . .
                                              ;  . . . . . . . 1 2 . . . . . . .
                                              ;  . . . . . . . 1 2 . . . . . . .
                                              ;  . . . . . . . 1 2 . . . . . . .
                                              ;  . . . . . . . . . . . . . . . .
                                              ;  8 8 8 8 8 8 . . . . 3 3 3 3 3 3
                                              ;  7 7 7 7 7 7 . . . . 4 4 4 4 4 4
                                              ;  . . . . . . . . . . . . . . . .
                                              ;  . . . . . . . 6 5 . . . . . . .
                                              ;  . . . . . . . 6 5 . . . . . . .
                                              ;  . . . . . . . 6 5 . . . . . . .
                                              ;  . . . . . . . 6 5 . . . . . . .
                                              ;  . . . . . . . 6 5 . . . . . . .
                                              ;  . . . . . . . 6 5 . . . . . . .
                                              ;
                                              ; the structure function is
                                              ; calculated for the 8 groups of
                                              ; pixels (forming 8 segments) here
                                              ; above. its range is here, if the
                                              ; screen are, e.g., 8m long (i.e
                                              ; 0.5m per pixel), from 0 to 2.5m.
return, struc
end
