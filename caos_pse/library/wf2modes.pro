; last revision: marcel.carbillet@unice.fr, 2011/05/30.
;+
;
; NAME
; wf2modes
;
; PURPOSE
; project a wavefront on a basis of mirror deformations
;
; INPUTS
; wf   : wavefront to be projected on the basis defined by def
; def  : cube of mirror deformations
;
; KEYWORDS
; ORTHO: is the basis orthogonal ? [yes=1B (set), no=0B (not set)].
; MAT  : - in the non-orthogonal case, and with SVD set, the wavefront-to-modes
;        matrix ;
;        - in the non-orthogonal case, but with SVD unset, the inverse of the
;        matrix Gij of the scalar products between the influence functions.
; SVD  : - if set, use oaa_lib PSEUDO_INVERT routine (with LAPACK singular value
;        decomposition inside through LA_SVD), and produce MAT ;
;        - if not set, use standard idl INVERT routine, and produce MAT.
;
; OUTPUT
; coeff: the coefficients of the projection of wf on the basis defined by def. 
; (in the orthogonal case, the simple scalar product between wf and def)
; (in the non-orthogonal case, with SVD set:
;    pseudo_invert(def.matrix)##transpose(reform(wf))
; (in the non-orthogonal case, but SVD unset:
;    coeff = \vec{a} comes from minimization of |wf-sum{coeff_i*def_i}|^2,
;                      and \vec{a} = MAT \vec{b} and MAT=invert(Gij)
;
; EXAMPLES
; 1. project the wavefront "wf" onto the orthogonal basis "def":
;    coeff = wf2modes(wf, def, /ORTHO)
; 2. project wf onto the non-orthogonal basis def using SVD:
;    coeff = wf2modes(wf, def, /SVD, MAT=w2m)
;    (where w2m is the wf-to-modes matrix, to be computed using SVD)
; 3. project wf onto the non-orthogonal basis def using SVD:
;    coeff = wf2modes(wf, def, /SVD, MAT=w2m)
;    (where w2m was computed before)
; 4. project wf onto the non-orthogonal basis def using direct inverse:
;    coeff = wf2modes(wf, def, MAT=Gji)
;    (where Gji is the inverse of the matrix Gij of the scalar products
;    between the influence functions, to be computed)
; 5. project wf onto the non-orthogonal basis def using direct inverse:
;    coeff = wf2modes(wf, def, MAT=Gji)
;    (where Gji was computed before)
; Examples 2+3 are essentially identical to Examples 4+5, but the method
; employed is much quicker.
;
; MODIFICATION HISTORY
; program written : Marcel Carbillet (Fizeau) [marcel.carbillet@unice.fr].
; with inputs from: Laurent Jolissaint (aquilAOptics) [laurent.jolissaint@aquilaoptics.com],
;                   Marco Bonaglia (OAA-INAF) [mbona@arcetri.astro.it],
;                   Lorenzo Busoni (OAA-INAF) [lbusoni@gmail.com].
;
; modifications   : month YEAR,
;                   name (institute) [email]:
;                  -modification description.
;                  -other modification description.
;
;-
function wf2modes, wf, def, ORTHO=ortho, MAT=mat, SVD=svd

if keyword_set(ORTHO) and keyword_set(MAT) then $
   message, "It is not envisaged to have both ORTHO and MAT keywords set " $
           +"=> stopping program..."
if keyword_set(ORTHO) and keyword_set(SVD) then $
   message, "It is not envisaged to have both ORTHO and SVD keywords set " $
           +"=> stopping program..."

np     = (size(def))[1]
n_def  = (size(def))[3]
indpup = where(total(def,3) ne 0, n_pup)

if not(keyword_set(ORTHO)) then begin
;; not-orthogonal case
   if keyword_set(SVD) then begin
   ;; PSEUDO-INVERSE (/SVD) case
      if not(keyword_set(MAT)) then begin
      ;; calculus of the wavefront-to-modes matrix ("mat" here)
         def_mat = dblarr(n_def, n_pup)
         for i=0, n_def-1L do def_mat[i,*] = (def[*,*,i])[indpup]
         mat = pseudo_invert(def_mat)
      endif
      coeff = mat ## transpose(reform(wf[indpup]))
   endif else begin
   ;; DIRECT INVERSE (no /SVD) case
      if not(keyword_set(MAT)) then begin
      ;; calculus of \Gamma (here Gij)
         Gij = fltarr(n_def, n_def)
         for i=0,n_def-1L do for j=0,n_def-1L do begin
            Gij[i,j]=total(def[*,*,i]*def[*,*,j])/total(def[*,*,j]*def[*,*,j])
         endfor
         mat=invert(temporary(Gij))
      endif
      ; calculus of \vec{b} (here coeff)
      coeff = fltarr(n_def)
      for i=0,n_def-1 do begin
         dummy    = def[*,*,i]
         coeff[i] = total(wf*dummy)/total(dummy*dummy)
      endfor
      ; calculus of \vec{a} (here coeff)
      coeff = mat##transpose(temporary(coeff))
   endelse
endif else begin
;; orthogonal case
   coeff = dblarr(n_def)
   for i=0,n_def-1 do begin
      dummy    = def[*,*,i]
      coeff[i] = total(wf*dummy)/total(dummy*dummy)
   endfor
endelse

return, coeff
end