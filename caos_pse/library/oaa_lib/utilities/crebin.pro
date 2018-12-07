; $Id: crebin.pro,v 1.2 2003/06/10 18:29:25 riccardi Exp $
;+
; CREBIN
;
; The function is a wrapper of the REBIN function that is also able to manage
; complex and dcomplex variables. If the array is complex/dcomplex, CREBIN returns a
; complex/dcomplex array having a rebinned real and imaginary part. The input array
; cannot have more then 8 dimensions.
;
; SYNTAX
;
; Same as REBIN
;
; HISTORY
;
; 24 Mar 2002, written by A. Riccardi
; Osservatorio Astrofisico di Arcetri, ITALY
; riccardi@arcetri.astro.it
;-

function crebin, a, n1, n2, n3, n4, n5, n6, n7, n8, _REF_EXTRA=e

case size(a,/TYPE) of
	6: $
		case n_params() of
			2: return, complex(rebin(float(a),n1),rebin(imaginary(a),n1,_EXTRA=e))
			3: return, complex(rebin(float(a),n1,n2),rebin(imaginary(a),n1,n2,_EXTRA=e))
			4: return, complex(rebin(float(a),n1,n2,n3),rebin(imaginary(a),n1,n2,n3,_EXTRA=e))
			5: return, complex(rebin(float(a),n1,n2,n3,n4),rebin(imaginary(a),n1,n2,n3,n4,_EXTRA=e))
			6: return, complex(rebin(float(a),n1,n2,n3,n4,n5),rebin(imaginary(a),n1,n2,n3,n4,n5,_EXTRA=e))
			7: return, complex(rebin(float(a),n1,n2,n3,n4,n5,n6),rebin(imaginary(a),n1,n2,n3,n4,n5,n6,_EXTRA=e))
			8: return, complex(rebin(float(a),n1,n2,n3,n4,n5,n6,n7),rebin(imaginary(a),n1,n2,n3,n4,n5,n6,n7,_EXTRA=e))
			9: return, complex(rebin(float(a),n1,n2,n3,n4,n5,n6,n7,n8),rebin(imaginary(a),n1,n2,n3,n4,n5,n6,n7,n8,_EXTRA=e))
			else: message, "Too many dimensions"
		endcase

	9: $
		case n_params() of
			2: return, dcomplex(rebin(double(a),n1),rebin(imaginary(a),n1,_EXTRA=e))
			3: return, dcomplex(rebin(double(a),n1,n2),rebin(imaginary(a),n1,n2,_EXTRA=e))
			4: return, dcomplex(rebin(double(a),n1,n2,n3),rebin(imaginary(a),n1,n2,n3,_EXTRA=e))
			5: return, dcomplex(rebin(double(a),n1,n2,n3,n4),rebin(imaginary(a),n1,n2,n3,n4,_EXTRA=e))
			6: return, dcomplex(rebin(double(a),n1,n2,n3,n4,n5),rebin(imaginary(a),n1,n2,n3,n4,n5,_EXTRA=e))
			7: return, dcomplex(rebin(double(a),n1,n2,n3,n4,n5,n6),rebin(imaginary(a),n1,n2,n3,n4,n5,n6,_EXTRA=e))
			8: return, dcomplex(rebin(double(a),n1,n2,n3,n4,n5,n6,n7),rebin(imaginary(a),n1,n2,n3,n4,n5,n6,n7,_EXTRA=e))
			9: return, dcomplex(rebin(double(a),n1,n2,n3,n4,n5,n6,n7,n8),rebin(imaginary(a),n1,n2,n3,n4,n5,n6,n7,n8,_EXTRA=e))
			else: message, "Too many dimensions"
		endcase

	else: $
		case n_params() of
			2: return, rebin(a,n1,_EXTRA=e)
			3: return, rebin(a,n1,n2,_EXTRA=e)
			4: return, rebin(a,n1,n2,n3,_EXTRA=e)
			5: return, rebin(a,n1,n2,n3,n4,_EXTRA=e)
			6: return, rebin(a,n1,n2,n3,n4,n5,_EXTRA=e)
			7: return, rebin(a,n1,n2,n3,n4,n5,n6,_EXTRA=e)
			8: return, rebin(a,n1,n2,n3,n4,n5,n6,n7,_EXTRA=e)
			9: return, rebin(a,n1,n2,n3,n4,n5,n6,n7,n8,_EXTRA=e)
			else: message, "Too many dimensions"
		endcase
endcase
end
