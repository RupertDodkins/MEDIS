; $Id: mult_beep.pro,v 1.3 2003/06/10 18:29:27 riccardi Exp $

pro mult_beep, times, DELAY=delay

if n_elements(delay) eq 0 then delay=0.3
if n_params() eq 0 then times=1

beep
for i=1,times-1 do begin
	wait, delay
	beep
endfor

end
