;T+
; \subsubsection{Function: {\tt askconfirm}}
;
; The following function asks for a generic confirmation. It returns
; either 1 or 0 if the answer is, respectively ``yes'' or ``no''.
;
;T-

FUNCTION AskConfirm, Prompt, Parent

Res = DIALOG_MESSAGE(Prompt,/DEFAULT_NO,DIALOG_PARENT=Parent,/QUESTION)

IF Res EQ 'Yes' THEN r=1 ELSE r=0

RETURN, r
END
