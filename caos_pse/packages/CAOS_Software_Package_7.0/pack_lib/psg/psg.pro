; $Id: psg.pro,v 5.2 2007/04/18 marcel.carbillet $
;+
; NAME:
;       psg
;
; PURPOSE:
;       generate and write on a cube-file a serie of phase screens that can be
;       either squares or stripes.
;
; CATEGORY:
;       utility
;
; CALLING SEQUENCE:
;       error = psg(                   $
;                  n_stripes,          $
;                  VERBOSE=verb,       $
;                  OVERWRITE=overwrite $
;                  )
;
; OUTPUT:
;       error: long scalar (error code, see !caos_error var in caos_init.pro).
;
; INPUT:
;       n_stripes: number of stripes per square screen (1 if square screens
;                  are requested).
;
; INCLUDED OUTPUTS:
;       none.
;
; KEYWORD PARAMETERS:
;       VERBOSE  : set this keyword if you want to know what happens while
;                  the program is computing.
;       OVERWRITE: set this keyword if you are sure you want the program to
;                  overwrite already existing cube-file with the same name.
;
; COMMON BLOCK:
;       psg_seed_block: contains the seeds for random numbers generation.
;
; SIDE EFFECTS:
;       none.
;
; RESTRICTIONS:
;       none.
;
; CALLED NON-IDL FUNCTIONS:
;       none.
;
; EXAMPLE:
;    if the user wants to make a cube file of 20 phase stripes of 512*256
;    pixels, she/he has to fill the psg_gen_default file with: n_layers=10
;    and dim=512, then run it (typing "psg_gen_default" at the IDL/CAOS
;    prompt), and eventually launch the command "print, psg(2)".
;    this will produce first 10 phase screens of 512*512 pixels and then
;    cut them in 20 phase stripes of 512*256 pixels.
;    An XDR file called "phase_stripes.xdr" is then saved in the CAOS working
;    directory (from where IDL and then CAOS are launched). This file can be
;    read from the ATM module (see its GUI), with the usual (usual for ATM)
;    limit of 6 phase screens (corresponding to 6 turbulent layers).
;    
; MODIFICATION HISTORY
;    program written: february/march 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it],
;                     Armando Riccardi (OAA) [riccardi@arcetri.astro.it].
;    modifications  : october 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -help corrected.
;                   : november 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -adapted to version 2.0 (CAOS).
;                   : april 2005,
;                     Marcel Carbillet (LUAN) [marcel.carbillet@unice.fr]:
;                    -file addresses were managed the old way... resulting
;                     in a bug when using PSG alone (not within ATM).
;                     (debugged thanks to a bug report from S.Hippler)
;                    -the "EXAMPLE" section has also been more detailed.
;
;-
;
function psg, n_stripes, VERBOSE=verb $        ; phase stripes generation
            , OVERWRITE=overwrite              ; n_stripes = NB OF STRIPES
                                               ; PER SQUARE SCREEN

common psg_seed_block, seed1, seed2            ; random nbs generation common
                                               ; seeds (seed1 for FFT/Zernike,
                                               ; seed2 for subharmonics adding)

error = !caos_error.ok                          ; initialize error code.

info = atm_info()
par_file = !caos_env.modules+!caos_env.delim+info.pack_name $
                   +!caos_env.delim+"modules"+!caos_env.delim+"atm"  $
                   +!caos_env.delim+"atm_lib"+!caos_env.delim+"psg"  $
                   +!caos_env.delim+"psg_default.sav"
restore, FILENAME=par_file                     ; restore parameters.

check_file = findfile(par.psg_add)             ; check overwriting of an
                                               ; already existing screens' file
if check_file[0] ne "" and not keyword_set(overwrite) then begin
   dummy = dialog_message(['file '+par.psg_add+' already exists.', $
                           'would you like to overwrite it ?'],    $
                          TITLE='PSG warning', /QUEST)
    if strlowcase(dummy) eq "no" then return, 1
endif                                                                    

seed1         = par.seed1                      ; FFT/Zernike seed init.
seed2         = par.seed2                      ; subharmonics seed init.
dim_x         = par.dim                        ; x-dimension [px]
dim_y         = par.dim/n_stripes              ; y-dimension [px]
n_screens     = par.n_layers*n_stripes         ; total nb of stripes
                                               ;(or screens if n_stripes=1)
L0_pixel_unit = par.L0/(par.length/par.dim)    ; wf outer scale [px]

if (dim_y*n_stripes ne dim_x) then message, $  ; check if the nbs are ok
   "bad number of stripes wrt screens dimensions"

header = psg_empty_header()                    ; initialize screens' file header
header.n_screens = n_screens                   ; and define its different fields
header.dim_x     = dim_x
header.dim_y     = dim_y
header.method    = par.method
header.model     = par.model
header.sha       = par.sha
header.L0        = L0_pixel_unit
header.seed1     = par.seed1
header.seed2     = par.seed2
header.double    = 0B

openw, unit, par.psg_add, /GET_LUN, /XDR, ERROR=error
                                               ; open file location
if error ne 0 then begin                       ; error management
    message, !ERR_STRING, /CONT
    return, -2L
endif

on_ioerror, IO_ERR                             ; error management
io_valid = 0B

writeu, unit, header                           ; write header first

str_tot = strtrim(n_screens,2)                 ; total nb of screens string
one_more = par.n_layers mod 2

for k = 1L, (n_screens/n_stripes)/2 do begin

   ;; psg works more efficiently if it generates a couple of
   ;; layers a time, instead of a single one.
   par.n_layers = 2

   if keyword_set(verb) then $
      print, 'computing ',strtrim(2*k*n_stripes,2),' of ',str_tot

   err = atm_psg(par, square_phase)           ; compute screens.

   if err ne 0 then begin                     ; any error ?
      if keyword_set(get_lun) then free_lun, unit else close, unit
      message, "error computing the wavefronts", /CONT
      return, -1L
   endif

   phase = fltarr(dim_x, dim_y, par.n_layers*n_stripes)
                                              ; stripes initialisation
   for i = 0, par.n_layers-1 do for j = 0, n_stripes-1 do begin
      phase[*,*,i*n_stripes+j] = square_phase[*,j*dim_y:(j+1)*dim_y-1,i]
                                              ; stripes computation
      writeu, unit, phase[*,*,i*n_stripes+j]
   endfor

endfor

if one_more then begin

   par.n_layers = 1

   if keyword_set(verb) then print, 'computing ',str_tot,' of ',str_tot

   err = atm_psg(par, square_phase)           ; compute screens.

   if err ne 0 then begin
      message, "error computing the wavefronts: the file is open", /CONT
      return, -1L
   endif

   phase = fltarr(dim_x, dim_y, n_stripes)    ; stripes initialisation

   for i = 0, par.n_layers-1 do for j = 0, n_stripes-1 do begin

      phase[*,*,i*n_stripes+j] = square_phase[*,j*dim_y:(j+1)*dim_y-1,i]
                                              ; stripes computation
      writeu, unit, phase[*,*,i*n_stripes+j]

   endfor

endif

if keyword_set(get_lun) then free_lun, unit else close, unit
                                               ; close file location
io_valid = 1B                                  ; error stuff
IO_ERR: if not io_valid then begin
    if keywod_set(get_lun) then free_lun, unit else close, unit    
    message, !ERR_STRING, /CONT
    return, -2L
endif

return, error                                  ; back to calling program.
end                                            ; end of utility function.
