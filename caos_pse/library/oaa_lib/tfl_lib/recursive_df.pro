; $Id: recursive_df.pro,v 1.5 2004/07/21 14:08:39 riccardi Exp $

;+
; RECURSIVE_DF
;
; filt_sig = recursive_df(sig, numd, dend)
;
; apply the digital recursive filter defined by numd, dend on the digital signal sig.
; The filtered signal is returned. See tustin.pro for a definition of numd and dend.
;
; MODIFICATON HISTORY
;
;    Written by: A. Riccardi (AR), Osservatorio Astrofisico di Arcetri, ITALY
;                riccardi@arcetri.astro.it
;    15 Jul 2004, AR & M. Xompero
;      bug when filter has no poles in z^-1 fixed
;-

function recursive_df, x, numd, dend

n = n_elements(x)
nd= n_elements(dend)
nn= n_elements(numd)

if dend[0] eq 0 then message,'the digital filter must have den_d[0] ne 0'

y = replicate(0B*x[0], n)

numr = rotate(numd,2)
if nd eq 1 then begin
    denr=0.0
    nd=2
endif else denr = rotate(dend[1:nd-1],2)
if dend[0] ne 1.0 then begin
    numr = numr/dend[0]
    denr = denr/dend[0]
endif
;for i=nf-1,n-1 do y[i]=total(numr*x[i-nf+1:i])-total(denr*y[i-nf+1:i-1])

y[0] = numr[nn-1]*x[0]
for i=1,n-1 do $ ; compute filtered signal recursively
  y[i]=total(numr[nn-1-i>0:*]*x[i-nn+1>0:i]) $
  -total(denr[nd-1-i>0:*]*y[i-nd+1>0:i-1])

return, y
end
