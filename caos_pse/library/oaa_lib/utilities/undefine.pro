; $Id: undefine.pro,v 1.4 2004/07/28 08:43:07 marco Exp $
;+
;   UNDEFINE
;
;  undefine the passed variable.
;
;  undefine, var
;
;  EXAMPLE
;
; IDL> a=1
; IDL> help, a
; A               INT       =        1
; IDL> undefine, a
; IDL> help, a
; A               UNDEFINED = <Undefined>
;
;   HISTORY
;
; 1999 created by A. Riccardi
; 28 Jul 2004 Marco Xompero (MX)
;  It undefines more variable in the same command line.
;-

pro undefine, var1, var2, var3, var4, var5, var6, var7, var8, var9
    if n_elements(var1) ne 0 then tempvar = size(temporary(var1))
    if n_elements(var2) ne 0 then tempvar = size(temporary(var2))
    if n_elements(var3) ne 0 then tempvar = size(temporary(var3))
    if n_elements(var4) ne 0 then tempvar = size(temporary(var4))
    if n_elements(var5) ne 0 then tempvar = size(temporary(var5))
    if n_elements(var6) ne 0 then tempvar = size(temporary(var6))
    if n_elements(var7) ne 0 then tempvar = size(temporary(var7))
    if n_elements(var8) ne 0 then tempvar = size(temporary(var8))
    if n_elements(var9) ne 0 then tempvar = size(temporary(var9))
end
