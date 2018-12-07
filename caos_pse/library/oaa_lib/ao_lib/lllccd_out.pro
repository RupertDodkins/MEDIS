; $Id: lllccd_out.pro,v 1.4 2003/06/10 18:29:24 riccardi Exp $
;+
;
; prob = lllccd_out(input_phe, r, m[, SEED=seed])
;
; input_phe: integer matrix: detected photo-electrons before amplification
; g        : float scalar: amplification gain. g=m^r where r is the number of
;            amplification registers and m is the multiplication factor per
;            register (m>=1, tipically m=1.01)
;
; SEED:  seed to be used in randomn call. On output it contains the seed returned
;        by the randomn call.
;
; MODIFICATION HISTORY:
; 21 March 2003. Written by A. Riccardi, INAF-OAA, Italy
;                riccardi@arcetri.astro.it
; 22 March 2003. by AR: output converted to long and offset=input added
;                It takes into account the detected
;-

function lllccd_out, input, g, SEED=seed

ni=n_elements(input)
output=input
idx=where(input ne 0, count)
if count ne 0 then $
	for i=0,count-1 do $
		output[idx[i]]=output[idx[i]]+g*randomn(seed, GAMMA=input[idx[i]], /DOUBLE)
return, long(output)

end
