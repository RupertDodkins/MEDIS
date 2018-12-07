; $Id: atm_prog.pro,v 7.0 2016/04/21 marcel.carbillet $
;+
; NAME:
;    atm_prog
;
; PURPOSE:
;    atm_prog represents the program routine for the ATMosphere building (ATM)
;    module (see atm.pro's header --or file caos_help.html-- for details about
;    the module itself).
;
; CATEGORY:
;    module's program routine
;
; CALLING SEQUENCE:
;    error = atm_prog(          $
;                    out_atm_t, $
;                    par,       $
;                    INIT=init  $
;                    )
;
; INPUTS/OUTPUTS/KEYWORDS/ETC.:
;    see module help for a detailed description.
;
; ROUTINE MODIFICATION HISTORY:
;    program written: february-april 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it].
;    modifications  : may 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -integer/non-integer shift problem (par.cal=0 case) fixed.
;                     (see also atm_init.pro)
;                   : june 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -subharmonics screens ringing problem fixed (=> bilinear
;                     interpolation is now used instead of the fft one when
;                     non-integer shift is needed and subharmonics were added
;                     to the original fft screen). (see also atm_init)
;                   : september 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -ROUND instead of FIX (better works).
;                   : november 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -adapted to version 2.0 (CAOS).
;                   : December 2000
;                     Bruno  Femenia   (OAA) [bfemenia@arcetri.astro.it],
;                    -Zernike part enhanced.
;                   : February 2001,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -Zernike are valid only within a pupil
;
;-
;
FUNCTION atm_prog, out_atm_t, $
                   par,       $
                   INIT=init

; initialization of the error code: no error as default
error = !caos_error.ok

; program itself

IF (init.iter NE 0) THEN BEGIN              ; first iteration: the screens were
                                            ; already computed/read in atm_init.
                                            ; next iterations: read the screens
                                            ; from the cube file.

   IF (par.cal EQ 1) THEN BEGIN             ; statistical averaging

      IF (par.lps EQ 0) THEN BEGIN          ; already computed screens to read

         FOR i = 0, par.n_layers-1 DO BEGIN
            error = psg_read_cube(init.unit, init.header, screen)
            out_atm_t.screen[*,*,i] = screen
         ENDFOR

         screen = 0

      ENDIF ELSE BEGIN

         error = atm_psg(par, screens, coeff)
         out_atm_t.screen = screens

         screens          = 0

         IF par.method THEN BEGIN 
            init.coeff= coeff
            coeff     = 0
         ENDIF 

      ENDELSE

   ENDIF ELSE BEGIN                         ; temporal evolution

      FOR i = 0, par.n_layers-1 DO BEGIN    ; loop over layers

         IF (init.shift_flag[i] EQ 1) THEN BEGIN
                                            ; non-integer shift AND non-SHA case
                                            ;=> FFT interpolation
            out_atm_t.screen[*,*,i] =                    $
            shiftfft(init.screens_mem[*,*,i], init.iter* $
                     [init.delta_x[i], init.delta_y[i]])

         ENDIF ELSE IF (init.shift_flag[i] EQ 0) THEN BEGIN
                                            ; integer shift case
                                            ;=> no interpolation
            out_atm_t.screen[*,*,i] =                 $
              SHIFT(FLOAT(init.screens_mem[*,*,i])  , $
                    ROUND(init.iter*init.delta_x[i]), $
                    ROUND(init.iter*init.delta_y[i])  )

         ENDIF ELSE BEGIN                   ; non-integer shift AND SHA case
                                            ;=> bilinear interpolation
            out_atm_t.screen[*,*,i] =                              $
            BILINEAR(FLOAT(init.screens_mem[*,*,i]),               $
                     INDGEN(init.dim_x)-init.iter*init.delta_x[i], $
                     INDGEN(init.dim_y)-init.iter*init.delta_y[i]  )

         ENDELSE

      ENDFOR

   ENDELSE 

ENDIF 

init.iter = init.iter + 1L                  ; iteration number updating

out_atm_t.data_status = !caos_data.valid

FOR i = 0, par.n_layers-1 DO BEGIN          ; proper normalization of wf

   factor = (5E-7)/(2*!PI)                $
           *SQRT(par.weight[i])           $
           *(out_atm_t.scale/par.r0)^(5/6.)
           
   out_atm_t.screen[*,*,i] = factor*out_atm_t.screen[*,*,i]

   if par.method then begin
      init.coeff[*,i] = factor*init.coeff[*,i]
                                            ; in this case Zernike coeff.
                                            ; also need proper normalization.
      out_atm_t.screen[*,*,i] = init.pupil * out_atm_t.screen[*,*,i]
                                            ; Zernike are valid only in a pupil
   endif

ENDFOR  

return, error
END