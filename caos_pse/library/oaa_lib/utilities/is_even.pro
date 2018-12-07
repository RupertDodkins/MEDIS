; $Id: is_even.pro,v 1.2 2003/06/10 18:29:26 riccardi Exp $           
;           
; A. Riccardi, Dipartimento di Astronomia di Firenze (Italy).         
; e-mail address: riccardi@arcetri.astro.it           
; Please, send me a message if you modify this code.    
    
    
function is_even, value         
;+           
; NAME:           
;       IS_EVEN           
;           
; PURPOSE:          
;       IS_EVEN returns true (1B) if its argument is even.
;		False (0B) otherwais.          
;
; CATEGORY:           
;       Utility          
;           
; CALLING SEQUENCE:           
;       Result = IS_EVEN(Value)           
;           
; INPUTS:
;		Value:	scalar or array.
;
; OUTPUT:
;		Result: byte scalar or array (same size of Value).
;           
; MODIFICATION HISTORY:           
;       Written by:     A. Riccardi; March, 1995.           
;-          
    return, byte(not(value mod 2B)) mod 2B
end         
