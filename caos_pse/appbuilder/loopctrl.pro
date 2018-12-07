;T+
; \subsubsection{Main Entry Point: LoopCtrl}
;
; The following group of routines are used to generate the interaction widget
; to allow the user to define the number of iterations for the simulation
; project.
; The {\tt AB} code uses the main entry point: {\tt LoopCtrl} 
; (Sect.~\ref{loopctrl}).
;
; \subsubsection{Procedure: {\tt LoopCtrlEvent}}
;
;       This is the event handler for the {\tt LoopCtrl} widget.
;
;T-

PRO LoopCtrlEvent, event

COMMON for_loopctrl_only, Field_id, field_value

widget_control, Field_id, get_value = field_value

IF Field_value GT 0  THEN widget_control, event.top, /destroy

END

;T+ 
; \subsubsection{Function: {\tt LoopCtrl}}		\label{loopctrl}
;
; This is the external entry point to the {\tt LoopCtrl} function.
; When called the procedure displays an interaction widget for
; the definition of the number of iterations to be performed
; when the project is run.
;
;T-

FUNCTION LoopCtrl, InitVal, Parent

COMMON for_loopctrl_only

base = widget_base(title = 'Define Loop Parameters',                    $
                   Group_leader=Parent, /col,     /modal)

field_id = cw_field(base, title = 'Number of Iterations',               $
                    value = InitVal, xsize = 5,/INTEGER)

dummy = Widget_Button(base, value='OK',                                 $
                           event_pro='LoopCtrlEvent')

widget_control, base, /realize

xmanager, 'loopctrl', base

RETURN, field_value
end
