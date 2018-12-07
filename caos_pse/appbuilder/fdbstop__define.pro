;T+
; \subsubsection{Object Description}
;
; This code block defines the {\tt Feedback stop} object. It is a special
; Module and is actually defined as a subclass of the class {\tt Module}.
;
; This module must be used when the project implements a system with
; feedback as a targed for the link which actually "closes" the loop.
; If the loop is closed without the use of this module an error (infinite
; loop) is issued in the code generation phase.
;
; {\bf NOTE:} this module will likely be eliminated from the final version
; of the {\tt Application Builder} to be sobstituted by the {\tt Combiner}
; special module (see section~\ref{CombinerSect}).
;
; The only difference between the {\tt FdbStop} special module and any
; other module is a special simbol which identifies the input of this
; module as a possible target for a feedback. For this reason the {\tt FdbStop}
; special module shares with plain modules all the methods and only differs
; for the INIT one.
;
; The {\tt FdbStop} module type is ``generic''.
;
;T-

; NAME:
;
;       FdbStop     - Feedback stop object
;
; Usage:
;
;  MyFdbStop = Obj_New('FdbStop');
;
; Methods:
;
;  See Module
;

;T+
; \subsubsection{Method: {\tt INIT}}
;
; Here follows the {\tt INIT} entry point. This method creates a {\tt module}
; object and then makes the small modifications which distinguish the
; FeedBack Stop module from a plain module.
;
;T-

FUNCTION FdbStop::INIT, id, FATHER=Father

COMMON ModuleList, ListPtr, TypeList, Generic_dtype, IOcolors
COMMON GenDims, ModWidth, ModHeigth, Slotspace
COMMON Worksheet_Common, ModIDgen, DirName, ProjectModified, GridD, $
                         Slot0XY, FileVersion, AB_Name, AB_Version, AB_Date

IF self->Module::INIT('s*s',id,FATHER=father) THEN BEGIN         ; Create module
   self.Graph.Model->remove, self.Graph.Text ; Remove name


                     ; Add feedback input
   self.Graph.Body->add,                            $
                          OBJ_NEW( 'IDLgrPolygon',  $
                               [5,10,5,0],               $     ; X coords
                               [0,15,30,15],             $     ; Y coords
                               [1,1,1,1],                $
                          STYLE=2,                  $
                               COLOR=[0,0,0],            $
                               LINESTYLE = 0      )
                     ; Add central mark


   RETURN, 1
ENDIF ELSE RETURN, 0

END

;T+
; \subsubsection{Data Structure}
;
; The following procedure is the required structure definition for the
; fdbstop object. The data structure is exactly tha same as for plain
; methods.
;
;T-

PRO FdbStop__define     ; Module data structure definition

struct = { FdbStop, INHERITS Module }

END

