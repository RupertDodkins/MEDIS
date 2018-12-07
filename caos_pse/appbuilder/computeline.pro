;T+
; \subsubsection{Function: {\tt ComputeLine}}
;
; The following function is used to rearrange intermediate points
; of a link by setting them in the  proper order, irrespective
; of the order defined by the user. Links, in fact, can be defined 
; using either an output or an input as starting point, but are stored
; in the data structure in the direction $output \rightarrow input$.
; 
; As a result of the call a new "Link" object is returned.
;
;T-

FUNCTION ComputeLine, Direction,           $	; Computes link line coordinates
                      VecX, VecY

Nxy=N_ELEMENTS(VecX)

IF Direction EQ 1 THEN BEGIN			; Reverse order of line points
	LastI = FIX((Nxy-1)/2)
	FOR i=0, LastI DO BEGIN
		exi = Nxy-1-i
		sx = VecX[exi]
		sy = VecY[exi]
		VecX[exi]=VecX[i]
		VecY[exi]=VecY[i]
		VecX[i]=sx
		VecY[i]=sy
	ENDFOR
ENDIF

Line=OBJ_NEW( 'Link', VecX, VecY )

RETURN, Line

END
