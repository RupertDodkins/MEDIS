; $Id: atm_init.pro,v 6.0 2016/03/08 marcel.carbillet $
;+
; NAME:
;    atm_init
;
; PURPOSE:
;    atm_init executes the initialization for the ATMophere building
;    (ATM) module, that is:
;       0- check the formal validity of the input/output structure
;       1- initialize the output structure out_atm_t
;    (see atm.pro's header --or file caos_help.html-- for details
;    about the module itself).
;
; CATEGORY:
;    module's initialisation routine
;
; CALLING SEQUENCE:
;    error = atm_init(          $
;                    out_atm_t, $
;                    par,       $
;                    INIT=init  $
;                    )
;
; INPUTS/OUTPUTS/KEYWORDS/ETC:
;    see atm.pro's help for a detailed description.
;
; ROUTINE MODIFICATION HISTORY:
;    program written: february-april 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it].
;    modifications  : may-june 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -integer/non-integer shift problem (par.cal=0 case) fixed.
;                     (see also atm_prog)
;                   : june 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -subharmonics screens ringing problem fixed (=> bilinear
;                     interpolation is now used instead of the fft one when
;                     non-integer shift is needed and subharmonics were added
;                     to the original fft screen). (see also atm_prog)
;                   : september 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it],
;                     Bruno  Femenia   (OAA) [bfemenia@arcetri.astro.it]:
;                    -non-integer shift is now done only if the non-integer part
;                     of the shift represents more than 0.001 pixel, in order to
;                     avoid the numerical errors that occurs while the
;                     user-desired shift should be integer.
;                    -a warning is printed if the layers' wind-shift will need
;                     either a bilinear interpolation or a FFT-based one.
;                   : november 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -adapted to version 2.0 (CAOS).
;                   : December 2000
;                     Bruno  Femenia   (OAA) [bfemenia@arcetri.astro.it]:
;                    -modifications so that within init structure one can 
;                     access the Zernike polynomial coefficients employed by
;                     ATM to generate  phase screens when using PSG with
;                     Zernike polynomials.
;                   : february 2001,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -atm_t type output tag "correction" added
;                     (for MCAO case management).
;                   : january 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -"mod_type"->"mod_name"
;                     (for version 4.0 of the whole Software System CAOS).
;                   : march 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -turbulence can now be switched off (by using par.turnatmos).
;
;-
;
function atm_init, out_atm_t, $
                   par,       $
                   INIT=init

; phase screen generation random seeds common block
common psg_seed_block, seed1, seed2

; initialization of the error code: no error as default
error = !caos_error.ok

; retrieve the input and output information
info = atm_info()

; get the individual output structure types
if info.out_type ne '' then out_type = str_sep(info.out_type,",")

; STANDARD CHECKS
;
; compute and test the requested number of atm arguments
n_par = 1  ; the parameter structure is always present within the arguments
if info.inp_type ne '' then begin
   inp_type = str_sep(info.inp_type,",")
   n_inp    = n_elements(inp_type)
endif else n_inp = 0
if info.out_type ne '' then begin
   out_type = str_sep(info.out_type,",")
   n_out    = n_elements(out_type)
endif else n_out = 0
n_par = n_par + n_inp + n_out
if n_params() ne n_par then message, 'wrong number of arguments'

; test the parameter structure
if test_type(par, /STRUCTURE, N_ELEMENTS=n) then $
   message, 'ATM error: par must be a structure'
if n ne 1 then message, 'ATM error: par cannot be a vector of structures'

if strlowcase(tag_names(par, /STRUCTURE_NAME)) ne info.mod_name then $
   message, 'par must be a parameter structure for the module ATM'

; STRUCTURE "INIT" DEFINITION AND INITIALISATION DATA FILE MANAGEMENT
;
if (par.lps eq 0) then begin

   error     = psg_openr_cube(unit, par.psg_add, header, /GET_LUN)
   dim_x     = header.dim_x
   dim_y     = header.dim_y
   n_screens = header.n_screens
   sha       = header.sha

   if (par.n_layers gt n_screens) then begin

      FREE_LUN, unit

      message, "the file "+string(par.psg_add)                         $
              +" doesn't contain enough wavefronts. program stopped !" $
              +"(nb of wf="+strtrim(n_screens,2)+", nb of layers="     $
              +strtrim(par.n_layers,2)+")"

   endif else begin

      screens = fltarr(dim_x, dim_y, par.n_layers)

      for i = 0, par.n_layers-1 do begin
         error = psg_read_cube(unit, header, screen)
         screens[*,*,i] = screen
      endfor

      if (par.cal eq 0) then FREE_LUN, unit

      screen = 0

   endelse

endif else begin

   seed1  = par.seed1
   seed2  = par.seed2
   error  = atm_psg(par, screens, coeff)
   dim_x  = par.dim
   dim_y  = par.dim
   sha    = par.sha
   header = 0
   unit   = 0

endelse


scale = par.length/dim_x

IF par.turnatmos THEN BEGIN

if (par.cal eq 0) then begin

   shift_flag = intarr(par.n_layers)    ; flag vector telling for each layer
                                        ; either it will need, for time
                                        ; evolution simulation, either a FFT
                                        ; interpolation (non-integer shift *AND*
                                        ; no subharmonics added) or a bilinear
                                        ; interpolation (non-integer shift *AND*
                                        ; subharmonics added) or none (integer
                                        ; shift).
   screens_mem = complexarr(dim_x, dim_y, par.n_layers)
                                        ; FFT(screens)/screens init.
   delta = par.wind*par.delta_t/scale   ; layers' shifts [px]
   delta_x = delta & delta_y = delta    ; layers' x- and y-shifts init.

   for i=0,par.n_layers-1 do begin

      dummy = 0B
      if (par.dir[i] eq 0.) then begin
         delta_x[i] = delta[i]
         delta_y[i] = 0.
      endif else if (par.dir[i] eq 180./!RADEG) then begin
         delta_x[i] = -delta[i]
         delta_y[i] = 0.
      endif else if (par.dir[i] eq  90./!RADEG) then begin
         dummy = 1B
         delta_x[i] = 0.
         delta_y[i] = delta[i]
      endif else if (par.dir[i] eq 270./!RADEG) then begin
         dummy = 1B
         delta_x[i] = 0.
         delta_y[i] = -delta[i]
      endif else begin
         delta_x[i] = delta[i] * cos(par.dir[i])
         delta_y[i] = delta[i] * sin(par.dir[i])
      endelse

      if (dim_x ne dim_y) and (dummy eq 1B) then begin
                                       ; in this case the rectangle screens
                                       ; are basically transposed, so...
         dummy = delta_x[i]
         delta_x[i] = delta_y[i]
         delta_y[i] = dummy

      endif

      if (abs(delta_x[i]-round(delta_x[i])) gt 0.001) $
      or (abs(delta_y[i]-round(delta_y[i])) gt 0.001) then begin

         if (sha eq 0) then begin      ; non-integer shift *AND* no SHA case
            shift_flag[i] = 1          ; FFT(screens) put in the init structure
            screens_mem[*,*,i] = fft(screens[*,*,i])

            print, "ATM warning:===================================+"
            print, "| a FFT-based interpolation will be applied in |"
            print, "| order to wind-shift the atmospheric layers...|"
            print, "+==============================================+"

         endif else begin              ; non-integer shift *AND* SHA case
            shift_flag[i] = 2          ; screens put in the init structure
            screens_mem[*,*,i] = screens[*,*,i]

            print, "ATM warning:===================================+"
            print, "| a bilinear interpolation will be applied in  |"
            print, "| order to wind-shift the atmospheric layers...|"
            print, "+==============================================+"

         endelse

      endif else begin                 ; integer shift case
                                       ; screens put in the init structure
         screens_mem[*,*,i] = screens[*,*,i]
      endelse

   endfor

   init = $                       ; init structure ("temporal evolution" case)
      {   $
      iter       : 0,           $ ; iteration number
      dim_x      : dim_x,       $ ; x-dim. [px]
      dim_y      : dim_y,       $ ; y-dim. [px]
      delta_x    : delta_x,     $ ; layers' x-shifts [px]
      delta_y    : delta_y,     $ ; layers' y-shifts [px]
      screens_mem: screens_mem, $ ; FFT(screens)/screens
      shift_flag : shift_flag   $ ; kind of interpolation for time evolution ?
      }

endif else BEGIN            ; init struct. ("statistical averaging" case)

   IF par.method THEN BEGIN ; Zernike+Jacobi method of screen generation

      pupil = makepupil(par.dim, par.dim, 0.,               $
                        XC=(par.dim-1)/2., YC=(par.dim-1)/2.)

      init = $
        {    $
        iter  : 0,       $ ; iteration number
        dim_x : par.dim, $ ; x-dim. [px]
        dim_y : par.dim, $ ; y-dim. [px]
        header: header,  $ ; screens descr. if lps=0, not used if lps=1
        unit  : unit,    $ ; file screens unit if lps=0, not used if lps=1
        coeff : coeff,   $ ; Used to store Zernike expansion coefficients
        pupil : pupil    $ ; screens' pupil
        }

   ENDIF ELSE BEGIN        ; FFT+SHA method of screen generation

      init = $
        {    $
        iter  : 0,       $ ; iteration number
        dim_x : par.dim, $ ; x-dim. [px]
        dim_y : par.dim, $ ; y-dim. [px]
        header: header,  $ ; screens descr. if lps=0, not used if lps=1.
        unit  : unit     $ ; file screens unit if lps=0, not used if lps=1
        }

      ENDELSE

ENDELSE

ENDIF ELSE BEGIN
   screens = fltarr(dim_x, dim_y, par.n_layers)
ENDELSE

; INITIALIZE THE OUTPUT STRUCTURE
;
alt = fltarr(par.n_layers)           ; layers' altitudes vector
for i = 0, par.n_layers-1 do alt[i] = par.alt[i]

out_atm_t = $                      ; output structure init.
  {         $
  data_type  : info.out_type[0], $ ; data type
  data_status: !caos_data.valid, $ ; data status
  screen     : screens,          $ ; layers' screens
  scale      : scale,            $ ; scale [m/px]
  delta_t    : par.delta_t,      $ ; time-base [s]
  alt        : alt,              $ ; layers' altitudes [m]
  dir        : par.dir,          $ ; winds' directions [rd]
  correction : 0B                $ ; this is NOT a correction atmosphere
  }

; back to calling program
return, error
end
