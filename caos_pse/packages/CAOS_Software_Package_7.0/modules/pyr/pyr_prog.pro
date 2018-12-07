; $Id: pyr_prog.pro,v 7.0 2016/05/19 marcel.carbillet $
;+
; NAME:
;    pyr_prog
;
; PURPOSE:
;    pyr_prog represents the scientific algorithm for the 
;    "Pyramid" (pyr) module.
;    (see pyr.pro's header --or file caos_help.html-- for details
;     about the module itself). 
; 
; CATEGORY:
;    scientific program
;
; CALLING SEQUENCE:
;    error = pyr_prog(inp_wfp_t, out_mim_t, par, INIT=init)
;
; MODIFICATION HISTORY:
;    program written: june 2001, 
;                     Christophe Verinaud (OAA) [verinaud@arcetri.astro.it].
;                     (from shs_prog.pro)
;    modifications  : october 2002,
;                     Christophe Verinaud (OAA) [verinaud@arcetri.astro.it]:
;                    -phase mask alternative added.
;                   : february 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -second output from mim_t to img_t.
;                   : may 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;-
;
function pyr_prog, inp_wfp_t, out_mim_t1, out_img_t2, par, INIT=init

error = !caos_error.ok      ;Init error code: no error as default

ds1 = inp_wfp_t.data_status

CASE ds1 OF
   !caos_data.not_valid: MESSAGE,'Input wfp_t cannot be not_valid.' 
   !caos_data.wait     : MESSAGE,'Input wfp_t data cannot be wait.'
   !caos_data.valid    : ds1= ds1
   ELSE                : MESSAGE,'Input wfp_t has an invalid data status.'
ENDCASE

error = pyr_image(inp_wfp_t, init, par, image, iii, par.fftwnd) 

out_mim_t1.image = image
out_img_t2.image = iii

return, error
end