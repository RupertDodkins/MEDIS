; $Id: evol_time.pro,v 7.0 2016/04/21 marcel.carbillet $
;
;+
; NAME:
;    evol_time
;
; PURPOSE:
;    evol_time computes the time evolution for a given turbulence profile,
;    and a given velocity profile.
;
; CATEGORY:
;    routine
;
; CALLING SEQUENCE:
;    t0 = evol_time(r0, v, Cn2)
;
; INPUTS:
;    r0 : Fried parameter [m].
;    v  : velocity profile [m/s].
;    Cn2: relative Cn2 profile.
;
; OPTIONAL INPUTS:
;    none.
;
; KEYWORD PARAMETERS:
;    none.
;
; OUTPUTS:
;    error code.
;
; OPTIONAL OUTPUTS:
;    none.
;
; COMMON BLOCKS:
;    none.
;
; SIDE EFFECTS:
;    none.
;
; RESTRICTIONS:
;    none.
;
; PROCEDURE:
;    none.
;
; EXAMPLE:
;    ...
;
; MODIFICATION HISTORY:
;    program written: october 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it].
;    modifications  : september 2004,
;                     Bruno Femenia (IAC) [bruno.femenia@iac.es]:
;                    -evolution time calculus corrected (sqrt(Cn2)). 
;
;-
;
function evol_time, r0, v, Cn2

sum = (total((abs(v))^(5/3.)*Cn2))^(3/5.)
if (sum eq 0.) then t0=!VALUES.F_INFINITY else t0=0.31*r0/float(sum)

return, t0
end