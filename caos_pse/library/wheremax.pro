PRO wheremax,image,x,y,noprint=noprint,min=min
;+
; NAME:
;      WHEREMAX
;
;
; PURPOSE:
;
;
;
; CATEGORY:
;
;
;
; CALLING SEQUENCE:
;        WHEREMAX, IMAGE, [X, Y]
;
; 
; INPUTS:
;
;
;
; OPTIONAL INPUTS:
;
;
;	
; KEYWORD PARAMETERS:
;       NOPRINT = if set, disable print to stdout
;       MIN = if set,print min value and its location
;
; OUTPUTS:
;        Print max value in IMAGE and its position (row, column)
;
;
; OPTIONAL OUTPUTS:
;        X
;        Y
;
; RESTRICTIONS:
;       Works only for 2 dim. images
;
;
; PROCEDURE:
;        MIN, WHERE2D, WHEREMIN
;
;
; EXAMPLE:
;
;
;
; MODIFICATION HISTORY:
;       created by Joel Vernet - Feb 1997 
;-

mm=MAX(image)
WHERE2D, (image ge mm), x, y


IF NOT(KEYWORD_SET(NOPRINT)) THEN  BEGIN
  sz=SIZE(x)
 FOR ii=0,(sz(1)-1) DO  PRINT,"Maximum =",STRING(mm),"  x="+STRING(x(ii),format='(i4)') $
  +"  y="+STRING(y(ii),format='(i4)')
ENDIF

IF (KEYWORD_SET(MIN)) THEN WHEREMIN,image

RETURN
END
