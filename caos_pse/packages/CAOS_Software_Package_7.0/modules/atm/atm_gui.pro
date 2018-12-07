; $Id: atm_gui.pro,v 7.0 2016/05/19 marcel.carbillet $
;+
; NAME:
;    atm_gui
;
; PURPOSE:
;    atm_gui generates the Graphical User Interface (GUI) for
;    setting the parameters of the ATMosphere (ATM) module.
;    A parameter file called atm_nnnnn.sav is created, where nnnnn
;    is the number n_module associated to the module instance.
;    The file is stored in the project directory proj_name located
;    in the working directory.
;    (see atm.pro's header --or file caos_help.html-- for details
;    about the module itself).
;
; CATEGORY:
;    module's Graphical User Interface routine
;
; CALLING SEQUENCE:
;    error = atm_gui(n_module, proj_name)
; 
; INPUTS:
;    n_module:  integer scalar. number associated to the intance
;               of the ATM module. n_module > 0.
;    proj_name: string. name of the current project.
;
; OUTPUTS:
;    error: long scalar, error code (see !caos_error var in caos_init.pro).
;
; COMMON BLOCKS:
;    none.
;
; CALLED NON-IDL FUNCTIONS:
;   sha_test
;   sha_test_gui
;   evol_time
;   trans_tab_gui 
;
; ROUTINE MODIFICATION HISTORY:
;    program written: october 1998,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it].
;    modifications  : november 1998,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -atmosphere evolution time calculus modified
;                     in order to take into account the case where
;                     the layers' winds are zeros.
;                   : february 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -a few modifications in order to fit with version 1.0
;                     new features.
;                   : october 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -the Fried parameter, the maximum field-of-view, the
;                     evolution time of turbulence, as well as the r0
;                     sampling, are now given for all the pre-defined bands
;                     (Johnson and special Na) central wavelengths, with
;                     dedicated sub-GUIs.
;                   : november-april 2000,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -enhanced and adapted to version 2.0 (CAOS).
;                   : december 2000,
;                     Bruno Femenia (OAA) [bfemenia@arcetri.astro.it]:
;                    -parameter "zern_rad_degree" added.
;                   : june 2001,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -avoided the use of the astrolib routine TAG_EXIST
;                     (and subsequent compatibility with older versions of
;                      the module).
;                   : january/february 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -adapted to version 4.0 of the whole Software System CAOS
;                     (variable "pack_name" added, and variable "mod_type"
;                     changed into "mod_name").
;                    -(atm_info()).help stuff added (instead of !caos_env.help).
;                    -warning on r0 sampling eliminated (was almost always useless
;                     and confusing).
;                   : december 2004,
;                     Marcel Carbillet (LUAN) [marcel.carbillet@unice.fr]:
;                    -no more crash provoked when controlling the Soft.Pack.
;                     version for existing parameter files - just a warning.
;                   : february 2007,
;                     Marcel Carbillet (LUAN) [marcel.carbillet@unice.fr]:
;                    -control of the the Soft.Pack. debugged (the warning was
;                     here *always* (partly) printed )...
;                   : april 2014,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -evolution time accessible even in the "statistical averaging" case.
;                   : october 2014,
;                     Marcel Carbillet (Fizeau) [marcel.carbillet@unice.fr]:
;                    -no more limit for the number of turbulent layers (but the one given
;                     by the default parameter file to be set up in atm_gen_default.pro).
;                   : march 2016,
;                     Ulysse Perruchon-Monge & Adama Sy (Dépt. Physique UNS),
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -turbulence can now be switched off (by using par.turnatmos).
;                   : april 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;                   : may 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr],
;                     Andrea La Camera (DIBRIS) [andrea.lacamera@unige.it]:
;                    -New way to call CAOS_HELP (by using the "online_help" 
;                     routine, independent from the operating system used.
;
;-
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; status setting procedure ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
pro atm_gui_set, state

widget_control, /HOURGLASS

case state.par.cal of
   0: begin
      widget_control, state.id.evol_t,  /SENSITIVE
      t0=evol_time(state.par.r0, state.par.wind, state.par.weight)
      widget_control, state.id.evol_t, SET_VALUE=t0
      state.par.method = 0
      widget_control, state.id.method, SET_VALUE=state.par.method
      WIDGET_CONTROL, state.id.zern_rad_degree, SENSITIVE=0
   end
   1: begin
      widget_control, state.id.evol_t,  SENSITIVE=0
      widget_control, state.id.evol_t,  SET_VALUE=0.
      widget_control, state.id.t0_tab,  SENSITIVE=0
   end
endcase

;;;ICI!!!;;;

if (state.par.model eq 0) then widget_control, state.id.L0, SENSITIVE=0 $
   else widget_control, state.id.L0, SENSITIVE=1

;if (state.par.n_layers gt 6) then begin
;   dummy = dialog_message('Number of turbulent layers MUST BE <= 6', $
;      DIALOG_PARENT=atm_gui, TITLE='ATM error', /ERROR)
;   state.par.n_layers = 6
;   widget_control, state.id.n_lay, SET_VALUE=state.par.n_layers
;endif
np = state.par.n_layers & atm_val = fltarr(4, np)
atm_val[0,*] = state.par.alt   [0:np-1]
atm_val[1,*] = state.par.weight[0:np-1]
atm_val[2,*] = state.par.wind  [0:np-1]
atm_val[3,*] = state.par.dir   [0:np-1]*!RADEG
widget_control, state.id.atm, /DELETE_ROWS
widget_control, state.id.atm, INSERT_ROWS=state.par.n_layers
widget_control, state.id.atm, $
   ROW_LABELS ="layer #"+strtrim(indgen(state.par.n_layers),2)
if (state.par.cal eq 1) then begin
   atm_val[2, *] = 0 & atm_val[3, *] = 0
   widget_control, state.id.atm, $
      COLUMN_LABELS=["h [m]", "Cn2 ratio", " ", " "]
endif else widget_control, state.id.atm, $
   COLUMN_LABELS=["h [m]", "Cn2 ratio", "v [m/s]", "dir [deg]"]

widget_control, state.id.atm, SET_VALUE=atm_val

if (state.par.length ne 0) then begin
   widget_control, state.id.sam_r0, $
      SET_VALUE=state.par.r0*state.par.dim/state.par.length
   widget_control, state.id.fov, $
      SET_VALUE=5E-7*state.par.dim/state.par.length*!RADEG*3600.
endif

if (state.par.lps eq 1) then begin

   widget_control, state.id.psg,     /SENSITIVE
   widget_control, state.id.read_ps, SENSITIVE=0
   widget_control, state.id.psg_L0,  SENSITIVE=0

   widget_control, state.id.width,   SET_VALUE=state.par.length

endif else begin

   widget_control, state.id.psg,     SENSITIVE=0
   widget_control, state.id.read_ps, /SENSITIVE
   widget_control, state.id.psg_L0,  /SENSITIVE

   error = psg_openr_cube(unit, state.par.psg_add, header, /GET_LUN)
   FREE_LUN, unit

   if (state.par.dim ne 0) then                               $
      widget_control, state.id.psg_L0,    SET_VALUE=header.L0 $
                                             * state.par.length/header.dim_x

   if (state.par.length ne 0) then begin
      widget_control, state.id.sam_r0,    SET_VALUE=state.par.r0 $
                                             * header.dim_x/state.par.length
      widget_control, state.id.fov,       SET_VALUE=5E-7*header.dim_x $
                                                   /state.par.length*!RADEG*3600
   endif

   widget_control, state.id.psg_dimx,     SET_VALUE=header.dim_x
   widget_control, state.id.psg_dimy,     SET_VALUE=header.dim_y
   widget_control, state.id.psg_nscreens, SET_VALUE=header.n_screens
   widget_control, state.id.psg_sha,      SET_VALUE=header.sha
   widget_control, state.id.psg_seed1,    SET_VALUE=header.seed1
   widget_control, state.id.psg_seed2,    SET_VALUE=header.seed2

   if (header.method eq 0) then dummy = "FFT (+ subharmonics)" $
   else dummy = "Zernike polynomials"
   widget_control, state.id.psg_meth,     SET_VALUE=dummy
   if (header.model eq 0) then dummy = "Kolmogorov" else dummy = "von Karman"
   widget_control, state.id.psg_model,    SET_VALUE=dummy
   if (header.double eq 1B) then dummy = "double" else dummy = "floating"
   widget_control, state.id.psg_prec,     SET_VALUE=dummy

   if (header.method eq 1) then begin
      widget_control, state.id.psg_sha,   SENSITIVE=0
      widget_control, state.id.psg_seed2, SENSITIVE=0
   endif else begin
      widget_control, state.id.psg_sha,   /SENSITIVE
      if (header.sha ne 0) then widget_control, state.id.psg_seed2, /SENSITIVE $
      else widget_control, state.id.psg_seed2, SENSITIVE=0
   endelse

   if (header.model eq 0) then widget_control, state.id.psg_L0, SENSITIVE=0

   widget_control, state.id.width, $
      SET_VALUE=header.dim_y*state.par.length/header.dim_x

endelse

case state.par.turnatmos of
   0B: begin
      state.par.n_layers = 1
      widget_control, state.id.n_lay, SET_VALUE=state.par.n_layers
      state.par.sha = 0
      widget_control, state.id.sha,   SET_VALUE=state.par.sha
      state.par.lps = 1
      widget_control, state.id.lps,   SET_VALUE=state.par.lps
      
      widget_control, state.id.cal,             SENSITIVE=0
      widget_control, state.id.evol_t,          SENSITIVE=0
      widget_control, state.id.t0_tab,          SENSITIVE=0
      widget_control, state.id.n_lay,           SENSITIVE=0
      widget_control, state.id.atm,             SENSITIVE=0
      widget_control, state.id.r0,              SENSITIVE=0
      widget_control, state.id.r0_tab,          SENSITIVE=0
      widget_control, state.id.lps,             SENSITIVE=0
      widget_control, state.id.sam_r0,          SENSITIVE=0
      widget_control, state.id.sam_r0_tab,      SENSITIVE=0
      widget_control, state.id.read_ps,         SENSITIVE=0
      widget_control, state.id.method,          SENSITIVE=0
      widget_control, state.id.model,           SENSITIVE=0
      widget_control, state.id.seed1,           SENSITIVE=0
      widget_control, state.id.seed2,           SENSITIVE=0
      widget_control, state.id.sha_test,        SENSITIVE=0
      widget_control, state.id.title_sha,       SENSITIVE=0
      widget_control, state.id.rec_sha,         SENSITIVE=0
      widget_control, state.id.sha,             SENSITIVE=0
      widget_control, state.id.L0,              SENSITIVE=0
      widget_control, state.id.zern_rad_degree, SENSITIVE=0       
   end
   1B: begin
      widget_control, state.id.cal,            /SENSITIVE
      widget_control, state.id.evol_t,         /SENSITIVE
      widget_control, state.id.t0_tab,         /SENSITIVE
      widget_control, state.id.n_lay,          /SENSITIVE
      widget_control, state.id.atm,            /SENSITIVE
      widget_control, state.id.r0,             /SENSITIVE
      widget_control, state.id.r0_tab,         /SENSITIVE
      widget_control, state.id.lps,            /SENSITIVE
      widget_control, state.id.sam_r0,         /SENSITIVE
      widget_control, state.id.sam_r0_tab,     /SENSITIVE
      widget_control, state.id.read_ps,        /SENSITIVE
      widget_control, state.id.method,         /SENSITIVE
      widget_control, state.id.model,          /SENSITIVE
      widget_control, state.id.seed1,          /SENSITIVE
      widget_control, state.id.seed2,          /SENSITIVE
      widget_control, state.id.sha_test,       /SENSITIVE
      widget_control, state.id.title_sha,      /SENSITIVE
      widget_control, state.id.rec_sha,        /SENSITIVE
      widget_control, state.id.sha,            /SENSITIVE
      widget_control, state.id.L0,             /SENSITIVE
      widget_control, state.id.zern_rad_degree,/SENSITIVE
   end
endcase

if (state.par.method eq 1) then begin
   state.par.model = 0
   widget_control, state.id.model,    SET_VALUE=state.par.model
   widget_control, state.id.sha,      SENSITIVE=0
   widget_control, state.id.rec_sha,  SENSITIVE=0
   widget_control, state.id.title_sha,SENSITIVE=0
   widget_control, state.id.sha_test, SENSITIVE=0
   widget_control, state.id.seed2,    SENSITIVE=0
   WIDGET_CONTROL, state.id.zern_rad_degree, /SENSITIVE
   WIDGET_CONTROL, state.id.zern_rad_degree,  SET_VALUE=state.par.zern_rad_degree
endif else begin
   widget_control, state.id.sha,      /SENSITIVE
   widget_control, state.id.rec_sha,  /SENSITIVE
   widget_control, state.id.title_sha,/SENSITIVE
   widget_control, state.id.sha_test, /SENSITIVE
   widget_control, state.id.seed2,    /SENSITIVE
   WIDGET_CONTROL, state.id.zern_rad_degree, SENSITIVE=0
   if (state.par.model eq 1 and state.par.length ne 0 and state.par.L0 ne 0) $
   then begin
      dummy = $
         ceil(alog(state.par.L0/state.par.length/sqrt(.99^(-6/5.)-1))/alog(3))
      if (dummy lt 0) then dummy=0
      widget_control, state.id.rec_sha, SET_VALUE=dummy
   endif else widget_control, state.id.rec_sha, SET_VALUE=9
endelse

end

;;;;;;;;;;;;;;;;;;;
; GUI events loop ;
;;;;;;;;;;;;;;;;;;;
;
pro atm_gui_event, event

common error_block, error

; read the GUI state structure
widget_control, event.top, GET_UVALUE=state

; handle a kill request (considered as a cancel event).
if tag_names(event, /STRUCTURE_NAME) eq 'WIDGET_KILL_REQUEST' then begin
   error = !caos_error.cancel
   widget_control, event.top, /DESTROY
endif

; handle all the other events.
widget_control, event.id, GET_UVALUE=uvalue
case uvalue of

   'turnatmos': begin
      state.par.turnatmos = event.value
      atm_gui_set, state
      widget_control, event.top, SET_UVALUE=state
   end

   'menu_cal': begin
      state.par.cal = event.value
      atm_gui_set, state
      widget_control, event.top, SET_UVALUE=state
   end

   'delta_t': begin
      state.par.delta_t = event.value
      atm_gui_set, state
      widget_control, event.top, SET_UVALUE=state
   end

   't0_tab': begin
      t0 = evol_time(state.par.r0, state.par.wind, state.par.weight)
      title = "ATM evolution time of turbulence GUI"
      sub_title = "t0 [s]"
      dummy = trans_tab_gui(t0, 5E-7, 6/5., title, sub_title, $
                            GROUP_LEADER=event.top            )
   end

   'r0' : begin
      state.par.r0 = event.value
      atm_gui_set, state
      widget_control, event.top, SET_UVALUE=state
   end

   'r0_tab': begin
      title = "ATM Fried parameter GUI"
      sub_title = "r0 [m]"
      dummy = trans_tab_gui(state.par.r0, 5E-7, 6/5., title, sub_title, $
                            GROUP_LEADER=event.top)
   end

   'L0' : begin
      state.par.L0 = event.value
      atm_gui_set, state
      widget_control, event.top, SET_UVALUE=state
   end

   'n_lay': begin
      state.par.n_layers = event.value
      atm_gui_set, state
      widget_control, event.top, SET_UVALUE=state
   end

   'table_atm': if (event.type eq 0) then begin
      widget_control, event.id,  GET_VALUE =dummy
      np = state.par.n_layers
      state.par.alt    = 0 & state.par.alt   [0:np-1] = dummy[0,*]
      state.par.weight = 0 & state.par.weight[0:np-1] = dummy[1,*]
      state.par.wind   = 0 & state.par.wind  [0:np-1] = dummy[2,*]
      state.par.dir    = 0 & state.par.dir   [0:np-1] = dummy[3,*]/!RADEG
      atm_gui_set, state
      widget_control, event.top,  SET_UVALUE=state
   endif

   'sam_r0_tab': begin
      title = "ATM Fried parameter sampling GUI"
      sub_title = "pixels/r0"
      sam_r0 = state.par.r0 * state.par.dim/state.par.length
      dummy = trans_tab_gui(sam_r0, 5E-7, 1., title, sub_title, $
                            GROUP_LEADER=event.top)
   end

   'fov_tab': begin
      title = "ATM  maximum field-of-view GUI"
      sub_title = "fov ['']"
      fov = 5E-7 * state.par.dim/state.par.length * 3600. * !RADEG
      dummy = trans_tab_gui(fov, 5E-7, 1., title, sub_title, $
                         GROUP_LEADER=event.top)
   end

   'menu_lps': begin
      state.par.lps = event.value
      atm_gui_set, state
      widget_control, event.top, SET_UVALUE=state
   end

   'psg_add': begin
      state.par.psg_add = event.value
      atm_gui_set, state
      widget_control, event.top, SET_UVALUE=state
   end

   'menu_meth': begin
      state.par.method = event.value
      atm_gui_set, state
      widget_control, event.top, SET_UVALUE=state
   end

   'dim': begin
      state.par.dim = event.value
      atm_gui_set, state
      widget_control, event.top, SET_UVALUE=state
   end

   'length': begin
      state.par.length = event.value
      atm_gui_set, state
      widget_control, event.top, SET_UVALUE=state
   end

   'menu_mod': begin
      state.par.model = event.value
      atm_gui_set, state
      widget_control, event.top, SET_UVALUE=state
   end

   'sha': begin
      state.par.sha = event.value
      widget_control, event.top, SET_UVALUE=state
   end

   'zern_rad_degree': BEGIN 
      state.par.zern_rad_degree = event.value
      WIDGET_CONTROL, event.top, SET_UVALUE=state
   END 

   'sha_test': begin
      dummy = sha_test_gui(                      $
                          state.par.sha,         $
                          state.par.model,       $
                          state.par.length,      $
                          state.par.L0,          $
                          GROUP_LEADER=event.top $
                          )
      state.par.sha = dummy
      widget_control, state.id.sha, SET_VALUE =state.par.sha
      widget_control, event.top,    SET_UVALUE=state
   end

   'seed1': begin
      state.par.seed1 = event.value
      widget_control, event.top, SET_UVALUE=state
   end

   'seed2': begin
      state.par.seed2 = event.value
      widget_control, event.top, SET_UVALUE=state
   end

   'save': begin

      ; Kolmogorov model means infinite wave-front outer-scale
      if (state.par.model eq 0) then state.par.L0=!VALUES.F_INFINITY

      ; first (dummy) checks...
      if (state.par.length le 0.) then begin
         dummy = dialog_message("screens' length MUST BE greater than zero", $
                                DIALOG_PARENT=event.top,                     $
                                TITLE='ATM error',                           $
                                /ERROR                                       )
         return
      endif
      if (state.par.r0 le 0.) then begin
         dummy = dialog_message("Fried parameter r0 MUST BE greater than zero",$
                                DIALOG_PARENT=event.top,                       $
                                TITLE='ATM error',                             $
                                /ERROR                                         )
         return
      endif
      if (state.par.dim le 0) then begin
         dummy = dialog_message("screens' dimension MUST BE greater than zero",$
                                DIALOG_PARENT=event.top,                       $
                                TITLE='ATM error',                             $
                                /ERROR                                         )
         return
      endif
      if (state.par.model ne 0) then begin
         if (state.par.L0 le 0) then begin
            dummy = dialog_message(                                    $
                    "wavefront outer-scale MUST BE greater than zero", $
                    DIALOG_PARENT=event.top,                           $
                    TITLE='ATM error',                                 $
                    /ERROR                                             )
            return
         endif
      endif
      if (state.par.cal eq 0) then begin
         if (state.par.delta_t le 0) then begin
            dummy = dialog_message("time base MUST BE greater than zero", $
                                   DIALOG_PARENT=event.top,               $
                                   TITLE='ATM error',                     $
                                   /ERROR                                 )
            return
         endif
      endif
      if (state.par.method eq 0) then begin
         if (state.par.sha lt 0) then begin
            dummy = dialog_message(["the nb of subharmonics to be added", $
                                    "MUST BE greater or equal to zero"],  $
                                   DIALOG_PARENT=event.top,               $
                                   TITLE='ATM error',                     $
                                   /ERROR                                 )
            return
         endif
      endif

      ; check if Cn2(h) sum over altitude is equal to 1
      if state.par.turnatmos then begin
         sum_Cn2 = total(state.par.weight[0:state.par.n_layers-1])
         if ( abs(sum_Cn2-1) ge 1e-6 ) then begin
            dummy = dialog_message(                                         $
               ['total sum of the relative weights of the',                 $
               'turbulent layers MUST BE 1 (not '+strtrim(sum_Cn2, 2)+')'], $
               DIALOG_PARENT=event.top, TITLE='ATM error', /ERROR)
            return
         endif
      endif

      ; check the wind directions in case of temporal evolution AND use of
      ; already computed STRIPES
      if ((state.par.cal eq 0) and (state.par.lps eq 0)) then begin
         error = psg_openr_cube(unit, state.par.psg_add, header, /GET_LUN)
         FREE_LUN, unit
         if (header.dim_x ne header.dim_y) then begin    ; stripes case
            for i = 0, state.par.n_layers-1 do begin
               if (state.par.dir[i] ne 0.           $
               and state.par.dir[i] ne 90./!RADEG   $
               and state.par.dir[i] ne 180./!RADEG  $
               and state.par.dir[i] ne 270./!RADEG) $
               then begin
                  dummy = dialog_message(                                  $
                     ['in this case, the wind direction MUST BE 0 or',     $
                      '90 deg. (x-dir.), or 180 or 270 deg. (y-dir.)'], $
                     DIALOG_PARENT=event.top, TITLE='ATM error', /ERROR)
                  return
               endif
            endfor
         endif
      endif

      ; check that wind directions are angles (in case of temporal evolution)
      if (state.par.cal eq 0) then begin
         for i = 0, state.par.n_layers-1 do begin
            if (state.par.dir[i] lt 0. or state.par.dir[i] gt 2*!PI) then begin
               dummy = dialog_message(['wind directions MUST BE angles',  $
                                       'between 0 deg. and 360 deg. !!'], $
                                      DIALOG_PARENT=event.top,            $
                                      TITLE='ATM error', /ERROR)
               return
            endif
         endfor
      endif

      ; check that wind velocities have positive values (in case of temp. evol.)
      if (state.par.cal eq 0) then begin
         for i = 0, state.par.n_layers-1 do begin
            if (state.par.wind[i] lt 0.) then begin
               dummy = dialog_message(                         $
                  'wind velocities MUST HAVE positive values', $
                  DIALOG_PARENT=event.top, TITLE='ATM error', /ERROR)
               return
            endif
         endfor
      endif


      ; do the following checks only if phase screen generation is desired
      if (state.par.lps eq 1) then begin

            ;; checking that desired number of Zernike polynomials is within range of
            ;; covariance matrix in file given by par.add_covmat
            RESTORE,state.par.add_covmat
            l_dim    = l_sprs.ija[0] - 2
            jmin     = 2L
            sup_jmax = l_dim + jmin - 1             ;Max. Zernike polynomial in cov matrix.
            sup_nmax = LONG(SQRT(2*sup_jmax)-1)     ;Radial order corresponding to sup_jmax.

            IF ((state.par.zern_rad_degree LT 1 )  OR                           $
                (state.par.zern_rad_degree GT sup_nmax)) THEN BEGIN 
               dummy =                                                          $
                 DIALOG_MESSAGE(['par specifies that COVARIANCE matrix for the',$
                                 'Zernike modes is read from file:            ',$
                                 ''                                            ,$
                                 '  '+state.par.add_covmat                     ,$
                                 ''                                            ,$
                                 'for which maximum Zernike radial degree MUST',$
                                 'BE =>1  and less or equal to' +               $
                                 STRCOMPRESS(sup_nmax)],                        $
                                 TITLE='ATM error', DIALOG_PARENT=atm_gui,/ERROR)
               state.par.zern_rad_degree = sup_nmax
               WIDGET_CONTROL, state.id.zern_rad_degree, SET_VALUE=state.par.zern_rad_degree
               return
            ENDIF 

            if (state.par.dim/2 ne state.par.dim/float(2)) then begin
               dummy = dialog_message(                            $
                  'phase screens linear nb of pix. MUST BE even', $
                  DIALOG_PARENT=event.top, TITLE='ATM error', /ERROR)
               return
            endif

      endif

      ; check before saving the parameter file if filename already exists
      check_file = findfile(state.sav_file)
      if check_file[0] ne "" then begin
         dummy = dialog_message(['file '+state.sav_file+' already exists.', $
            'would you like to overwrite it ?'],                            $
            DIALOG_PARENT=event.top, TITLE='ATM warning', /QUEST)
         if strlowcase(dummy) eq "no" then return
      endif else begin
         dummy = dialog_message(['file '+state.sav_file+' will be saved.'], $
                               DIALOG_PARENT=event.top,                    $
                               TITLE='ATM information',                    $
                               /INFO                                       )
         ; inform were the parameters will be saved
      endelse

      ; save the parameter data file
      par = state.par
      save, par, FILENAME=state.sav_file

      ; kill the GUI returning a null error
      error = !caos_error.ok
      widget_control, event.top, /DESTROY

   end

   'help' : online_help, book=(atm_info()).help, /FULL_PATH

   'restore': begin

      ; restore the desired parameter file
      par = 0
      title = "parameter file to restore"
      restore, filename_gui(state.def_file,                          $
                            title,                                   $
                            GROUP_LEADER=event.top,                  $
                            FILTER=state.par.module.mod_name+'*sav', $
                            /NOEDIT,                                 $
                            /MUST_EXIST,                             $
                            /ALL_EVENTS                              )

      ; update the current module number
      par.module.n_module = state.par.module.n_module

      ; set the default values for all the widgets
      widget_control, state.id.turnatmos,  SET_VALUE=par.turnatmos
      widget_control, state.id.cal,        SET_VALUE=par.cal
      widget_control, state.id.delta_t,    SET_VALUE=par.delta_t
      widget_control, state.id.r0,         SET_VALUE=par.r0
      widget_control, state.id.L0,         SET_VALUE=par.L0
      widget_control, state.id.n_lay,      SET_VALUE=par.n_layers
      widget_control, state.id.psg_add,    SET_VALUE=par.psg_add
      widget_control, state.id.lps,        SET_VALUE=par.lps
      widget_control, state.id.method,     SET_VALUE=par.method
      widget_control, state.id.length,     SET_VALUE=par.length
      widget_control, state.id.width,      SET_VALUE=par.length
      widget_control, state.id.dim,        SET_VALUE=par.dim
      widget_control, state.id.model,      SET_VALUE=par.model
      widget_control, state.id.sam_r0, $
         SET_VALUE=par.r0*par.dim/par.length
      widget_control, state.id.fov,    $
         SET_VALUE=5E-7*par.dim/par.length*!RADEG*3600.
      widget_control, state.id.sha,        SET_VALUE=par.sha
      np = par.n_layers & atm_val = fltarr(4, np)
      atm_val[0,*] = par.alt   [0:np-1]
      atm_val[1,*] = par.weight[0:np-1]
      atm_val[2,*] = par.wind  [0:np-1]
      atm_val[3,*] = par.dir   [0:np-1]/!RADEG
      widget_control, state.id.atm,        SET_VALUE=atm_val

      ; update the state structure
      state.par = par

      ; reset the setting parameters status
      atm_gui_set, state

      ; write the GUI state structure
      widget_control, event.top, SET_UVALUE=state

   end

   'cancel': begin
      error = !caos_error.cancel
      widget_control, event.top, /DESTROY
   end

endcase

end

;;;;;;;;;;;;;;;;;;;;;;;
; GUI generation code ;
;;;;;;;;;;;;;;;;;;;;;;;
;
function atm_gui, n_module, proj_name, GROUP_LEADER=group

; error status from the event handler procedure
common error_block, error

; retrieve the module information
info = atm_info()

; check if a saved parameter file exists. If it exists it is restored,
; otherwise the default parameter file is restored.
sav_file = mk_par_name(info.mod_name, n_module, PROJ_NAME=proj_name)
def_file = mk_par_name(info.mod_name, PACK_NAME=info.pack_name, /DEFAULT)
par=0
;print, 'line 738', par
check_file = findfile(sav_file)
;print, 'line 740', par
if check_file[0] eq '' then begin
   restore, def_file
   par.module.n_module = n_module
   ;print, 'line 744', par
   if par.module.mod_name ne info.mod_name then        $
      message, 'the default parameter file ('+def_file $
              +') is from another module: please take the right one'
   if (par.module.ver ne info.ver) then       $
      message, 'the default parameter file ('+def_file $
              +') is not compatible: please generate it again'
endif else begin
   restore, sav_file
   ;print, sav_file
   ;print, 'line 753', par
   if (par.module.mod_name ne info.mod_name) then $
      message, 'the parameter file '+sav_file     $
               +' is from another module: please generate a new one'
   ;print, 'line 757', par
   if (par.module.ver ne info.ver) then begin
      print, '************************************************************'
      print, 'WARNING: the parameter file '+sav_file
      print, 'is probably from an older version than '+info.pack_name+' !!'
      print, 'You should possibly need to generate it again...'
      print, '************************************************************'
   endif
   ;print, 'line 765', par
endelse
;print, 'line 767', par

atm_val      = fltarr(4, par.n_layers)
atm_val[0,*] = par.alt   [0:par.n_layers-1]
atm_val[1,*] = par.weight[0:par.n_layers-1]
atm_val[2,*] = par.wind  [0:par.n_layers-1]
atm_val[3,*] = par.dir   [0:par.n_layers-1]/!RADEG

id = $
   { $
   turnatmos      : 0L, $
   par_base       : 0L, $
   cal            : 0L, $
   delta_t        : 0L, $
   evol_t         : 0L, $
   t0_tab         : 0L, $
   r0             : 0L, $
   r0_tab         : 0L, $
   L0             : 0L, $
   n_lay          : 0L, $
   atm            : 0L, $
   lps            : 0L, $
   psg            : 0L, $
   read_ps        : 0L, $
   psg_add        : 0L, $
   psg_nscreens   : 0L, $
   psg_dimx       : 0L, $
   psg_dimy       : 0L, $
   psg_L0         : 0L, $
   psg_model      : 0L, $
   psg_meth       : 0L, $
   psg_sha        : 0L, $
   psg_prec       : 0L, $
   psg_seed1      : 0L, $
   psg_seed2      : 0L, $
   method         : 0L, $
   length         : 0L, $
   width          : 0L, $
   dim            : 0L, $
   model          : 0L, $
   sam_r0         : 0L, $
   sam_r0_tab     : 0L, $
   fov            : 0L, $
   fov_tab        : 0L, $
   rec_sha        : 0L, $
   sha            : 0L, $
   zern_rad_degree: 0L, $
   title_sha      : 0L, $
   sha_test       : 0L, $
   seed1          : 0L, $
   seed2          : 0L  $
   }

state = $
   {    $
   sav_file: sav_file, $
   def_file: def_file, $
   id      : id,       $
   par     : par       $
   }

modal = n_elements(group) ne 0
title = strupcase(info.mod_name)+" parameters setting GUI"
root_base_id = widget_base(TITLE=title, MODAL=modal, /COL, GROUP_LEADER=group)
widget_control, root_base_id, SET_UVALUE=state
   
   ; parameters base
   state.id.par_base = widget_base(root_base_id, FRAME=10, COL=2)

   left_base_id = widget_base(state.id.par_base, /COL)

      turn_base_id = widget_base(left_base_id, ROW=2, /FRAME)

         dummy = widget_label(turn_base_id, $
            VALUE="turbulent atmosphere control", /FRAME)

         state.id.turnatmos = cw_bgroup(turn_base_id, $
            ['turn off !','turn on !'],               $
            SET_VALUE=state.par.turnatmos, UVALUE='turnatmos', COLUMN=2, /EXCLUSIVE)


      cal_base_id = widget_base(left_base_id, ROW=4, /FRAME)

         dummy = widget_label(cal_base_id, $
            VALUE='type of calculation', /FRAME)

         state.id.cal = cw_bgroup(cal_base_id,               $
            ['temporal evolution', 'statistical averaging'], $
            SET_VALUE=state.par.cal, UVALUE='menu_cal', COLUMN=2, /EXCLUSIVE)

         dummy = widget_base(cal_base_id, COL=2)
            state.id.delta_t = cw_field(dummy,            $
               TITLE='time-base [s]', /COLUMN,            $
               VALUE=state.par.delta_t, UVALUE='delta_t', $
               /FLOATING, /ALL_EVENTS)
            state.id.evol_t = cw_field(dummy,                          $
               TITLE='(evolution time of turbulence t0 [s] (@500nm))', $
               /COLUMN, /NOEDIT, /FLOATING)

         state.id.t0_tab = widget_button(cal_base_id,                         $
                                         VALUE=                               $
            "(t0 vs. central wavelengths of pre-defined bands (Johnson+Na))", $
                                         UVALUE="t0_tab"                    )

      atm_base_id = widget_base(left_base_id, /FRAME, ROW=6)

         dummy = widget_label(atm_base_id, $
            VALUE='atmosphere parameters', /FRAME)

         lay_base_id = widget_base(atm_base_id, COLUMN=2)
            state.id.n_lay = cw_field(lay_base_id,       $
               TITLE="nb of turbulent layers: ",         $
               VALUE=state.par.n_layers, UVALUE='n_lay', $
               /INTEGER, /RETURN_EVENTS)
            dummy = widget_label(lay_base_id, VALUE='(HIT RETURN !!)')

         dummy = widget_label(atm_base_id, $
            VALUE='characteristics of the turbulent layers')

         state.id.atm = widget_table(atm_base_id, $
            ROW_LABELS='layer #'+strtrim(indgen(state.par.n_layers),2),   $
            COLUMN_LABELS=["h [m]", "Cn2 ratio", "v [m/s]", "dir [deg]"], $
            VALUE=atm_val, UVALUE='table_atm', /EDITABLE, YSIZE=5)

         state.id.r0 = cw_field(atm_base_id,           $
            TITLE="Fried parameter r0 [m] (@500nm): ", $
            VALUE=state.par.r0, UVALUE='r0', /FLOATING, /ALL_EVENTS)

         state.id.r0_tab = widget_button(atm_base_id,                         $
                                         VALUE=                               $
            "(r0 vs. central wavelengths of pre-defined bands (Johnson+Na))", $
                                         UVALUE="r0_tab"                      )

      layers_base_id = widget_base(left_base_id, /FRAME, ROW=6)

         dummy = widget_label(layers_base_id,                $
                              VALUE="layers' phase screens", $
                              /FRAME)

         state.id.lps = cw_bgroup(layers_base_id,                        $
                                  ['use already computed phase screens', $
                                   'generate new ones'],                 $
                                  SET_VALUE=state.par.lps,               $
                                  UVALUE='menu_lps',                     $
                                  COLUMN=2,                              $
                                  /EXCLUSIVE                             )

         dummy = widget_base(layers_base_id, COL=2)
            state.id.length = cw_field(dummy,                                $
                                       TITLE="screens' physical length [m]", $
                                       /COLUMN,                              $
                                       VALUE=state.par.length,               $
                                       UVALUE='length',                      $
                                       /FLOATING,                            $
                                       /ALL_EVENTS                           )
            state.id.width = cw_field(dummy,                                 $
                                      TITLE="(screens' physical width [m])", $
                                      /COLUMN,                               $
                                      VALUE=state.par.length,                $
                                      /FLOATING,                             $
                                      /NOEDIT                                )

         dummy = widget_base(layers_base_id, COL=2)
            state.id.sam_r0 = cw_field(dummy,                                 $
                                       TITLE="(r0 sampling [px/r0] (@500nm))",$
                                       /COLUMN,                               $
                                       VALUE=state.par.r0*state.par.dim       $
                                            /state.par.length,                $
                                       /FLOATING,                             $
                                       /NOEDIT                                )
            state.id.fov= cw_field(dummy,                                     $
                                   TITLE="(field-of-view [arcsec] (@500nm))", $
                                   /COLUMN,                                   $
                                   VALUE=5E-7*state.par.dim/state.par.length  $
                                        *!RADEG*3600.,                        $
                                   /FLOATING,                                 $
                                   /NOEDIT                                    )

         state.id.sam_r0_tab = widget_button(layers_base_id,                 $
                                             VALUE=                          $
   "(ro sampling vs. central wavelengths of pre-defined bands (Johnson+Na))",$
                                             UVALUE="sam_r0_tab"             )

         state.id.fov_tab = widget_button(layers_base_id,                     $
                                          VALUE=                              $
         "(f-o-v vs. central wavelengths of pre-defined bands (Johnson+Na))", $
                                          UVALUE="fov_tab"                    )


   right_base_id = widget_base(state.id.par_base, /COL)

      state.id.read_ps = widget_base(right_base_id, /FRAME, ROW=6)

         dummy = widget_label(state.id.read_ps,           $
                              VALUE='phase screens file', $
                              /FRAME                      )

         state.id.psg_add = cw_filename(state.id.read_ps,                   $
                                        TITLE="phase screens file address", $
                                        VALUE=state.par.psg_add,            $
                                        UVALUE='psg_add',                   $
                                        /RETURN_EVENTS                      )

         dummy = widget_base(state.id.read_ps, COL=3)
            state.id.psg_dimx = cw_field(dummy,                         $
                                         TITLE="(screens' x-dim [px])", $
                                         /COLUMN,                       $
                                         /INTEGER,                      $
                                         /NOEDIT                        )
            state.id.psg_dimy = cw_field(dummy,                         $
                                         TITLE="(screens' y-dim [px])", $
                                         /COLUMN,                       $
                                         /INTEGER,                      $
                                         /NOEDIT                        )
            state.id.psg_nscreens = cw_field(dummy,                     $
                                             TITLE="(nb of screens)",   $
                                             /COLUMN,                   $
                                             /INTEGER,                  $
                                             /NOEDIT                    )

         dummy = widget_base(state.id.read_ps, COL=3)
            state.id.psg_meth = cw_field(dummy,                             $
                                         TITLE="(computing method)",        $
                                         /COLUMN,                           $
                                         /NOEDIT                            )
            state.id.psg_model = cw_field(dummy,                            $
                                          TITLE="(atmospheric model)",      $
                                          /COLUMN,                          $
                                          /NOEDIT                           )
            state.id.psg_sha = cw_field(dummy,                              $
                                        TITLE="(nb of subharmonics added)", $
                                        /COLUMN,                            $
                                        /INTEGER,                           $
                                        /NOEDIT                             )

         dummy = widget_base(state.id.read_ps, COL=3)
            state.id.psg_prec = cw_field(dummy,                        $
                                         TITLE="(precision)",          $
                                         /COLUMN,                      $
                                         /NOEDIT                       )
            state.id.psg_seed1= cw_field(dummy,                        $
                                         TITLE="(FFT/Zernike seed)",   $
                                         /COLUMN,                      $
                                         /INTEGER,                     $
                                         /NOEDIT                       )
            state.id.psg_seed2 = cw_field(dummy,                       $
                                          TITLE="(subharmonics seed)", $
                                          /COLUMN,                     $
                                          /INTEGER,                    $
                                          /NOEDIT                      )

         state.id.psg_L0 = cw_field(state.id.read_ps,                      $
                                    TITLE="(wf outer scale L0 [m]): ",     $
                                    /FLOATING,                             $
                                    /NOEDIT                                )

      state.id.psg = widget_base(right_base_id, /FRAME, ROW=4)

         dummy = widget_label(state.id.psg,                    $
                              VALUE='phase screen generation', $
                              /FRAME                           )

         dummy = widget_base(state.id.psg, COLUMN=3)

            state.id.method = cw_bgroup(dummy,                        $
                                        LABEL_TOP='computing method', $
                                        ['FFT (+ subharmonics)',      $
                                         'Zernike polynomials'],      $
                                        SET_VALUE=state.par.method,   $
                                        UVALUE='menu_meth',           $
                                        /EXCLUSIVE                    )

            state.id.model = cw_bgroup(dummy,                         $
                                       LABEL_TOP="atmospheric model", $
                                       ['Kolmogorov', 'von Karman'],  $
                                       SET_VALUE=state.par.model,     $
                                       UVALUE='menu_mod',             $
                                       /EXCLUSIVE                     )

            dumdummy = widget_base(dummy, ROW=2)

               state.id.seed1 = cw_field(dumdummy,                    $
                                         TITLE="FFT/Zernike seed",    $
                                         /COLUMN,                     $
                                         VALUE=state.par.seed1,       $
                                         /LONG,                       $
                                         UVALUE='seed1',              $
                                         /ALL_EVENTS                  )

               state.id.seed2 = cw_field(dumdummy,                    $
                                         TITLE="subharmonics seed",   $
                                         /COLUMN,                     $
                                         VALUE=state.par.seed2,       $
                                         /LONG,                       $
                                         UVALUE='seed2',              $
                                         /ALL_EVENTS                  )

         dummy = widget_base(state.id.psg, ROW=2)

            dummy_base = widget_base(dummy, COL=2)

               dumdummy = widget_base(dummy_base, ROW=2)

                  label = widget_label(dumdummy, VALUE=" ")

                  state.id.sha_test = widget_button(dumdummy,               $
                     VALUE='PUSH HERE to test subharmonics adding accuracy !!',$
                     UVALUE='sha_test'                                        )

            dummy_base = widget_base(dummy, /COL)

               state.id.title_sha = widget_label(dummy_base,                $
                                                 VALUE='nb of subharmonics' )

               dumdummy = widget_base(dummy_base, COL=2)

                  state.id.rec_sha = cw_field(dumdummy,              $
                                              TITLE='(recommended)', $
                                              /COLUMN,               $
                                              VALUE=state.par.sha,   $
                                              UVALUE='rec_sha',      $
                                              /NOEDIT,               $
                                              XSIZE=3                )

                  state.id.sha     = cw_field(dumdummy,              $
                                              TITLE='desired',       $
                                              /COLUMN,               $
                                              VALUE=state.par.sha,   $
                                              /INTEGER,              $
                                              UVALUE='sha',          $
                                              /ALL_EVENTS,           $
                                              XSIZE=3                )

            dummy_base = widget_base(dummy, COL=3)

                  state.id.dim = cw_field(dummy_base,                      $
                                          TITLE='x- and y-dimension [px]', $
                                          /COLUMN,                         $
                                          VALUE=state.par.dim,             $
                                          UVALUE='dim',                    $
                                          /INTEGER,                        $
                                          /ALL_EVENTS                      )

                  state.id.L0 = cw_field(dummy_base,                       $
                                         TITLE="wf outer scale L0 [m]",    $
                                         /COLUMN,                          $
                                         VALUE=state.par.L0,               $
                                         /FLOATING,                        $
                                         UVALUE='L0',                      $
                                         /ALL_EVENTS                       )

                  state.id.zern_rad_degree = cw_field(dummy_base,          $
                                         TITLE='max. Zernike radial degree',$
                                         VALUE=state.par.zern_rad_degree,  $
                                         /INTEGER,                         $
                                         UVALUE='zern_rad_degree',         $
                                         /ALL_EVENTS,                      $
                                         /COLUMN                           )


   ; base for footnote
   note_base_id = widget_base(right_base_id, /COL, FRAME=10)
      dummy = ['NOTE:',                                                        $
               'The parameters with a title in between brackets - "(title)"'   $
               +' and not "title" - have non-editable fields: they cannot be'  $
               +' changed.'                                                    ]
      dummy = widget_text(note_base_id, $
                          VALUE=dummy,  $
                          YSIZE=N_ELEMENTS(dummy))


   ; button base for control buttons (standard buttons)
   btn_base_id = widget_base(right_base_id, FRAME=10, /ROW)
      dummy = widget_button(btn_base_id, VALUE="HELP", UVALUE="help")
      cancel_id = widget_button(btn_base_id, VALUE="CANCEL", UVALUE="cancel")
      if modal then widget_control, cancel_id, /CANCEL_BUTTON
      dummy = widget_button(btn_base_id, VALUE="RESTORE PARAMETERS", $
                            UVALUE="restore")
      save_id = widget_button(btn_base_id, VALUE="SAVE PARAMETERS", $
                              UVALUE="save")
      if modal then widget_control, save_id, /DEFAULT_BUTTON

; initialize all the sensitive states
atm_gui_set, state

; save the state structure of the GUI in the top base uvalue
widget_control, root_base_id, SET_UVALUE=state

; draw the GUI
widget_control, root_base_id, /REALIZE

xmanager, 'atm_gui', root_base_id, GROUP_LEADER=group

return, error
end
