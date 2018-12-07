; $Id: tfl_gen_default.pro,v 7.0 2016/05/19 marcel.carbillet $
;+
; NAME:
;    tfl_gen_default
;
; PURPOSE:
;    tfl_gen_default generates the default parameter structure
;    for the TFL module and save it in the rigth location.(see 
;    tfl.pro's header --or file caos_help.html-- for details 
;    about the module itself). 
;
;    The default filter is the discrete recursive
;    filter obtained appling the bilinear transformation (see
;    bilinear.pro) to a pure integrator:
;
;                TF(s) = 1/s
;
;    giving in the z-domain:
;
;                         1   1 + z^-1
;                TF(z) = --- ----------
;                         2   1 - z^-1
;
;    (the sampling freqency is normalized to 1 in the TF(z))
;
; CATEGORY:
;    module's utility routine
;
; CALLING SEQUENCE:
;    tfl_gen_default
;
; ROUTINE MODIFICATION HISTORY:
;    routine written: february 1999,
;                     Armando Riccardi (OAA) [riccardi@arcetri.astro.it].
;    modifications  : december 1999--january 2000, 
;                     Bruno  Femenia   (OAA) [bfemenia@arcetri.astro.it],
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -adapted to new version CAOS (v 2.0).
;                   : january/february 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -"mod_type"->"mod_name"
;                     (for version 4.0 of the whole Software System CAOS").
;                    -negative_fd is now a priori not active.
;                   : may 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;-
;
pro tfl_gen_default

info = tfl_info()             ; obtain module infos

module = gen_def_module(info.mod_name, info.ver)
                               ; generate module descrip. structure

max_n_coeff = fix(5)           ; max nb of allowed coeffs, i.e. the max number
                               ; of poles or zeros is max_n_coeff-1
                               ; poles and 0s can be complex

s_zero = dcomplexarr(max_n_coeff-1)
s_pole = dcomplexarr(max_n_coeff-1)
z_num_coeff = dblarr(max_n_coeff)
z_den_coeff = dblarr(max_n_coeff)

;; The default filter is a pure integrator (single pole @ 0 rad/s):
;; TF(s)=1d0/s
double = 1B                    ; used filter precision: double prec.
type = 0                       ; filter type: 0 pure integrator
                               ;              1 PID
                               ;              2 generic gain-zero-pole
; pure integrator (type=0)
s_const   = 1d0
n_s_zero  = 0
n_s_pole  = 1
s_pole[0] = 0d0                ; single pole at zero

method = 0                     ; design methods of discrete from continuos
                               ; filter: 0 tustin (bilinear) (othet
                               ; possibilities in future
                               ; implementations)

negative_fb = 0B               ; is the filter used for a Negative feedback?
                               ; 1B: yes (output = - filtered(input))
                               ; 0B: no  (output = filtered(input))


par = $
   {  $
   tfl, $                      ; structure named TFL
   module     : module,      $ ; standard module description structure
   max_n_coeff: max_n_coeff, $ ; max number of allowed coeffs
   s_const    : s_const,     $ ; constant factor of the s-domain filt. tf
   n_s_zero   : n_s_zero,    $ ; number of zeros of the s-domain filt. tf
   n_s_pole   : n_s_pole,    $ ; number of poles of the s-domain filt. tf
   s_zero     : s_zero,      $ ; zeros of the s-domain filter tf
   s_pole     : s_pole,      $ ; poles of the s-domain filter tf
   filename   : '',          $ ; filename of the filter data (ascii format)
   negative_fb: negative_fb, $ ; is the filter used for a neg. feedback?
   type       : type,        $ ; filter type, usefull for the gui
   method     : method,      $ ; chosen method index from the method list
   double     : double       $ ; coeffs precision: 0B single, 1B double
   }

save, par, FILENAME=info.def_file
end