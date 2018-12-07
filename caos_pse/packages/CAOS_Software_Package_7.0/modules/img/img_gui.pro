; $Id: img_gui.pro,v 7.0 2016/05/19 marcel.carbillet $
;+
; NAME:
;    img_gui
;
; PURPOSE:
;    img_gui generates the Graphical User Interface (GUI) for
;    setting the parameters of the IMaGer (IMG) module.
;    A parameter file called img_yyyyy.sav is created, where yyyyy
;    is the number n_module associated to the the module instance.
;    The file is stored in the project directory proj_name located
;    in the working directory.
;
; CATEGORY:
;    Graghical User Interface (GUI) program
;
; CALLING SEQUENCE:
;    error = img_gui(n_module, proj_name)
;
; INPUTS:
;    n_module:   integer scalar. Number associated to the intance
;                of the IMG module. n_module > 0.
;    proj_name:  string. Name of the current project.
;
; OUTPUTS:
;    error    :  long scalar. Error code (see caos_init procedure).
;
; COMMON BLOCKS:
;    none.
;
; CALLED NON-IDL FUNCTIONS:
;    None.
;
; MODIFICATION HISTORY:
;    program written: Dec 1999,
;                     Bruno Femenia (OAA) [bfemenia@arcetri.astro.it]
;
;    modifications  : may 2000,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -call to help file debugged.
;                   : B. Femenia (OAA) [bfemenia@arcetri.astro.it]
;                    -IDL 5.4 handles SEEDs in calls to RANDOM such that now
;                     the initial seed has to be fed. Now having control
;                     over seeds to generate noise.
;                     !! keeped compatibility with previous parameters structure !!
;                        (as a consequence the new tags seed_ron, seed_dark, and
;                        seed_pn are not visible when loading an old parameter
;                        file, and restoring of the new default file is not
;                        possible => in that case first kill the old parameter
;                        file and then set again the parameters.)
;                   : october 2002,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -option for background adding (or not!) added.
;                     !! kept compatibility with previous parameters structure !!
;                        (as a consequence the new tag backgradd is not visible
;                        when loading an old parameter file, and restoring of
;                        the new default file is not possible => in that case
;                        first kill the old parameter file and then set again
;                        the parameters.)
;                    -improved help about the compatibility question.
;                   : january 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -adapted to version 4.0 of the whole Software System CAOS
;                     (variable "pack_name" added, and variable "mod_type"
;                     changed into "mod_name").
;                    -(img_info()).help stuff added (instead of !caos_env.help).
;                   : march 2003,
;                     B. Femenia (GTC) [bfemenia@ll.iac.es]
;                    -merging versions at OAA and GTC.
;                   : september 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -GUI arranged (better fitting for laptop screens...)
;                   : december 2004,
;                     Marcel Carbillet (LUAN) [marcel.carbillet@unice.fr]:
;                    -no more crash provoked when controlling the Soft.Pack.
;                     version for existing parameter files - just a warning.
;                   : february 2007,
;                     Marcel Carbillet (LUAN) [marcel.carbillet@unice.fr]:
;                    -control of the the Soft.Pack. debugged (the warning was
;                     here *always* (partly) printed )...
;                   : may 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr],
;                     Andrea La Camera (DIBRIS) [andrea.lacamera@unige.it]:
;                    -New way to call CAOS_HELP (by using the "online_help" 
;                     routine, independent from the operating system used.
;                    -adapted to Soft. Pack. CAOS 7.0.
;-
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; status setting procedure ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
PRO img_set, state

   COMMON wavelengths, band_tab, lambda_tab, width_tab, flag_band, f_band

   status = TAG_EXIST(state.par,'seed_pn')
   IF status THEN BEGIN 
      IF state.par.noise[0] THEN                       $
        WIDGET_CONTROL,state.id.seed_pn, /SENSITIVE    $
      ELSE                                             $
        WIDGET_CONTROL,state.id.seed_pn,  SENSITIVE=0
   ENDIF 


   CASE state.par.noise[1]  OF

       0: BEGIN
          WIDGET_CONTROL,state.id.read_noise, SENSITIVE=0
          IF TAG_EXIST(state.par,'seed_ron') THEN $
            WIDGET_CONTROL,state.id.seed_ron, SENSITIVE=0
       END 

       1: BEGIN
          WIDGET_CONTROL,state.id.read_noise, /SENSITIVE
          IF TAG_EXIST(state.par,'seed_ron') THEN $
            WIDGET_CONTROL,state.id.seed_ron, /SENSITIVE
       END 

   ENDCASE


   CASE state.par.noise[2] OF

      0: BEGIN 
         WIDGET_CONTROL,state.id.dark_noise, SENSITIVE=0
         IF TAG_EXIST(state.par,'seed_dark') THEN $
           WIDGET_CONTROL,state.id.seed_dark,SENSITIVE=0
      END 

       1: BEGIN 
          WIDGET_CONTROL,state.id.dark_noise, /SENSITIVE
          IF TAG_EXIST(state.par,'seed_dark') THEN $
            WIDGET_CONTROL,state.id.seed_dark,/SENSITIVE
       END 

   ENDCASE


   IF (state.par.foc_dist NE !VALUES.F_INFINITY) THEN BEGIN
       WIDGET_CONTROL,state.id.foc_dist, /SENSITIVE
       WIDGET_CONTROL,state.id.foc_dist, SET_VALUE= state.par.foc_dist
   ENDIF ELSE BEGIN
       WIDGET_CONTROL,state.id.foc_dist, SENSITIVE= 0 
       WIDGET_CONTROL,state.id.foc_dist, SET_VALUE= !VALUES.F_INFINITY
   ENDELSE


   ;;Indicating in GUI which bands have been selected
   ;;------------------------------------------------

   dummy  = CLOSEST(state.par.lambda,lambda_tab)
   value  = INTARR(N_ELEMENTS(band_tab))
   n_band = N_ELEMENTS(band_tab)
   f_band = FLTARR(n_band)

   IF ((state.par.lambda*state.par.width NE 0) AND (dummy GT -1)) THEN BEGIN 

      IF (((state.par.lambda - lambda_tab[dummy]) LT 1e-12)  AND        $
          ((state.par.width  - width_tab[dummy ]) LT 1e-12)) THEN BEGIN 

      
         flag_band     = 0B                                 ;Indicates a single band!!
         value[dummy]  = 1
         f_band[dummy] = 1.
         
      ENDIF ELSE BEGIN 
         
         flag_band = 1B                                     ;Indicates wavelength range spans over more than 1 band
         lambda1   = state.par.lambda - state.par.width/2
         lambda2   = state.par.lambda + state.par.width/2
         
         FOR i=0,n_band-1 DO BEGIN
            band1 = lambda_tab[i]-width_tab[i]/2.
            band2 = lambda_tab[i]+width_tab[i]/2.
            f_band[i] = INTERVAL2(lambda1, lambda2, band1, band2, d1, d2)
            lambda1 = d1
            lambda2 = d2
         ENDFOR 
         
         r1 = WHERE(f_band GT 0., c1)
         IF (c1 GT 0) THEN $
           value[r1] = 1.  $
         ELSE              $
           MESSAGE,'Bandwidth selected not within the standard bands. Check!!'
         
      ENDELSE
      
   ENDIF ELSE BEGIN 
;       state.par.lambda = 0.
;       state.par.width  = 0.
   ENDELSE 

   WIDGET_CONTROL,state.id.band  ,SET_VALUE= value
;    WIDGET_CONTROL,state.id.lambda,SET_VALUE= state.par.lambda*1e9
;    WIDGET_CONTROL,state.id.width ,SET_VALUE= state.par.width*1e9
   
END



;;;;;;;;;;;;;;;;;;;;;;
; img_gui event loop ;
;;;;;;;;;;;;;;;;;;;;;;
;
PRO img_gui_event, event

COMMON error_block, error
COMMON wavelengths, band_tab, lambda_tab, width_tab, flag_band, f_band

IF TAG_NAMES(event, /STRUCTURE_NAME) EQ 'WIDGET_KILL_REQUEST' THEN BEGIN
    WIDGET_CONTROL, event.top, GET_UVALUE=state
    error = !caos_error.cancel
    WIDGET_CONTROL, event.top, /DESTROY
ENDIF

WIDGET_CONTROL, event.id , GET_UVALUE = uvalue, GET_VALUE=dummy
WIDGET_CONTROL, event.top, GET_UVALUE = state

CASE uvalue OF

    'np': BEGIN
       state.par.npixel = dummy
       WIDGET_CONTROL, event.top, SET_UVALUE=state
    END


    'psize': BEGIN
       state.par.pxsize = dummy
       WIDGET_CONTROL, event.top, SET_UVALUE=state
    END


    'qe': BEGIN
       state.par.qeff = dummy
       WIDGET_CONTROL, event.top, SET_UVALUE=state
    END


    'time_integ': BEGIN
       state.par.time_integ = dummy
       WIDGET_CONTROL, event.top, SET_UVALUE=state
    END
    
    
    'time_delay': BEGIN
       state.par.time_delay = dummy
       WIDGET_CONTROL, event.top, SET_UVALUE=state
    END


    'foc_button': BEGIN
       IF (event.value EQ 0) THEN                  $
         state.par.foc_dist= !VALUES.F_INFINITY    $
       ELSE state.par.foc_dist= 9.0e4
       img_set, state
       WIDGET_CONTROL, event.top, SET_UVALUE=state
    END
    

    'foc_dist': BEGIN
       state.par.foc_dist = dummy
       WIDGET_CONTROL, event.top, SET_UVALUE=state
    END


    'menu_band': BEGIN
       r1 = WHERE(dummy GT 0, c1)
       IF (c1 GT 0) THEN BEGIN 
          min_lambda = MIN(lambda_tab[r1]-width_tab[r1]/2.)
          max_lambda = MAX(lambda_tab[r1]+width_tab[r1]/2.)
          lambda = (max_lambda+min_lambda)/2
          width  = (max_lambda-min_lambda)
          state.par.lambda= lambda 
          state.par.width = width
       ENDIF ELSE BEGIN 
          state.par.lambda= 0.
          state.par.width = 0.
       ENDELSE 
       WIDGET_CONTROL, state.id.lambda, SET_VALUE=state.par.lambda*1e9
       WIDGET_CONTROL, state.id.width,  SET_VALUE=state.par.width *1e9
       WIDGET_CONTROL, event.top, SET_UVALUE=state
       img_set, state
    END

    'increase':BEGIN
       state.par.increase= 2*event.value+1
       WIDGET_CONTROL,state.id.inc_field, SET_VALUE= state.par.increase
       WIDGET_CONTROL,event.top, SET_UVALUE=state
    END

    'noise':BEGIN
        state.par.noise= dummy
        img_set, state
        WIDGET_CONTROL, event.top, SET_UVALUE=state
    END


    'read_noise':BEGIN
       state.par.read_noise = dummy
       WIDGET_CONTROL, event.top, SET_UVALUE=state
    END

    'dark_noise':BEGIN
       state.par.dark_noise = dummy
       WIDGET_CONTROL, event.top, SET_UVALUE=state
    END

    'seed_pn':BEGIN
       state.par.seed_pn = dummy
       WIDGET_CONTROL, event.top, SET_UVALUE=state
    END 

    'seed_ron':BEGIN
       state.par.seed_ron = dummy
       WIDGET_CONTROL, event.top, SET_UVALUE=state
    END 

    'seed_dark':BEGIN
       state.par.seed_dark = dummy
       WIDGET_CONTROL, event.top, SET_UVALUE=state
    END 

    'backgradd':BEGIN
       state.par.backgradd = dummy
       WIDGET_CONTROL, event.top, SET_UVALUE=state
    END

    'lambda':BEGIN
       state.par.lambda = dummy*1e-9
       WIDGET_CONTROL, event.top, SET_UVALUE=state
       img_set, state
    END

    'width':BEGIN
       state.par.width = dummy*1e-9
       WIDGET_CONTROL, event.top, SET_UVALUE=state
       img_set, state
    END 


    'reset':BEGIN
       state.par.lambda = 0.
       state.par.width  = 0.
       WIDGET_CONTROL,state.id.lambda, SET_VALUE=state.par.lambda
       WIDGET_CONTROL,state.id.width , SET_VALUE=state.par.width
       WIDGET_CONTROL, event.top, SET_UVALUE=state
       img_set, state
    END 

    'save': BEGIN
        
        ; cross-check controls among the parameters

        IF (state.par.npixel LE 1) THEN BEGIN
           dummy = DIALOG_MESSAGE(["Linear number of pixels must be"+ $
                                   " equal or larger than 2"],        $
                                  DIALOG_PARENT=event.top,            $
                                  TITLE='IMG error',                  $
                                  /ERROR                              )
           RETURN 
        ENDIF
         

        IF (state.par.qeff LE 0 OR state.par.qeff GT 1 ) THEN BEGIN
           dummy = DIALOG_MESSAGE(["Quantum efficiency must be "    + $
                                   "larger than 0 and smaller or "  + $
                                   "equal to 1"],                     $
                                  DIALOG_PARENT=event.top,            $
                                  TITLE='IMG error',                  $
                                  /ERROR                              )
           RETURN 
        ENDIF
         
        IF (state.par.lambda*state.par.width EQ 0) THEN BEGIN 
            dummy = DIALOG_MESSAGE(["Both central wavelength and ba" + $
                                    "nwidth must be larger than 0"],   $
                                   DIALOG_PARENT=event.top,            $
                                   TITLE='IMG error',/ERROR)
           RETURN 
        ENDIF
          


        ; check before saving the parameter file if filename already exists
        ; or inform where the parameters will be saved.
        check_file = FINDFILE(state.sav_file)
        IF check_file[0] NE "" THEN BEGIN
            dummy=DIALOG_MESSAGE(['file '+state.sav_file+             $
                                  ' already exists.',                 $
                                  'Would you like to overwrite it?'], $
                                 DIALOG_PARENT=event.top,             $
                                 TITLE='IMG warning', /QUEST)
            IF STRLOWCASE(dummy) EQ "no" THEN RETURN
        ENDIF ELSE BEGIN 
           answ = dialog_message(['File '+state.sav_file+' will be '+ $
                                  'saved.'],DIALOG_PARENT=event.top,  $
                                 TITLE='IMG information',/INFO)
        ENDELSE 

        ; save the parameter data file
        par = state.par
        SAVE, par, FILENAME=state.sav_file

        ; kill the GUI returning a null error
        error = !caos_error.ok
        WIDGET_CONTROL, event.top, /DESTROY
    END


    'help' : online_help, book=(img_info()).help, /FULL_PATH


    'restore': BEGIN

       WIDGET_CONTROL, event.top, GET_UVALUE=state

       ; restore the desired parameter file
       par = 0
       title = "Parameter file to restore"
       RESTORE, filename_gui(state.def_file,                          $
                             title,                                   $
                             GROUP_LEADER=event.top,                  $
                             FILTER=state.par.module.mod_name+'*sav', $
                             /NOEDIT,                                 $
                             /MUST_EXIST,                             $
                             /ALL_EVENTS)

       ; update the current module number
       par.module.n_module = state.par.module.n_module
       
       WIDGET_CONTROL, state.id.npixel     , SET_VALUE= par.npixel
       WIDGET_CONTROL, state.id.pxsize    , SET_VALUE= par.pxsize
       WIDGET_CONTROL, state.id.qeff      , SET_VALUE= par.qeff
       WIDGET_CONTROL, state.id.time_integ, SET_VALUE= par.time_integ
       WIDGET_CONTROL, state.id.time_delay, SET_VALUE= par.time_delay
       WIDGET_CONTROL, state.id.foc_dist  , SET_VALUE= par.foc_dist
       WIDGET_CONTROL, state.id.lambda    , SET_VALUE= par.lambda*1e9
       WIDGET_CONTROL, state.id.width     , SET_VALUE= par.width*1e9
       WIDGET_CONTROL, state.id.increase  , SET_VALUE= (par.increase-1)/2
       WIDGET_CONTROL, state.id.inc_field , SET_VALUE= par.increase
       WIDGET_CONTROL, state.id.noise     , SET_VALUE= par.noise
       WIDGET_CONTROL, state.id.read_noise, SET_VALUE= par.read_noise
       WIDGET_CONTROL, state.id.dark_noise, SET_VALUE= par.dark_noise
       
       dummy= CLOSEST(par.lambda,lambda_tab)
       WIDGET_CONTROL, state.id.band, SET_VALUE=dummy
       
       IF (par.foc_dist NE !VALUES.F_INFINITY) THEN dummy= 1 $
       ELSE dummy=0
       WIDGET_CONTROL, state.id.foc_button,  SET_VALUE=dummy
       
       state.par = par
       img_set, state
       WIDGET_CONTROL, event.top, SET_UVALUE=state

       ;update SEEDS if corresponding TAGS exist in PAR structure
       IF TAG_EXIST(par,'seed_pn') THEN $
         WIDGET_CONTROL, state.id.seed_pn, SET_VALUE= par.seed_pn

       IF TAG_EXIST(par,'seed_ron') THEN $
         WIDGET_CONTROL, state.id.seed_ron, SET_VALUE= par.seed_ron

       IF TAG_EXIST(par,'seed_dark') THEN $
         WIDGET_CONTROL, state.id.seed_dark, SET_VALUE= par.seed_dark

       IF TAG_EXIST(par,'backgradd') THEN $
       WIDGET_CONTROL, state.id.backgradd , SET_VALUE= par.backgradd


    END
    
    'cancel'  : BEGIN
        error = !caos_error.cancel
        WIDGET_CONTROL, event.top, /DESTROY
    END
    
ENDCASE

END

;;;;;;;;;;;;;;;;;;;;;;;
; GUI generation code ;
;;;;;;;;;;;;;;;;;;;;;;;
;
FUNCTION img_gui, n_module, proj_name, GROUP_LEADER=group

COMMON error_block, error
COMMON wavelengths, band_tab, lambda_tab, width_tab, flag_band, f_band


; retrieve the module information
info = img_info()

; check if a saved parameter file already exists for this module.
; if it exists it is restored, otherwise the default parameter file is restored.
sav_file = MK_PAR_NAME(info.mod_name, n_module, PROJ_NAME=proj_name)
def_file = MK_PAR_NAME(info.mod_name, PACK_NAME=info.pack_name, /DEFAULT)

par = 0
check_file = FINDFILE(sav_file)
IF check_file[0] EQ '' THEN BEGIN
   RESTORE, def_file
   par.module.n_module = n_module
   IF (par.module.mod_name NE info.mod_name) THEN          $
     MESSAGE, 'the default parameter file ('+ def_file     $
     +') is from another module: please take the right one'
   IF (par.module.ver ne info.ver) THEN                    $
     MESSAGE, 'the default parameter file ('+ def_file     $
     +') is not compatible: please generate it again'   
ENDIF ELSE BEGIN
   RESTORE, sav_file
   IF (par.module.mod_name NE info.mod_name) THEN          $
     MESSAGE, 'the parameter file '+sav_file               $
     +' is from another module: please generate a new one'
   IF (par.module.ver NE info.ver) THEN begin
      print, '************************************************************'
      print, 'WARNING: the parameter file '+sav_file
      print, 'is probably from an older version than '+info.pack_name+' !!'
      print, 'You should possibly need to generate it again...'
      print, '************************************************************'
   endif
ENDELSE

dummy     = N_PHOT(1.,BAND=dummy1,LAMBDA=dummy2,WIDTH=dummy3)
band_tab  = dummy1
lambda_tab= dummy2
width_tab = dummy3

id =                $
  {                 $
    npixel    : 0L, $
    pxsize    : 0L, $
    qeff      : 0L, $
    time_integ: 0L, $
    time_delay: 0L, $
    foc_button: 0L, $
    foc_dist  : 0L, $
    band      : 0L, $
    lambda    : 0L, $
    width     : 0L, $
    noise     : 0L, $
    read_noise: 0L, $
    dark_noise: 0L, $
    increase  : 0L, $
    inc_field : 0L, $
    seed_pn   : 0L, $
    seed_ron  : 0L, $
    seed_dark : 0L, $
    backgradd : 0L, $
    reset     : 0L, $
    f_band    : 0L  $
  }

state =                  $
  {                      $
   sav_file  : sav_file, $
   def_file  : def_file, $
   id        : id      , $
   par       : par       $
   }


; ROOT BASE
;===========

modal = N_ELEMENTS(group) NE 0
title = STRUPCASE(par.module.mod_name)+' parameter setting GUI'
root  = WIDGET_BASE(TITLE=title,MODAL=modal,/COL,GROUP_LEADER=group)

WIDGET_CONTROL, root, SET_UVALUE=state  ;Set the status structure

par_base = WIDGET_BASE(root, FRAME=10, COLUMN=2 ) 
btn_base = WIDGET_BASE(root, FRAME=10, /ROW) 


;; left-part of GUI : detector base + band stuff
;;==============================================

par_base1 = widget_base(par_base, /COL)

; DETECTOR BASE Characteristics of detector, wavelength and where it focuses
;==============
det_base = WIDGET_BASE(par_base1, /FRAME, /COL,/BASE_ALIGN_CENTER) 
dummy    = WIDGET_LABEL(det_base,VALUE='Detector Characteristics',/FRAME)
dummy    = WIDGET_LABEL(det_base,VALUE='Detector conjugated to plane at')


IF (state.par.foc_dist NE !VALUES.F_INFINITY) THEN dummy=1 ELSE dummy= 0
state.id.foc_button=                                             $
  CW_BGROUP(det_base, ['Infinity','Other'],UVALUE='foc_button'  ,$
            SET_VALUE=dummy, /EXCLUSIVE, /ROW);,                   $
            ;LABEL_TOP= 'Detector conjugated to plane at')

det_base1= WIDGET_BASE(det_base, COLUMN=2)

state.id.npixel =                                                         $
  CW_FIELD(det_base1,TITLE="Number of pixels (along x & y-axes)",/COLUMN, $
           VALUE=state.par.npixel,UVALUE="np",/INTEGER,/ALL_EVENTS)

state.id.pxsize =                                                         $
  CW_FIELD(det_base1,TITLE="Detector pixel size [arcseconds]   ",/COLUMN, $
           VALUE=state.par.pxsize,UVALUE="psize",/FLOATING,/ALL_EV)

state.id.time_integ =                                                          $
  CW_FIELD(det_base1, TITLE="Integration time [base-time units] ", /COLUMN,    $
           VALUE=state.par.time_integ,UVALUE="time_integ",                     $
           /INTEGER,/ALL_EVENTS)

state.id.lambda =                                                              $
  CW_FIELD(det_base1,TITLE="Central wavelength [nm]            ", /COLUMN,     $
           VALUE=state.par.lambda*1e9,/FLOATING,UVALUE='lambda',/ALL_EVENTS)

state.id.foc_dist =                                                      $
  CW_FIELD(det_base1, TITLE="Focusing distance  [m]       ", /COLUMN,    $
           VALUE=state.par.foc_dist,UVALUE='foc_dist',/FLOATING,         $
           /ALL_EVENTS)

state.id.qeff  =                                                         $
  CW_FIELD(det_base1, TITLE="Quantum efficiency (0< qe <1)", /COLUMN,    $
           VALUE=state.par.qeff,UVALUE="qe",/FLOATING,/ALL_EVENTS)

state.id.time_delay =                                                    $
  CW_FIELD(det_base1,TITLE="Delay time [base-time units] ",/COLUMN,      $
           VALUE=state.par.time_delay,UVALUE="time_delay",               $
           /INTEGER,/ALL_EVENTS)

state.id.width =                                                         $
  CW_FIELD(det_base1,TITLE="Band-width [nm]              ",/ALL_EVENTS,  $
           /FLOATING,VALUE=state.par.width*1e9,/COLUMN,UVALUE='width')



;Determining which bands have been chosen => If a band is partially selected then it appears as having been chosen,
;----------------------------------------     unless lambda AND width coincide exactly with values in band_tab

det_base2= WIDGET_BASE(det_base, /COLUMN, /BASE_ALIGN_CENTER)


dummy          = WIDGET_LABEL(det_base2,VALUE='Wavelength band at which IMG operates',/FRAME)
state.id.reset = WIDGET_BUTTON(det_base2,UVALUE='reset',VALUE='Reset Bands')

dummy  = CLOSEST(state.par.lambda,lambda_tab)
value  = INTARR(N_ELEMENTS(band_tab))
n_band = N_ELEMENTS(band_tab)
f_band = FLTARR(n_band)

IF (((state.par.lambda - lambda_tab[dummy]) LT 1e-12)  AND        $
    ((state.par.width  - width_tab[dummy ]) LT 1e-12)) THEN BEGIN 

   flag_band     = 0B                                       ;Indicates a single band!!
   value[dummy]  = 1
   f_band[dummy] = 1.
   state.id.band =                                                             $
     CW_BGROUP(det_base2, band_tab, /ROW, SET_VALUE=value, UVALUE='menu_band', $
               BUTTON_UVALUE= INDGEN(n_band),/NONEXCL)

ENDIF ELSE BEGIN                                            ;The selected wavelength range spans over two or more bands

   flag_band = 1B

   lambda1 = state.par.lambda - state.par.width/2
   lambda2 = state.par.lambda + state.par.width/2

   FOR i=0,n_band-1 DO BEGIN
      band1 = lambda_tab[i]-width_tab[i]/2.
      band2 = lambda_tab[i]+width_tab[i]/2.
      f_band[i] = INTERVAL2(lambda1, lambda2, band1, band2, d1, d2)
      lambda1 = d1
      lambda2 = d2
   ENDFOR 
      

   r1 = WHERE(f_band GT 0., c1)
   
   IF (c1 GT 0) THEN BEGIN
      value[r1] = 1.
      state.id.band =                                                            $
        CW_BGROUP(det_base2, band_tab, /ROW, SET_VALUE=value, UVALUE='menu_band',$
                  BUTTON_UVALUE= INDGEN(n_band),/NONEXCL)
   ENDIF ELSE BEGIN 
      MESSAGE,'Bandwidth selected not within the standard bands. Check!!'
   ENDELSE 

ENDELSE 


;; right-part of GUI: NOISE base + RESOLUTION base
;;================================================

par_base2 =  widget_base(par_base, /COL, /FRAME)

;NOISE base
;==========

status = TAG_EXIST(par,'seed_pn')

;;;;noiseback = widget_base(det_base2, ROW=2, /FRAME)
noiseback = widget_base(par_base2, ROW=2, /FRAME)

IF status THEN BEGIN 

   noise = WIDGET_BASE(noiseback,COLUMN=3)
   noise1= WIDGET_BASE(noise,/COL)
   noise2= WIDGET_BASE(noise,/COL)
   noise3= WIDGET_BASE(noise,/COL)
   
   
   state.id.noise =                                                            $
     CW_BGROUP(noise1,['Photon Noise','Read-out Noise','Dark-current Noise'],  $
               UVALUE='noise',/NONEXCLUSIVE,/COL,SET_VALUE=state.par.noise)
   

   state.id.read_noise=                                                   $
     CW_FIELD(noise2, TITLE='Read-out   [e- rms]', /COL, /INTEGER,        $
              VALUE=state.par.read_noise,UVALUE="read_noise",/ALL_EVENTS)
   
   state.id.dark_noise=                                                   $
     CW_FIELD(noise2, TITLE='Dark-current [e-/s]', /COL, /INTEGER,        $
              VALUE=state.par.dark_noise,UVALUE="dark_noise",/ALL_EVENTS)
   

   dummy = WIDGET_LABEL(noise3,VALUE=' NOISE SEEDS',/FRAME)

   state.id.seed_pn =                                    $
     CW_FIELD(noise3, TITLE='',/ROW,/LONG,/ALL_EVENTS,   $
              VALUE=state.par.seed_pn,UVALUE='seed_pn')

   state.id.seed_ron =                                   $
     CW_FIELD(noise3, TITLE='',/ROW,/LONG,/ALL_EVENTS,   $
              VALUE=state.par.seed_ron,UVALUE='seed_ron')

   state.id.seed_dark =                                   $
     CW_FIELD(noise3, TITLE='',/ROW,/LONG,/ALL_EVENTS,    $
              VALUE=state.par.seed_dark,UVALUE='seed_dark')

ENDIF ELSE BEGIN 

   noise = WIDGET_BASE(det_base2, COLUMN=3,/FRAME)
   noise1= WIDGET_BASE(noise,/COL)
   noise2= WIDGET_BASE(noise,/COL)
   
   
   state.id.noise =                                                            $
     CW_BGROUP(noise1,['Photon Noise','Read-out Noise','Dark-current Noise'],  $
               UVALUE='noise',/NONEXCLUSIVE,/COL,SET_VALUE=state.par.noise)
   
   state.id.read_noise=                                                   $
     CW_FIELD(noise2, TITLE='Read-out   [e- rms]', /COL, /INTEGER,        $
              VALUE=state.par.read_noise,UVALUE="read_noise",/ALL_EVENTS)
   
   state.id.dark_noise=                                                   $
     CW_FIELD(noise2, TITLE='Dark-current [e-/s]', /COL, /INTEGER,        $
              VALUE=state.par.dark_noise,UVALUE="dark_noise",/ALL_EVENTS)
  
ENDELSE 


;background stuff
;================
status = TAG_EXIST(par,'backgradd')
IF status THEN BEGIN 
   state.id.backgradd = cw_bgroup(noiseback,                                                  $
                                  LABEL_LEFT="Add sky background to the PSF and the image ?", $
                                  ['no', 'yes'],                                              $
                                  ROW=2,                                                      $
                                  SET_VALUE=state.par.backgradd,                              $
                                  /EXCLUSIVE,                                                 $
                                  UVALUE="backgradd"                                          )
endif


;INCREASE RESOLUTION base
;===================

;;;;dummy   = WIDGET_BASE(det_base2,COLUMN=2, FRAME= 10)
dummy   = WIDGET_BASE(par_base2,COLUMN=2, FRAME= 10)

state.id.increase=                                               $
  WIDGET_SLIDER(dummy, /DRAG, XSIZE=350, MINIMUM=0, MAXIMUM=10,  $
                UVALUE= 'increase',VALUE=state.par.increase/2 ,  $
               /SUPPRESS_VALUE, TITLE='Increase resolution '+    $
               'in PSF calculus (see NOTE 2) by factor:')

state.id.inc_field=                                              $
  CW_FIELD(dummy,/COLUMN,VALUE=state.par.increase,/INT,/NOEDIT,  $
          TITLE=' ',XSIZE=4)

note  = WIDGET_LABEL(par_base2, VALUE='NOTES: 1/ In App.Builder BOTTOM box (=1st ouput) contains the PSF and ')
note  = WIDGET_LABEL(par_base2, VALUE='          UPPER box (= 2nd ouput) stores PSF @ Object (@= convolution)')

note  = WIDGET_LABEL(par_base2, VALUE='       2/ Increase in resolution is ONLY considered for a 2x2 detector')
note  = WIDGET_LABEL(par_base2, VALUE='          (e.g. quad-cell) or NxN CCD (N>2) with pixel<lambda/Diameter')




;Filling Control Buttons Section (standard buttons)
;===============================

dummy = WIDGET_BUTTON(btn_base, UVALUE="help"   ,VALUE="HELP")
cancel= WIDGET_BUTTON(btn_base, UVALUE="cancel" ,VALUE="CANCEL")
dummy = WIDGET_BUTTON(btn_base, UVALUE="restore",VALUE="RESTORE PARAMETERS")
save  = WIDGET_BUTTON(btn_base, UVALUE="save"   ,VALUE="SAVE PARAMETERS")

IF modal THEN WIDGET_CONTROL, cancel, /CANCEL_BUTTON
IF modal THEN WIDGET_CONTROL, save  , /DEFAULT_BUTTON


;Final stuff
;============
img_set,state

WIDGET_CONTROL, root, SET_UVALUE=state
WIDGET_CONTROL, root, /REALIZE

XMANAGER, 'img_gui', root, GROUP_LEADER=group

RETURN, error
END