; $Id: delay_tf.pro,v 1.1 2003/03/04 17:42:15 riccardi Exp $

;+
;
; DELAY_TF
;
; Complex transfer function corresponding to a pure delay time_delay
; at the frequency values stored in the freq_vec vector
;
; tf = delay_tf(freq_vec, time_delay)
;
; MODIFCATION HISTORY:
;
;   Written by: A. Riccardi, Osservatorio Astrofisico di Arcetri, Italy
;-

function delay_tf, frec_vec, time_delay
	iu=complex(0.0,1.0)
	s=iu*2*!pi*frec_vec

	return, exp(-s*double(time_delay))
end
