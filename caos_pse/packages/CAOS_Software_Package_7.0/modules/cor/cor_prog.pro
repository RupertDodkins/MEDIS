; $Id: cor_prog.pro,v 7.0 2016/04/27 marcel.carbillet $
;+
; NAME:
;    cor_prog
;
; PURPOSE:
;    cor_prog represents the program routine for the CORonagraph
;    (COR) module, that is:
;
;    (see cor.pro's header --or file caos_help.html-- for details about the
;    module itself).
;
; CATEGORY:
;    module's program routine
;
; CALLING SEQUENCE:
;    error = cor_prog(inp_wfp_t, $ ; wfp_t input structure
;                     out_img_t, $ ; img_t output structure
;                     par,       $ ; parameters structure
;                     INIT=init  $ ; initialisation data structure
;                     ) 
;
; INPUTS/OUTPUTS/KEYWORDS/ETC.:
;    see module help for a detailed description. 
;
; ROUTINE MODIFICATION HISTORY: 
;    routine written: october 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it],
;                     Olivier Lardiere (OAA) [lardiere@arcetri.astro.it].
;    modifications  : november 2004,
;                     Marcel Carbillet (LUAN) [marcel.carbillet@unice.fr],
;                     Eduard Serradell (LUAN) [eduard_serradell@yahoo.com]:
;                    -stupid one-value-vector IDL6+ bug corrected (n_phot->n_phot[0]).
;                   : september 2008,
;                     Marcel Carbillet (Fizeau) [marcel.carbillet@unice.fr]:
;                    -FFT is actually not inverse passing from plane B to plane C
;                    (lines 67 and 74)
;                   : april 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;
;-
; 
function cor_prog, inp_wfp_t, $ ; input struc.
                   out_img_t, $ ; output struc.
                   par,       $ ; COR parameters structure
                   INIT=init    ; COR initialization data structure

; CAOS global common block
common caos_block, tot_iter, this_iter

; error code initialization
error = !caos_error.ok

; complex amplitude computation
; - host star
wf_star  = fltarr(init.dim,init.dim)
wf_star[init.xx1, init.xx1] = inp_wfp_t.screen
dummy    = n_phot(0., BAND=band)
n_phot   = inp_wfp_t.n_phot[where(band eq par.band)]*inp_wfp_t.delta_t
amp_star = sqrt(n_phot[0])*init.pupil*exp(COMPLEX(0,1)*2*!PI/out_img_t.lambda[0]*wf_star)

; - companion
wf_plan  = wf_star+init.decal
amp_plan = sqrt(n_phot[0]*par.int_ratio)*init.pupil*exp(COMPLEX(0,1)*2*!PI/out_img_t.lambda[0]*wf_plan)

; compute image from host star
;
if par.corono eq 0 then psf_star = shift((abs(fft(amp_star)))^2,init.dim/2,init.dim/2) $
else psf_star =                                                                        $
;   (abs(fft(fft(shift(fft(amp_star),init.dim/2,init.dim/2)*init.mask,/INV)*init.lyotstop)))^2
   (abs(fft(fft(shift(fft(amp_star),init.dim/2,init.dim/2)*init.mask)*init.lyotstop)))^2

; compute image from companion
;
if par.corono eq 0 then psf_plan = shift((abs(fft(amp_plan)))^2,init.dim/2,init.dim/2) $
else psf_plan =                                                                        $
;   (abs(fft(fft(shift(fft(amp_plan),init.dim/2,init.dim/2)*init.mask,/INV)*init.lyotstop)))^2
   (abs(fft(fft(shift(fft(amp_plan),init.dim/2,init.dim/2)*init.mask)*init.lyotstop)))^2

; update image output
out_img_t.data_status = !caos_data.valid
out_img_t.image = psf_star + psf_plan

return, error
end
