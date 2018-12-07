; $Id: atm_psg_zer.pro,v 7.0 2016/04/21 marcel.carbillet$
;+
; NAME:
; atm_psg_zer
;
; Zernike phase screens generation.
; See atm_psg help.
; (version modified by BF-March 2001)
;-
;
function atm_psg_zer, par, wave_screen, coeff

common psg_seed_block, seed1, seed2

error = 0L
np    = par.dim

restore, par.add_covmat              ; covariance matrix to be
                                     ; read (4186 Zern. pol. in default file)
l_dim    = l_sprs.ija[0] - 2
jmin     = 2L
sup_jmax = l_dim + jmin - 1          ;Maximum Zernike polynomial considered in
                                     ;     covariance matrix in par.add_covmat.
sup_nmax = LONG(SQRT(2*sup_jmax)-1)  ;Radial order corresponding to sup_jmax.

IF (sup_nmax GT 90L) THEN BEGIN                             ;In original version 
   dummy =                                                $ ; A. Riccardi set 
     DIALOG_MESSAGE('Max. number of polynomials is too ' +$ ; this limit.Keeping
                    'large:',DIALOG_PARENT=atm_gui,/ERROR,$ ; it.
                    TITLE= 'Number of Zernike polynomials')
   error = -1
   return, error
ENDIF 
             

nmax  =  par.zern_rad_degree
IF ( (nmax GT sup_nmax) OR (nmax LT 1) ) THEN BEGIN 
   dummy =                                                          $
     DIALOG_MESSAGE(['par specifies that COVARIANCE matrix for the',$
                     'Zernike modes is read from file:            ',$
                     ''                                            ,$
                     '  '+par.add_covmat                           ,$
                     ''                                            ,$
                     'for which maximum Zernike radial degree MUST',$
                     'BE => 1 and less or equal to' +               $
                     STRCOMPRESS(sup_nmax)],                        $
                    TITLE='ATM error', DIALOG_PARENT=atm_gui,/ERROR)
   error = -1
   return, error
ENDIF 

make_xy, np, 1D0, r, theta, /DOUBLE, /POLAR
make_xy, np, 1D0, rq, /DOUBLE, /POLAR, /QUARTER

mmax  = nmax
jmax  = (nmax+1)*(nmax+2)/2
coeff = (randomn_covar(l_sprs,/SPARSE,SEED=seed1))[0:jmax-2]
wave_screen = dblarr(np, np)

for m = mmax, 1, -1 do begin

   for n = m, nmax, 2 do begin

      zr        = zern_jradial(n, m, rq, jp1, jp2)
      zr        = [ [rotate(zr,2), rotate(zr,7)], $
                    [rotate(zr,5), zr          ]  ]
      lower_idx = zern_index(n,m)
      
      if lower_idx mod 2 then begin
         
         sin_idx = lower_idx
         cos_idx = lower_idx+1
         
      endif else begin
         
         cos_idx = lower_idx
         sin_idx = lower_idx+1
         
      endelse
      
      wave_screen = temporary(wave_screen) + $
        ( coeff(cos_idx-jmin) * cos(m*theta) $
          +coeff(sin_idx-jmin) * sin(m*theta) ) $
        * sqrt(2D0*(n+1D0)) * zr
   endfor
   
endfor

;  m=0 case : rotationally symmetric Zernike polynomials

wave_m0 = rq * 0.0

for n = 2, nmax, 2 do begin
   
   zr      = zern_jradial(n, 0, rq, jp1, jp2)
   wave_m0 = temporary(wave_m0) + sqrt(n+1D0) $
     * coeff(zern_index(n,0)-jmin) * zr
   
endfor

wave_screen = temporary(wave_screen) + $
  [ [rotate(wave_m0,2), rotate(wave_m0,7)], $
    [rotate(wave_m0,5), wave_m0          ] ]


wave_screen = 2*!PI * np^(5/6.) * float(temporary(wave_screen))
                                   ; convert wave screen to
                                   ; phase screen with 1 px/r0

coeff = 2*!PI * np^(5/6.) *coeff   ;Apply same conversion to coefficients!!

return, error                      ; back to calling program...
end