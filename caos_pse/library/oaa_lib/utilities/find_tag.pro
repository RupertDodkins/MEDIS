;$Id: find_tag.pro,v 1.1 2004/12/07 18:16:57 marco Exp $$
;+
;  NAME:
;   FIND_TAG
;
;  PURPOSE:
;   This routine helps you to find a forgetten field into a large structure.
;
;  USAGE:
;   FIND_TAG, regexp, struct, strout
;
;  INPUT:
;   regexp: string. Regular expression special chacacters are permitted. (See IDL help)
;   struct: struct. This is the place where we are looking for the tag.
;
;  OUTPUT:
;   strout: (optional) string array. Result of the matching. If nothing is found, 
;            it return an empty string. If the struct parameter is wrong, it's set to
;            an integer value -1.
;
;  NOTE:
;   None.
;  
;  PACKAGE:
;   OAA_LIB/UTILITIES
;
;  HISTORY:
;
;  07 Dec 2004
;   Created by Marco Xompero (MX)
;   marco@arcetri.astro.it
;-

Pro find_tag, regexp, struct, strout
   
   if test_type(struct, /struct) then begin
      message, 'Input parameter are wrong: you should insert a valid structure!', CONT=1
      print, 'Returning...'
      strout = -1
      return
   endif
   tags = strlowcase(tag_names(struct))
   regexp = strlowcase(regexp)
   matched = stregex(tags, regexp)
   idx = where(matched ge 0, cc)
   if cc eq 0 then begin
      strout=''
      return
   endif else begin
      strout = transpose(tags[idx])
      print, strout
   endelse
   return

End
