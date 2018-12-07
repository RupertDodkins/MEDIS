;T+
; \subsubsection{Function: {\tt GetPrjList}} \label{getprjlist}
;
; The following function returns an array containing a list of currently 
; defined projects. Its main purpose is to isolate operating system
; dependency in the  file scan IDL procedure ({\tt FINDFILE}) which
; has sligthly different behaviours under Unix and under Windows.
;
;T-

; 26 July 2004 - modified in order to work also under windows XP
;                (in addition to Unix/Linux - not tested for MacOS and vms)
;              - brice le roux [leroux@arcetri.astro.it],
;                marcel carbillet [marcel@arcetri.astro.it].

FUNCTION GetPrjList			; Returns a list of current projects

COMMON Worksheet_Common

PrjDir = filepath(ROOT='.',SUB='Projects','')

case !VERSION.OS_FAMILY of
   "unix": begin
      PrjList = FINDFILE(PrjDir+dir_wildcard, COUNT=cc)
   end
   "Windows": begin
      PrjList = FINDFILE(PrjDir+'*', COUNT=cc)
   end
   "vms": begin
      PrjList = FINDFILE(PrjDir+dir_wildcard, COUNT=cc)
   end
   "MacOS": begin
      PrjList = FINDFILE(PrjDir+dir_wildcard, COUNT=cc)
   end
   else: message, "the operative system of the family "+!VERSION.OS_FAMILY $
                   +" is not supported."
endcase

FOR i=0,cc-1 DO BEGIN
	fname = sep_path(PrjList[i], SUB=sub)
	IF fname EQ '' THEN                          $
		PrjList[i] = sub[n_elements(sub)-1]  $
	ELSE                                         $
		PrjList[i]=fname
ENDFOR

idx = WHERE((PrjList NE '.') AND (PrjList NE '..'), cc)
IF cc EQ 0 THEN PrjList = '' ELSE PrjList = PrjList[idx]

RETURN, PrjList

END
