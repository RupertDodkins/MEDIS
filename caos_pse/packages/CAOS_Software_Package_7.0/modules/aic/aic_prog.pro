; $Id: aic_prog.pro,v 7.0 2016/04/15 marcel.carbillet $
;+
; NAME:
;    aic_prog
;
; PURPOSE:
;    aic_prog represents the program routine for the Achrom. Interf. Coronagraph
;    (AIC) module, that is:
;
;    (see aic.pro's header --or file caos_help.html-- for details about the
;    module itself).
;
; CATEGORY:
;    module's program routine
;
; CALLING SEQUENCE:
;    error = aic_prog(inp_wfp_t, $ ; wfp_t input structure
;                     out_img_t, $ ; img_t output structure
;                     par,       $ ; parameters structure
;                     INIT=init  $ ; initialisation data structure
;                     ) 
;
; INPUTS/OUTPUTS/KEYWORDS/ETC.:
;    see module help for a detailed description. 
;
; ROUTINE MODIFICATION HISTORY: 
;    routine written: september 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it],
;                     Christophe Verinaud (ESO) [cverinau@eso.org].
;    modifications  : november 2004,
;                     Marcel Carbillet (LUAN) [marcel.carbillet@unice.fr]:
;                    -stupid one-value-vector IDL6+ bug corrected (here n_phot->n_phot[0]).
;                   : april 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;-
; 
function aic_prog, inp_wfp_t, $ ; input struc.
                   out_img_t, $ ; output struc.
                   par,       $ ; AIC parameters structure
                   INIT=init    ; AIC initialization data structure

; CAOS global common block
common caos_block, tot_iter, this_iter

; error code initialization
error = !caos_error.ok

; complex amplitude computation
; - host star
wf_star   = fltarr(init.dim,init.dim)
wf_star[init.xx1, init.xx1] = inp_wfp_t.screen
dummy    = n_phot(0., BAND=band)
n_phot   = inp_wfp_t.n_phot[where(band eq par.band)]*inp_wfp_t.delta_t
dummy    = exp(COMPLEX(0,1)*2*!PI/out_img_t.lambda*wf_star)
amp_star = sqrt(n_phot[0])*sqrt(par.Rfac)*sqrt(par.Tfac)*init.pupil $
         *(dummy[0]+reverse(reverse(dummy[0]*exp(complex(0,!PI)),1),2))

; - companion
wf_plan  = wf_star+init.decal
dummy    = exp(COMPLEX(0,1)*2*!PI/out_img_t.lambda*wf_plan)
amp_plan = sqrt(n_phot[0])*sqrt(par.int_ratio)*sqrt(par.Rfac)*sqrt(par.Tfac)*init.pupil $
          *(dummy[0]+reverse(reverse(dummy[0]*exp(complex(0,!PI)),1),2))

; compute image from host star
;
psf_star = $
   (abs(shift(fft(amp_star),init.dim/2,init.dim/2)))^2

; compute image from companion
;
psf_plan = $
   (abs(shift(fft(amp_plan),init.dim/2,init.dim/2)))^2

; update coronagraphic image output
out_img_t.data_status = !caos_data.valid
out_img_t.image = psf_star + psf_plan

return, error
end