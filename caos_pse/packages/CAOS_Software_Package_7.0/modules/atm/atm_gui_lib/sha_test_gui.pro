; $Id: sha_test_gui.pro,v 7.0 2016/04/21 marcel.carbillet $
;+
; NAME:
;       sha_test_gui
;
; PURPOSE:
;       sha_test_gui generates a Graphical User Interface (GUI) that
;       is a sub-part of the ATM one.
;
; CATEGORY:
;       GUI
;
; CALLING SEQUENCE:
;       sha = sha_test_gui(sha, model, length, L0, GROUP_LEADER=group)
;
; INPUTS:
;       sha   : a priori nb of sub-harmonics to be added
;       model : atmospheric model
;       length: phase screen length [m]
;       L0    : outer-scale [m]
;
; OPTIONAL INPUTS:
;       none.
;
; KEYWORD PARAMETERS:
;       none.
;
; OUTPUTS:
;       sha : definitive nb of sub-harmonics to be added
;
; OPTIONAL OUTPUTS:
;       none.
;
; COMMON BLOCKS:
;       none.
;
; SIDE EFFECTS:
;       none.
;
; RESTRICTIONS:
;       none.
;
; PROCEDURE:
;       none.
;
; EXAMPLE:
;       ...
;
; PROGRAM MODIFICATION HISTORY:
;    program written: june 1998,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it].
;    modifications  : november 1998,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -display clarified.
;                   : november 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -adapted to version 2.0 (CAOS).
;
;-
;
;;;;;;;;;;;;;;;;;;;;;;;
; sha_test_gui event loop
;;;;;;;;;;;;;;;;;;;;;;;
;
pro sha_test_gui_event, event

common sha_test_gui_block, par, id

widget_control, event.id, GET_UVALUE=uvalue

case uvalue of

   'sha_max': begin
      widget_control, event.id, GET_VALUE=dummy
      if (dummy gt 11) then dummy = 11
      par.sha_max = dummy
      widget_control, id.sha_max, SET_VALUE=par.sha_max
      if (par.model eq 0) then par.L0 = !VALUES.F_INFINITY
      sha_test, alpha, beta, par.sha_max, par.length, L0=par.L0
      widget_control, id.plot_win, GET_VALUE=dummy
      wset, dummy
      if (par.model eq 1) then begin
         plot, alpha, YR=[min([min(alpha),min(beta)]),1.], $
            XTITLE="number of adding sub-harmonics", $
            YTITLE="___str.fct ratio   ...int.power ratio"
         oplot, beta, linestyle=1
      endif else plot, alpha, YR=[min(alpha),1.], $
                    XTITLE="number of adding sub-harmonics", $
                    YTITLE="structure function ratio"
      par.ratio = 0.
      par.ratio[0:par.sha_max,0] = alpha
      par.ratio[0:par.sha_max,1] = beta
      widget_control, id.ratio_table, /DELETE_COLUMNS
      widget_control, id.ratio_table, INSERT_COLUMNS=par.sha_max+1
      widget_control, id.ratio_table, $
         COLUMN_LABELS="n="+strtrim(indgen(par.sha_max+1),2)
      if (par.model eq 1) then $
         widget_control, id.ratio_table, SET_VALUE=par.ratio else $
         widget_control, id.ratio_table, SET_VALUE=par.ratio[*,0]

   end

   'sha': begin
      widget_control, event.id, GET_VALUE=dummy
      par.sha = dummy
   end

   'help': spawn, !caos_env.browser+" "+!caos_env.help

   'ok': widget_control, event.top, /DESTROY

endcase

end

;;;;;;;;;;;;;;;;;;;;;;;;;
; GUI generation code
;;;;;;;;;;;;;;;;;;;;;;;;;
;
function sha_test_gui, sha, model, length, L0, GROUP_LEADER=group

common sha_test_gui_block, par, id

sha_max = 11
ratio = fltarr(sha_max+1,2)

; parameters id. struc.

par = $
   {  $
   L0     : L0,      $
   length : length,  $
   model  : model,   $
   sha    : sha,     $
   sha_max: sha_max, $
   ratio  : ratio    $
   }

; widgets id. struc.

id = $
   { $
   sha_max    : 0L, $
   plot_win   : 0L, $
   ratio_table: 0L, $
   sha        : 0L  $
   }

; root base

modal = n_elements(group) ne 0
title = 'ATM sub-harmonics testing GUI'
root_base_id = widget_base(TITLE=title, MODAL=modal, /COL, GROUP_LEADER=group)

; parameter base

par_base_id = widget_base(root_base_id, /FRAME, /COL)

   sha_base_id = widget_base(par_base_id, /ROW)

      id.sha_max = cw_field(sha_base_id, $
         TITLE='max nb of sub-harmonics:', $
         VALUE=par.sha_max, UVALUE="sha_max", $
         /INTEGER, /RETURN_EVENTS)

      dummy = widget_label(sha_base_id, VALUE='(HIT RETURN !!)')

   id.plot_win = widget_draw(par_base_id, XSIZE=400, YSIZE=300)

   dummy = widget_label(par_base_id, $
      VALUE="values of structure function (@ length/2) ratio")

   if (par.model eq 1) then begin

      dummy = widget_label(par_base_id, $
         VALUE="   and integrated power ratio ")

      id.ratio_table = widget_table(par_base_id,              $
         ROW_LABELS=['struc. fct','int. power'],      $
         COLUMN_LABELS="n="+strtrim(indgen(par.sha_max+1),2), $
         VALUE=par.ratio, FORMAT='(F10.3)', $
         /SCROLL, X_SCROLL_SIZE=3, Y_SCROLL_SIZE=2)

   endif else id.ratio_table = widget_table(par_base_id,   $
      ROW_LABELS=['str.fct ratio'],                        $
      COLUMN_LABELS="n="+strtrim(indgen(par.sha_max+1),2), $
      VALUE=par.ratio[*,0], /SCROLL, X_SCROLL_SIZE=3, Y_SCROLL_SIZE=1)

   id.sha = cw_field(par_base_id,                           $
      TITLE='desired number of sub-harmonics to be added:', $
      VALUE=par.sha, UVALUE="sha",                          $
      /INTEGER, /ALL_EVENTS)

; button base for control buttons (standard buttons)

btn_base_id = widget_base(root_base_id, /FRAME, /ROW)
   dummy = widget_button(btn_base_id, VALUE="Help", UVALUE="help")
   ok_id = widget_button(btn_base_id, VALUE="Back to ATM parameter setting GUI", UVALUE="ok")
   if modal then widget_control, ok_id, /CANCEL_BUTTON

widget_control, root_base_id, /realize

widget_control, id.plot_win, GET_VALUE=dummy
wset, dummy
dummy = fltarr(sha_max+1)
if (par.model eq 1) then begin
   plot, dummy, YR=[0,1.], $
      XTITLE="number of adding sub-harmonics", $
      YTITLE="___str.fct ratio   ...int.power ratio"
   oplot, dummy, psym=1
endif else plot, dummy, YR=[0,1.], $
              XTITLE="number of adding sub-harmonics", $
              YTITLE="structure function ratio"

xmanager, 'sha_test_gui', root_base_id, GROUP_LEADER=group

return, par.sha
end