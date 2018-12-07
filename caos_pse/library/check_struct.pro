; $Id: check_struct.pro,v 1.1.1.1 2003/03/07 10:46:19 marcel Exp $
;************************************************************************
;
;+
; NAME:
;       check_struct
;
; PURPOSE:
;       check_struct verifies if two structures are equal.
;       It returns a 0 value (no fault) if both structures have the same tags 
;       and the same values for each tag.
;       It returns a 1 value if both structures have the same tags but
;       different values for the tags.
;       It returns a -1 value if the structures have not the same tags (names 
;       or number of tags)
;       If the tags are not ordered on the same way, the program sorts them
;       and verify if they are identical. If so, it returns 0.
;
; CATEGORY:
;       General utility function
;
; CALLING SEQUENCE:
;       faults = check_struct ( struct_1 , struct_2 )
;
; INPUTS:
;       struct_1 and struct_2 are the 2 structures to compare.
;
; OUTPUTS:
;       faults: existence of a fault between the structures
;               0 if no fault
;               1 if same tag names but different value(s)
;              -1 if different tag names of different number of tags
;
; SIDE EFFECTS:
;       None.
;
; RESTRICTIONS:
;       None.
;
; PROCEDURE:
;       None.
;
; EXAMPLE:
;       Write here an example!
;
; MODIFICATION HISTORY:
;       December 1998,   written by F. Delplancke (ESO) <fdelplan@eso.org>
;       September 1999,  F. Delplancke (ESO), bug due to floating
;       precision fixed.
;-


FUNCTION check_struct, struct_1, struct_2

faults = 0

IF n_tags(struct_1) NE n_tags(struct_2) THEN $

   faults = -1 $      ; non equal number of tags

ELSE BEGIN

   names_1 =  tag_names(struct_1)
   names_2 =  tag_names(struct_2)

   n1 =  sort(names_1)   ; sorting the tag names
   n2 =  sort(names_2)

   dummy =  where( names_1(n1) NE names_2(n2) , count )
                         ; testing if the same tags are equal

   IF count NE 0 THEN $

      faults =  -1 $     ; non identical structure names

   ELSE BEGIN

      k = 0
      REPEAT BEGIN
         machin = size(struct_1.(n1[k]))
         if machin[ (size(machin))[1] - 2 ] eq 7 then begin
         check =  struct_1.(n1[k]) eq struct_2.(n2[k])
         endif else begin
            check =  ( struct_1.(n1[k]) le (struct_2.(n2[k])*1.00001) ) and $
                     ( struct_1.(n1[k]) ge (struct_2.(n2[k])*0.99999) )
         endelse 
         IF (size(check))[0] NE 0 THEN BEGIN
            truc = 1
            FOR a=0,(size(check))[0]-1 DO $
               truc =  truc * (size(check))[a+1]
            num =  0
            REPEAT BEGIN 
               IF check[num] NE 1 THEN  faults = 1
              num = num+1
            END UNTIL (num EQ (truc-1) OR faults EQ 1)
         ENDIF ELSE IF check NE 1 THEN faults = 1

                         ; non-equal values
         k = k+1
      END UNTIL ( faults NE 0 OR k EQ n_tags(struct_1) )

   ENDELSE

ENDELSE    
return, faults 

END 


