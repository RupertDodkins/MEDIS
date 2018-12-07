; $Id: timing.pro,v 1.2 2003/06/10 18:29:27 riccardi Exp $ 
; 
; A. Riccardi, Dipartimento di Astronomia di Firenze (Italy). 
; riccardi@arcetri.astro.it
; Please, send me a message if you modify this code. 

function timing, t
;+ 
; NAME: 
;       TIMING 
; 
; PURPOSE: 
;       This function compute time elapsed since last calling. 
; 
; CATEGORY: 
;       Utilities. 
; 
; CALLING SEQUENCE: 
;  
;       Result = TIMING(T) 
; 
; INPUTS: 
;       T:      long integer variable. System time returned by last calling
;               of TIMING.
; 
; OUTPUTS: 
;       Result: float. Time elapsed since last calling in minutes. If
;               T is undefined, Result is -1..
;
;       T:      long integer. Updated to current system time for future use.
; 
; RESTRICTIONS: 
;       If T variable is modified since last calling, the Result is uncorrect. 
; 
; EXAMPLE: 
;       Print the time needed to execute a sequence of stantments:
;
;       Dummy = TIMING(T)
;       ...
;       ...
;       ...
;       PRINT, TIMING(T)
; 
; MODIFICATION HISTORY: 
;       Written by:     A. Riccardi; Month, 1995. 
;       July, 1994      Any additional mods get described here.  Remember to 
;                       change the stuff above if you add a new keyword or 
;                       something! 
;- 
	st=size(t)
	if (n_elements(t) eq 0) then begin
		t=systime(1)
		return, -1.
	endif else begin
		t1=t
		t=systime(1)
		return, (t-t1)/60.
	endelse
end

