; $Id: zern_degree.pro,v 1.2 2003/06/10 18:29:24 riccardi Exp $           
;           
; A. Riccardi, Dipartimento di Astronomia di Firenze (Italy).         
; e-mail address: riccardi@arcetri.astro.it           
; Please, send me a message if you modify this code.    
    
    
pro zern_degree, j, n, m                                  
;+           
; NAME:           
;       ZERN_DEGREE           
;           
; PURPOSE:          
;       ZERN_DEGREE calculates the radial degree n and azimuthal  
;       frequency m of Zernike polynomial of index j.   
;           
; CATEGORY:           
;       Optics.          
;           
; CALLING SEQUENCE:           
;            
;       ZERN_DEGREE, J, N, M           
;           
; MODIFICATION HISTORY:           
;       Written by:     A. Riccardi; March, 1995.           
;-          
   n = long(0.5D0*(sqrt(8D0*j-7)-3))+1     
   cn = n*(n+1)/2+1     
   if is_even(n) then m = long(j-cn+1)/2*2 $     
   else m = long(j-cn)/2*2+1     
end  
