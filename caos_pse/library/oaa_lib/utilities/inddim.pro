; $Id: inddim.pro,v 1.1 2004/04/14 10:13:24 marco Exp $
;
;+
; NAME:
;	INDDIM
;
; PURPOSE:
; 	Format change array index from linear to 2D dimensional
;
; CATEGORY:
;	Array routine
;
; CALLING SEQUENCE:
; 	vect = indimm(index, dim)
;
; INPUTS:
; 	index: index linear vector
;	dim: dim 2D square (only scalar)
;
; OUTPUTS:
;	vect: array with 2D coordinates
;
; KEYWORDS:
;	TRANSPOSE: give the vectors in a tranpsose way
;
; MODIFICATION HISTORY:
; 	Written by:	Xompero Marco, Mar 2003.
;-
function inddim, index, dim, TRANSPOS=transpos
	sizei = size(index)
	index_length = sizei[1]
	vect = dblarr(index_length,2)
	if keyword_set(transpos) then vect = [transpose(index mod dim[0]),transpose(floor(index/dim[0]))] $
	else vect = [[index mod dim[0]],[floor(index/dim[0])]]
	return, vect
end