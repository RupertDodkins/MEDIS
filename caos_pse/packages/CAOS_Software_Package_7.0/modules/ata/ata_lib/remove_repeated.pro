; $Id: remove_repeated.pro,v 7.0 2016/05/19 marcel.carbillet $
;+
; NAME:
;       remove_repeated
;
; PURPOSE:
;       Given a 2D multicolumn array (>2) , sorts it and removes points with same
;       entry in first column, keeping the first occurence.
;
; CATEGORY:
;       ...
;
; CALLING SEQUENCE:
;       ...
;
; INPUTS/OUTPUTS/KEYWORDS/ETC.:
;       see module help for a detailed description. 
;
; MODIFICATION HISTORY:
;       program written: March 2001,
;                        Bruno Femenia (OAA)  [bfemenia@arcetri.astro.it]
;                      : april 2016,
;                        Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                       -adapted to Soft. Pack. CAOS 7.0.
;-
;
PRO remove_repeated, data, out, VERBOSE=verbose, EPS= eps

   r1   = SORT(data[0,*])
   data = data[*,r1]

   s1 = SIZE(data)

   IF s1[0] NE 2 THEN MESSAGE,'Routine intended only for 2D arrays'

   CASE s1[3] OF

      1: dummy = BYTEARR(s1[1],s1[2])

      2: dummy = INTARR(s1[1],s1[2])

      3: dummy = LONARR(s1[1],s1[2])

      4: dummy = FLTARR(s1[1],s1[2])

      5: dummy = DBLARR(s1[1],s1[2])

      ELSE: MESSAGE,"Routine not intended for I/P's type"

   ENDCASE 

   index1 = 0l
   index2 = 0l

   IF NOT(KEYWORD_SET(eps)) THEN BEGIN
      MESSAGE,'No tolerance chosen =>  program compares absolute'+ $
        ' differences against 0!! (Infinite precission).',/INFO
      eps = 0.
   ENDIF 

   REPEAT BEGIN 
      r1 = WHERE( ABS(data[0,*]-data[0,index2]) LE eps, c1)
      dummy[*,index1] = data[*,r1[0]]
      index1 = index1+1
      index2 = index2+c1
      IF (KEYWORD_SET(verbose) AND c1 GT 1) THEN $
        FOR i=0,c1-1 DO PRINT,'Element repeated: ',data[*,r1[i]],'  at index:', STRCOMPRESS(r1[i])
   ENDREP UNTIL (index2 EQ s1[2])

   
   out = dummy[*,0:index1-1]

   return

END 