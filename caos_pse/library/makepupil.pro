; $Id makepupil.pro, for CAOS Library v 5.4, 2014/02/23 marcel.carbillet$
;+
; NAME:
;    makepupil.pro
;
; PURPOSE:
;    this module creates a matrix representing the pupil of the telescope.
;    It makes an annular pupil of the right size with values of 1 inside
;    and 0 outside of the pupil.
;
; CATEGORY:
;    CAOS library routine.
;
; CALLING SEQUENCE:
;    pupil = makepupil_rec(dim_x,     $
;                          diam,      $
;                          eps,       $
;                          XC=xc,     $
;                          YC=yc,     $
;                          DIM_Y=dim_y)
;
; INPUTS:
;    dim_x = x-dimensions of the simulation matrix to generate
;            [integer or long, in sampling points]
;    dim_y = y-dimensions (if different from dim_x)
;            [integer or long, in sampling points]
;    diam  = actual linear dimension of the pupil in the simulation
;            [integer or long, in sampling points]
;    eps   = relative diameter of the central obsturation
;            [float, <1, fraction of diam]
;    xc    = keywords giving the x-position of the center of the pupil
;            [float, <dim_x, default value = dim_x-1/2]
;    yc    = keywords giving the y-position of the center of the pupil
;            [float, <dim_y, default value = dim_y-1/2]
;
; OUTPUT:
;    pupil = the matrix containing the pupil [bytes, dim_x x dim_y]
;
; COMMON BLOCKS:
;    none.
;
; CALLED NON-IDL FUNCTIONS:
;    none.
;
; MODIFICATION HISTORY:
;    program written: december 1998,
;                     Francoise Delplancke (ESO) [fdelplan@eso.org].
;                     (from Francois Rigaut's program simul.pro,v3.0)
;    modifications  : november 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -deals now with rectangle arrays.
;                    -a few other minor modifications.
;                   : march-may 2012,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -now centered on the real center of the array
;                    (odd dimension: in between the 4 central pixels),
;                    (even dimension: on the central pixel).
;                    -other minor revisions.
;                   : february 2014,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -help clarified (cobs=>eps).
;
;-
;
FUNCTION makepupil, dim_x, diam, eps, XC=xc, YC=yc, DIM_Y=dim_y

; by default the pupil is centered on the center of the array
; (i.e. NOT on a pixel for a square array…)
if not keyword_set(XC)    then xc    = (dim_x-1L)/2.
if not keyword_set(DIM_Y) then dim_y = dim_x
if not keyword_set(YC)    then yc    = (dim_y-1L)/2.

x = rebin(findgen(dim_x), dim_x, dim_y)            - xc
y = transpose(rebin(findgen(dim_y), dim_y, dim_x)) - yc

dummy = sqrt(x^2.+y^2.)/(diam/2.)

; pupil array is 1 under the pupil and 0 elsewhere
pupil = (dummy lt 1.) and (dummy ge eps)

; return the pupil array and back to calling program
return, pupil
end
