pro where2d,logic,col,row
;+
; NAME: 
;       WHERE2D
;
; PURPOSE:
;       returns 2 vectors containing row and index subscripts of the
;       nonzero elements of a 2 dim Array_Expression 
;
; CATEGORY:
;
;
;
; CALLING SEQUENCE:
;
;       WHERE2D,Array_Expression,Col_Subscripts,Row_Subscripts
; 
; INPUTS:
;
;       Array_Expression = The 2 dim array to be search
;
; OPTIONAL INPUTS:
;	
; KEYWORD PARAMETERS:
;
; OUTPUTS:
;
;       Col_Subscripts = a vector containing column subscripts
;       Row_Subscripts = a vector containing row subscripts
;
; OPTIONAL OUTPUTS:
;
; SIDE EFFECTS:
;
; RESTRICTIONS:
;
; PROCEDURE:
;
;       Use WHERE, then SIZE and MOD to determine Col and Row
;
; EXAMPLE:
;       
;       a=INDGEN(10,10)
;       WHERE2D,(a GE 98),x,y
;       PRINT,x,y
;             8           9
;             9           9
;
; MODIFICATION HISTORY:
;      
;       Joel Vernet, Feb-97
;-

index=where(logic)
s = SIZE(logic)
ncol = s(1)
col = index MOD ncol
row = index / ncol

end
