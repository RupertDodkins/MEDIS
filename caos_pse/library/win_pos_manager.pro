; $Id: win_pos_manager.pro,v 1.1.1.1 2003/03/07 10:46:20 marcel Exp $
; +
; NAME:
;    win_pos_manager
;
; PURPOSE:
;    window positionning management.
;
; MODIFICATION HISTORY:
;    program written: march 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it].
;                     (within module DIS of Software Package CAOS)
;    modifications  : may 1999,
;                     Armando Riccardi (OAA) [riccardi@arcetri.astro.it]:
;                    -windows stuff.
;                   : november 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it].
;                    -adapted to version 2.0 (CAOS).
;                   : february 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it].
;                    -moved to common library "caos/lib" (became common
;                     to two packages -- CAOS_4.0 and AIRY_2.0).
;
; -
;
function win_pos_manager, win_index               $ ; new window index
                        , win_xsize               $ ; new window x-size [px]
                        , win_ysize               $ ; new window y-size [px]
                        , TITLE=win_title         $ ; new window title
                        , SCREEN_SIZE=screen_size   ; screen size [px,px]

; result returned is an error code
error = !caos_error.ok                       ; initialize error code

; window title definition
if (n_elements(win_title) eq 0) then win_title=""

; screen size definition
if (n_elements(screen_size) eq 0) then device, GET_SCREEN_SIZE=screen_size
screen_xsize = screen_size[0]       ; screen x-size [px]
screen_ysize = screen_size[1]       ; screen y-size [px]

; systematic offsets while window creation
offset_x = 0
offset_y = 23

; screen's origin for window positionning
zero_x = 0
case !D.NAME of
    'X'  : zero_y = screen_ysize-(win_ysize+offset_y)
    'WIN': zero_y = offset_y
    else : zero_y = screen_ysize-(win_ysize+offset_y)
endcase

; window positioning
if (!D.WINDOW ne -1L) then begin    ; a window is already opened

   device, GET_WINDOW_POSITION=win_pos
                                    ; get position of previous window
   xpos = win_pos[0] + !D.X_SIZE + offset_x
  case !D.NAME of
    'X'  : ypos = win_pos[1] + offset_y
    'WIN': ypos = win_pos[1] - !D.Y_SIZE
    else : ypos = win_pos[1] + offset_y
  endcase

   if (xpos+win_xsize gt screen_xsize) then begin
                                    ; x-size is too large=>will put it under
      xpos = zero_x
      case !D.NAME of
        'X'  : ypos = ypos - (!D.Y_SIZE + offset_y)
        'WIN': ypos = ypos + !D.Y_SIZE + offset_y
        else : ypos = ypos - (!D.Y_SIZE + offset_y)
      endcase

      case !D.NAME of
          'X': if (ypos lt 0) then ypos = zero_y
          'WIN': if (ypos gt screen_ysize) then ypos = zero_y
          else: if (ypos lt 0) then ypos = zero_y
      endcase
    endif

endif else begin                    ; this is the first opened window
                                    ; =>will put it at the screen's origin point
   xpos = zero_x
   ypos = zero_y

endelse

window, /FREE           $           ; create window
      , XSIZE=win_xsize $
      , YSIZE=win_ysize $
      , TITLE=win_title $
      , XPOS=xpos       $
      , YPOS=ypos

win_index = !D.WINDOW

return, error                       ; back to calling program
end
