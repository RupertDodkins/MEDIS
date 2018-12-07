; $Id: trans_tab_gui.pro,v 7.0 2016/04/21 marcel.carbillet $
;
;+
; NAME:
;    trans_tab_gui
;
; PURPOSE:
;    trans_tab_gui generates a Graphical User Interface (GUI) that
;    is a sub-part of the ATM one.
;
; CATEGORY:
;    GUI
;
; CALLING SEQUENCE:
;    dummy = trans_tab_gui(ref_value,        $
;                          lambda_ref,       $
;                          power_law,        $
;                          title,            $
;                          sub_title,        $
;                          GROUP_LEADER=group)
;
; INPUTS:
;    ref_value : reference value (@lambda_ref) from which to deduce the
;                parameter at the other wavelengths (considering Johnson
;                special Na-band).
;    lambda_ref: reference wavelength [m].
;    power_law : the power law at which the transform has to be done.
;    title     : the title chosen for the sub-GUI. 
;    sub_title : the sub-title chosen for the table within the sub-GUI. 
;
; OPTIONAL INPUTS: 
;    none.
;
; KEYWORD PARAMETERS:
;    none.
;
; OUTPUTS:
;    error code.
;
; OPTIONAL OUTPUTS:
;    none.
;
; COMMON BLOCKS:
;    none.
;
; SIDE EFFECTS:
;    none.
;
; RESTRICTIONS:
;    none.
;
; PROCEDURE:
;    none.
;
; EXAMPLE:
;    ...
;
; PROGRAM MODIFICATION HISTORY:
;    program written: october 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it].
;    modifications  : november 1999,
;                     Marcel carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -adapted to version 2.0 (CAOS).
;
;-
;
;;;;;;;;;;;;;;;;;;;;;;;
; GUI event loop
;;;;;;;;;;;;;;;;;;;;;;;
;
pro trans_tab_gui_event, event

widget_control, event.id, GET_UVALUE=uvalue  

case uvalue of
                   
   'help': spawn, !caos_env.browser+" "+!caos_env.help

   'ok': widget_control, event.top, /DESTROY

endcase

end       

;;;;;;;;;;;;;;;;;;;;;;;;;
; GUI generation code
;;;;;;;;;;;;;;;;;;;;;;;;;
;                                 
function trans_tab_gui, ref_value, lambda_ref, power_law, title, sub_title, $
                     GROUP_LEADER=group

error = !caos_error.ok

modal = n_elements(group) ne 0
root_base_id = widget_base(TITLE=title, MODAL=modal, /COL, GROUP_LEADER=group)

; parameter base

par_base_id = widget_base(root_base_id, /FRAME, /COL)

   dummy = n_phot(0., BAND=band, LAMBDA=lambda)
   tab = widget_table(par_base_id,                                   $
                      ROW_LABELS=[sub_title],                        $
                      COLUMN_LABELS=band,                            $
                      VALUE=ref_value*(lambda/lambda_ref)^power_law, $
                      YSIZE=1                                        ) 

; standard buttons base

btn_base_id = widget_base(root_base_id, /FRAME, /ROW)

   dummy = widget_button(btn_base_id,  $
                         VALUE="Help", $
                         UVALUE="help" )
   ok_id = widget_button(btn_base_id,                               $
                         VALUE="Back to ATM parameter setting GUI", $
                         UVALUE="ok"                                )
   if modal then widget_control, ok_id, /CANCEL_BUTTON

widget_control, root_base_id, /REALIZE
xmanager, 'trans_tab_gui', root_base_id, GROUP_LEADER=group

return, error
end