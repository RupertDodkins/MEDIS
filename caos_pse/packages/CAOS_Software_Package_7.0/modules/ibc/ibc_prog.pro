; $Id: ibc_prog.pro,v 7.0 2016/04/29 marcel.carbillet $
;
;+
; NAME:
;    ibc_prog
;
; PURPOSE:
;    ibc_prog represents the scientific algorithm for the Interferometric
;    Beam Combinator (IBC) module.
;
; CATEGORY:
;   module's program routine
;
; CALLING SEQUENCE:
;    error = ibc_prog(in1_wfp_t, $ ; 1st wfp_t input structure
;                     in2_wfp_t, $ ; 2nd wfp_t input structure
;                     out_wfp_t, $ ; wfp_t output structure
;                     par,       $ ; parameters structure
;                     INIT=init  ) ; initialisation structure
;
; INPUTS/OUTPUTS/KEYWORDS/ETC.:
;    see module help for a detailed description. 
;
; ROUTINE MODIFICATION HISTORY: 
;    program written: april-october 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it].
;                     Serge  Correia   (OAA) [correia@arcetri.astro.it].
;    modifications  : december 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -adapted to version 2.0 (CAOS).
;                   : february 2001,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -partial diff. piston correction now tasken into account.
;                   : january 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -screens better calculated (screen1+screen2).
;                    -definition of x0 and y0: use of "ceil" instead of "fix".
;                   : april 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;
;-
;
function ibc_prog, in1_wfp_t, $
                   in2_wfp_t, $
                   out_wfp_t, $
                   par,       $
                   INIT=init

; error code initialization
error = !caos_error.ok

; check the validity of the inputs
ds1 = in1_wfp_t.data_status
if ds1 eq !caos_data.wait then message, $
   'the 1st input cannot have a wait data status.'
ds2 = in2_wfp_t.data_status
if ds2 eq !caos_data.wait then message, $
   'the 2nd input cannot have a wait data status.'

; PROGRAM ITSELF
;

; initialize total screen
dim_x   = (size(out_wfp_t.screen))[1]
dim_y   = (size(out_wfp_t.screen))[2]
screen1 = fltarr(dim_x, dim_y)
screen2 = fltarr(dim_x, dim_y)

; take off the part of the local pistons requested

idx = where(in1_wfp_t.pupil gt 0.5, dummy)
piston_1 = total(double(in1_wfp_t.screen[idx]))/dummy
in1_wfp_t.screen = in1_wfp_t.screen - (1.-par.residual)*piston_1

idx = where(in2_wfp_t.pupil gt 0.5, dummy)
piston_2 = total(double(in2_wfp_t.screen[idx]))/dummy
in2_wfp_t.screen = in2_wfp_t.screen - (1.-par.residual)*piston_2

print, " "
print, "IBC:"
print, "piston on 1st pupil: ", piston_1
print, "piston on 2nd pupil: ", piston_2
print, "=> input differential piston: ", piston_2-piston_1

print, " "
print, "residual piston on 1st pupil: ", par.residual*piston_1
print, "residual piston on 2nd pupil: ", par.residual*piston_2
print, "=> output differential piston: ", par.residual*(piston_2-piston_1)
 
; put the wf from the 1st telescope in the whole interferometer wf
x0 = ceil(init.x1 - init.np1/2.)
y0 = ceil(init.y1 - init.np1/2.)
screen1[x0, y0] = in1_wfp_t.screen * in1_wfp_t.pupil

; put the wf from the 2nd telescope in the whole interferometer wf
x0 = ceil(init.x2 - init.np2/2.)
y0 = ceil(init.y2 - init.np2/2.)
screen2[x0, y0] = in2_wfp_t.screen * in2_wfp_t.pupil

; multiply the whole phase screen by the diluted pupil
out_wfp_t.screen = screen1 + screen2

; validate the data status
out_wfp_t.data_status = !caos_data.valid


; back to calling program
return, error
end