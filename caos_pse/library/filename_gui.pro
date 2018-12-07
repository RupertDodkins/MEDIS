; $Id: filename_gui.pro,v 1.1.1.1 2003/03/07 10:46:19 marcel Exp $
;+
; NAME:
;    filename_gui
;
; PURPOSE:
;    filename_gui generates a Graphical User Interface (GUI) for
;    the compound widget cw_filename.
;
; CATEGORY:
;    GUI
;
; CALLING SEQUENCE:
;    filename = filename_gui(def_filename,       $
;                            title,              $      
;                            GROUP_LEADER=group, $
;                            ...)
;
; INPUTS:
;    def_filename: default filename.
;    title       : title of the GUI.
;
; OPTIONAL INPUTS: 
;    none.
;
; KEYWORD PARAMETERS:
;    none.
;
; OUTPUTS:
;    filename: name of the desired file.
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
; MODIFICATION HISTORY:
;    program written: november 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it].
;
;-
;
;;;;;;;;;;;;;;;;;;;;;;;
; GUI event loop
;;;;;;;;;;;;;;;;;;;;;;;
;
pro filename_gui_event, event

common filename_gui_block, filename

widget_control, event.id, GET_UVALUE=uvalue  
case uvalue of

   "filename": filename=event.value
                   
   "help"    : spawn, !caos_env.browser+" "+!caos_env.help

   "ok"      : widget_control, event.top, /DESTROY

endcase

end       

;;;;;;;;;;;;;;;;;;;;;;;;;
; GUI generation code
;;;;;;;;;;;;;;;;;;;;;;;;;
;                                 
function filename_gui, def_filename,       $
                       title,              $
                       GROUP_LEADER=group, $
                       _EXTRA=e

common filename_gui_block, filename
filename = def_filename

error = !caos_error.ok

modal = n_elements(group) ne 0
root_base_id = widget_base(TITLE=title, MODAL=modal, /COL, GROUP_LEADER=group)

; parameter base

par_base_id = widget_base(root_base_id, FRAME=10, /COL)

   dummy = cw_filename(par_base_id,                       $
                       TITLE=title,                       $
                       VALUE=def_filename,                $
                       UVALUE="filename",                 $
                       _EXTRA=e                           )

; standard buttons base

btn_base_id = widget_base(root_base_id, FRAME=10, /ROW)
   dummy = widget_button(btn_base_id,  $
                         VALUE="Help", $
                         UVALUE="help" )
   dummy = widget_button(btn_base_id,                                $
                         VALUE="Back to main parameter setting GUI", $
                         UVALUE="ok"                                 )
   if modal then widget_control, dummy, /CANCEL_BUTTON

widget_control, root_base_id, /REALIZE

xmanager, 'filename_gui', root_base_id, GROUP_LEADER=group

return, filename
end
