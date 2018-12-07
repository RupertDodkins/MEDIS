; $Id: pyr_gui.pro,v 7.0 2016/05/19 marcel.carbillet $
;+
; NAME:
;    pyr_gui
;
; PURPOSE:
;    pyr_gui generates the Graphical User Interface (GUI) for
;    setting the parameters of the [pyramid WFS] (pyr) module.
;    a parameter file called pyr_nnnnn.sav is created, where nnnnn
;    is the number n_module associated to the module instance.
;    the file is stored in the project directory proj_name located
;    in the working directory.
;    (see pyr.pro's header --or file caos_help.html-- for details
;    about the module itself).
;
; CATEGORY:
;    module's Graghical User Interface routine
;
; CALLING SEQUENCE:
;    error = pyr_gui(n_module, $
;                    proj_name )
; 
; INPUTS:
;    n_module : number associated to the intance of the XXX module
;               [integer scalar -- n_module > 0].
;    proj_name: name of the current project [string].
;
; OUTPUTS:
;    error: error code [long scalar].
;
; COMMON BLOCKS:
;    none.
;
; CALLED NON-IDL FUNCTIONS:
;    none.
;
; ROUTINE MODIFICATION HISTORY:
;    routine written: june 2001,
;                     Christophe Verinaud (OAA) [verinaud@arcetri.astro.it].
;    modifications  : september 2001,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -option for FFTWND added.
;                   : october 2002,
;                     Christophe Verinaud (OAA) [verinaud@arcetri.astro.it]:
;                    -new parameters for phase mask alternative.
;                   : january 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -adapted to version 4.0 of the whole Software System CAOS
;                     (variable "pack_name" added, and variable "info.mod_type"
;                     changed into "info.mod_name").
;                    -(pyr_info()).help stuff added (instead of
;                    !caos_env.help).
;                    -init file management eliminated (was useless).
;                   : february 2003, 
;                     Christophe Verinaud (ESO) [cverinau@eso.org]:
;                    - param. separation between pupil unsensitive if
;                      transmission mask selected
;                   : january 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -GUI arranged (best fitting with laptop screens).
;                   : december 2004,
;                     Marcel Carbillet (LUAN) [marcel.carbillet@unice.fr]:
;                    -no more crash provoked when controlling the Soft.Pack.
;                     version for existing parameter files - just a warning.
;                    -GUI remade in order to fit small screens.
;                   : february 2007,
;                     Marcel Carbillet (LUAN) [marcel.carbillet@unice.fr]:
;                    -control of the the Soft.Pack. debugged (the warning was
;                     here *always* (partly) printed )...
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
pro pyr_gui_set, state

widget_control, /HOURGLASS


; initialisation base management

if (state.par.algo eq 0B) then widget_control, state.id.sep, SENSITIVE=0 $
else widget_control, state.id.sep, /SENSITIVE

end
;;;;;;;;;;;;;;;;;;;
; GUI events loop ;
;;;;;;;;;;;;;;;;;;;
;
pro pyr_gui_event, event

common error_block, error

; read the GUI state structure
widget_control, event.top, GET_UVALUE=state

if tag_names(event, /STRUCTURE_NAME) eq 'WIDGET_KILL_REQUEST' then begin
   error = !caos_error.cancel
   widget_control, event.top, /DESTROY
endif

widget_control, event.id, GET_UVALUE=uvalue
case uvalue of
   'sep'       : state.par.sep        = event.value
   'time_integ': state.par.time_integ = event.value
   'time_delay': state.par.time_delay = event.value
   'fvalid'    : state.par.fvalid     = event.value
   'lambda'    : state.par.lambda     = event.value*1e-9
   'width'     : state.par.width      = event.value*1e-9
   'noise':BEGIN
        WIDGET_CONTROL, event.top, GET_UVALUE=state
        WIDGET_CONTROL, event.id , GET_VALUE=dummy
        state.par.noise= dummy
        WIDGET_CONTROL, event.top, SET_UVALUE=state
    END
   'background':BEGIN
        WIDGET_CONTROL, event.top, GET_UVALUE=state
        WIDGET_CONTROL, event.id , GET_VALUE=dummy
        state.par.background= dummy
        WIDGET_CONTROL, event.top, SET_UVALUE=state
    END
    'pyr_fov':BEGIN
        WIDGET_CONTROL, event.top, GET_UVALUE=state
        WIDGET_CONTROL, event.id,  GET_VALUE=dummy
        state.par.pyr_fov = dummy
        WIDGET_CONTROL, event.top, SET_UVALUE=state
    END
    'rnoise':BEGIN
        WIDGET_CONTROL, event.top, GET_UVALUE=state
        WIDGET_CONTROL, event.id,  GET_VALUE=dummy
        state.par.rnoise = dummy
        WIDGET_CONTROL, event.top, SET_UVALUE=state
    END
    'dark':BEGIN
        WIDGET_CONTROL, event.top, GET_UVALUE=state
        WIDGET_CONTROL, event.id,  GET_VALUE=dummy
        state.par.dark = dummy
        WIDGET_CONTROL, event.top, SET_UVALUE=state
    END
   'threshold':BEGIN
        WIDGET_CONTROL, event.top, GET_UVALUE=state
        WIDGET_CONTROL, event.id,  GET_VALUE=dummy
        state.par.threshold  = dummy
        WIDGET_CONTROL, event.top, SET_UVALUE=state
    END
   'qe'          : state.par.qe                                     = event.value
   'nxsub'       : state.par.nxsub                                  = event.value
   'modul'       : for k=0, state.par.n_pyr-1 do state.par.modul[k] = event.value
   'step'        : for k=0, state.par.n_pyr-1 do state.par.step[k]  = event.value
   'fftwnd'      : state.par.fftwnd                                 = event.value
   'mod_type'    : state.par.mod_type                               = event.value
   'algo'        : state.par.algo                                   = event.value
   'psf_sampling': state.par.psf_sampling                           = event.value

   'save': begin

      ;; check before saving the parameter file if filename already exists
      ;; or inform where the parameters will be saved.
      check_file = findfile(state.sav_file)
      if check_file[0] ne "" then begin
         answ = dialog_message(['file '+state.sav_file+' already exists.', $
                                'would you like to overwrite it?'],        $
                               DIALOG_PARENT = event.top, $
                               TITLE = 'PYR warning', /QUEST)
         if strlowcase(answ) eq "no" then return
      ENDIF ELSE BEGIN 
         answ = dialog_message(['file '+state.sav_file+' will be saved.'], $
                               DIALOG_PARENT=event.top,                    $
                               TITLE='PYR information',/INFO)
      ENDELSE 

      ; save the parameter data file
      par = state.par
      save, par, FILENAME=state.sav_file

      ; kill the GUI returning a null error
      error = !caos_error.ok
      WIDGET_CONTROL, event.top, /DESTROY
      return

   end

   'help' : online_help, book=(pyr_info()).help, /FULL_PATH

   'restore': begin

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

;      WIDGET_CONTROL, state.id.n_pyr,        SET_VALUE=par.n_pyr
      WIDGET_CONTROL, state.id.rnoise,       SET_VALUE=par.rnoise
      WIDGET_CONTROL, state.id.dark,         SET_VALUE=par.dark
      WIDGET_CONTROL, state.id.threshold,    SET_VALUE=par.threshold
      WIDGET_CONTROL, state.id.time_integ,   SET_VALUE=par.time_integ
      WIDGET_CONTROL, state.id.time_delay,   SET_VALUE=par.time_delay
      WIDGET_CONTROL, state.id.fvalid,       SET_VALUE=par.fvalid
      WIDGET_CONTROL, state.id.qe,           SET_VALUE=par.qe
      WIDGET_CONTROL, state.id.lambda,       SET_VALUE=par.lambda*1e9
      WIDGET_CONTROL, state.id.width,        SET_VALUE=par.width*1e9
      WIDGET_CONTROL, state.id.nxsub,        SET_VALUE=par.nxsub
      WIDGET_CONTROL, state.id.modul,        SET_VALUE=par.modul
      WIDGET_CONTROL, state.id.step,         SET_VALUE=par.step
      WIDGET_CONTROL, state.id.sep,          SET_VALUE=par.sep
      WIDGET_CONTROL, state.id.noise,        SET_VALUE=par.noise
;      WIDGET_CONTROL, state.id.fftwnd,       SET_VALUE=par.fftwnd
;      WIDGET_CONTROL, state.id.mod_type,     SET_VALUE=par.mod_type
;      WIDGET_CONTROL, state.id.algo,         SET_VALUE=par.algo
      WIDGET_CONTROL, state.id.psf_sampling, SET_VALUE=par.psf_sampling
      ; update the state structure
      state.par = par

    end

    'cancel'  : begin
        error = !caos_error.cancel
        WIDGET_CONTROL, event.top, /DESTROY
        return
    end

endcase

pyr_gui_set, state

; write the GUI state structure
widget_control, event.top, SET_UVALUE=state

return
end

;;;;;;;;;;;;;;;;;;;;;;;
; GUI generation code ;
;;;;;;;;;;;;;;;;;;;;;;;
;
function pyr_gui, n_module,  $
                  proj_name, $
                  GROUP_LEADER=group


; CAOS global common block
common caos_block, tot_iter, this_iter

; error status from the event handler procedure
common error_block, error

; retrieve the module information
info = pyr_info()

; check if a saved parameter file already exists for this module.
; if it exists it is restored, otherwise the default parameter file is restored.
sav_file = mk_par_name(info.mod_name, n_module, PROJ_NAME=proj_name)
def_file = mk_par_name(info.mod_name, PACK_NAME=info.pack_name, /DEFAULT)
par=0
check_file = findfile(sav_file)
if check_file[0] eq '' then begin
   restore, def_file
   par.module.n_module = n_module
   if (par.module.mod_name ne info.mod_name) then      $
      message, 'the default parameter file ('+def_file $
              +') is from another module: please take the right one'
   if (par.module.ver ne info.ver) then                $
      message, 'the default parameter file ('+def_file $
              +') is not compatible: please generate it again'   
endif else begin
   restore, sav_file
   if (par.module.mod_name ne info.mod_name) then $
      message, 'the parameter file '+sav_file     $
              +' is from another module: please generate a new one'
   if (par.module.ver ne info.ver) then begin
      print, '************************************************************'
      print, 'WARNING: the parameter file '+sav_file
      print, 'is probably from an older version than '+info.pack_name+' !!'
      print, 'You should possibly need to generate it again...'
      print, '************************************************************'
   endif
endelse

; build the widget id structure where all the needed (in pyr_gui_event)
; widget's id will be stored
id = $
{ $                     
   par_base        : 0L, $ 
   n_pyr           : 0L, $
   sens_base       : 0L, $
   modul_base	   : 0L, $
   ccd_base	   : 0L, $
   spec_base 	   : 0L, $
   fvalid    	   : 0L, $
   sep             : 0L, $
   psf_sampling    : 0L, $
   lambda    	   : 0L, $
   width     	   : 0L, $
   qe        	   : 0L, $
   noise     	   : 0L, $
   background	   : 0L, $
   pyr_fov	   : 0L, $
   rnoise    	   : 0L, $
   dark      	   : 0L, $
   threshold 	   : 0L, $
   nxsub     	   : 0L, $ 
   modul	   : 0L, $
   step		   : 0L, $
   mod_type        : 0L, $
   algo            : 0L, $
   fftwnd	   : 0L, $   
   time_delay      : 0L, $ ; time delay field id
   time_base	   : 0L, $
   time_integ      : 0L  $
   }

; build the state structure were par, id, sav_file and def_file will be stored
; (and passed to pyr_gui_event).
state = $
   {    $                ; widget state structure
   sav_file: sav_file, $ ; actual name of the file where save params
   def_file: def_file, $ ; default name of the file where save params
   id      : id,       $ ; widget id structure
   par     : par       $ ; parameter structure
   }


; root base definition
modal = n_elements(group) ne 0
dummy = strupcase(info.mod_name)+' parameters setting GUI'
root_base_id = widget_base(TITLE=dummy, MODAL=modal, /COL, GROUP_LEADER=group)

; set the status structure
widget_control, root_base_id, SET_UVALUE=state

   ; parameters base
   state.id.par_base = widget_base(root_base_id, FRAME=10, ROW=2)
  ; dummy = widget_label(state.id.par_base, VALUE='parameters', /FRAME)
;;;;par_base_id = widget_base(state.id.par_base, /COL)
   par_base_id = widget_base(state.id.par_base, /ROW)

   ; split widgets in two colums
   par_base_id1 = widget_base(par_base_id, /COL)
   par_base_id2 = widget_base(par_base_id, /COL)
 
 ; sensor geometry parameters base
;;;;state.id.sens_base = WIDGET_BASE(par_base_id, ROW=2, /FRAME)
   state.id.sens_base = WIDGET_BASE(par_base_id1, ROW=2, /FRAME)
   dummy = WIDGET_LABEL(state.id.sens_base, VALUE='sensor caracteristics', /FRAME)
   sens_base_id = WIDGET_BASE(state.id.sens_base, /COL)

   sens_base_id2= WIDGET_BASE(sens_base_id, /ROW)
      state.id.nxsub = cw_field(sens_base_id2,              $
                                TITLE='linear nb of sub-apertures', $
                                VALUE=state.par.nxsub,      $
                                UVALUE='nxsub',             $
                                /COLUMN,                    $
                                /INTEGER,                   $
                                /ALL_EVENTS                 )

      state.id.fvalid = cw_field(sens_base_id2,          $
                                 TITLE=                  $
              "mini. illumination ratio for valid sub-ap.",    $
                                 VALUE=state.par.fvalid, $
                                 UVALUE="fvalid",        $
                                 /COLUMN,                $
                                 /FLOATING,              $
                                 /ALL_EVENTS             )

      state.id.sep = cw_field(sens_base_id,                                                    $
                              TITLE='Separation between centers of quads [fraction of pupil]', $
                              VALUE=state.par.sep,                                             $
                              UVALUE='sep',                                                    $
                              /COLUMN,                                                         $
                              /FLOATING,                                                       $
                              /ALL_EVENTS                                                      )

;;;;state.id.algo = widget_base(par_base_id, ROW=2, /FRAME)
  state.id.algo = widget_base(par_base_id1, ROW=2, /FRAME)
  dummy = WIDGET_LABEL(state.id.algo, VALUE='Pyramid algorithm', /FRAME)
  algo_id = WIDGET_BASE(state.id.algo, /COL)

  dummy = cw_bgroup(algo_id,                        $
                       LABEL_LEFT=' ',              $
                       ['transmition mask','phase mask'], $
                       COLUMN=2,                    $
                       SET_VALUE=state.par.algo,    $
                       /EXCLUSIVE,                  $
  			UVALUE="algo"  )

psf_base_id = WIDGET_BASE(algo_id, /ROW)

state.id.psf_sampling = cw_field(psf_base_id,                    $
                                 TITLE=                           $
            "Sampling points per lambda/D", $
                                 VALUE=state.par.psf_sampling,          $
                                 UVALUE="psf_sampling",                 $
                                 /COLUMN,                         $
                                 /INTEGER,                       $
                                 /ALL_EVENTS                      )

state.id.pyr_fov=                                                   $
  CW_FIELD(psf_base_id, TITLE='pyramid FoV ["]', /COLUMN, /FLOATING,        $
           VALUE=state.par.pyr_fov,UVALUE="pyr_fov",/ALL_EVENTS)

;;;;state.id.modul_base = WIDGET_BASE(par_base_id, ROW=2, /FRAME)
state.id.modul_base = WIDGET_BASE(par_base_id1, ROW=2, /FRAME)
   dummy = WIDGET_LABEL(state.id.modul_base, VALUE='modulation', /FRAME)
   modul_base_id = WIDGET_BASE(state.id.modul_base, /ROW)
 
 state.id.modul = cw_field(modul_base_id,                     $
                                TITLE='amplitude (+/-lambda/D)',  $
                                VALUE=state.par.modul,            $
                                UVALUE='modul',                   $
                                /COLUMN,                          $
                                /FLOATING,                         $
                                /ALL_EVENTS                       )

      state.id.step = cw_field(modul_base_id,                    $
                                 TITLE="number of steps ", $
                                 VALUE=state.par.step,          $
                                 UVALUE="step",                 $
                                 /COLUMN,                         $
                                 /FLOATING,                       $
                                 /ALL_EVENTS                      )


state.id.mod_type = widget_base(modul_base_id, ROW=2, /FRAME)
 dummy = WIDGET_LABEL(state.id.mod_type, VALUE='modulation shape', /FRAME)
 mod_type_id = WIDGET_BASE(state.id.mod_type, /ROW)

  dummy = cw_bgroup(mod_type_id,                                                         $
                       LABEL_LEFT=' ',$
                       ['square','circular'],                                                          $
                       COLUMN=2,                                                               $
                       SET_VALUE=state.par.mod_type,                                             $
                       /EXCLUSIVE,                                                             $
		       UVALUE="mod_type"   )

;;;;state.id.fftwnd = widget_base(par_base_id, ROW=2, /FRAME)
state.id.fftwnd = widget_base(par_base_id2, ROW=2, /FRAME)
 dummy = WIDGET_LABEL(state.id.fftwnd, VALUE='FFT computation', /FRAME)
 fftwnd_base_id = WIDGET_BASE(state.id.fftwnd, /ROW)

     dummy = cw_bgroup(fftwnd_base_id,                                                         $
                       LABEL_LEFT='perform FFTs with routine FFTWND (needs special package) ?',$
                       ['no', 'yes'],                                                          $
                       COLUMN=2,                                                               $
                       SET_VALUE=state.par.fftwnd,                                             $
                       /EXCLUSIVE,                                                             $
                       UVALUE="fftwnd"                 )

; time behaviour
;;;;state.id.time_base = WIDGET_BASE(par_base_id, ROW=2, /FRAME)
   state.id.time_base = WIDGET_BASE(par_base_id2, ROW=2, /FRAME)
   dummy = WIDGET_LABEL(state.id.time_base, VALUE='time integration/delay', $
                        /FRAME                                              )
   time_base_id = WIDGET_BASE(state.id.time_base, /ROW)

      state.id.time_integ = cw_field(time_base_id,                   $
                                     TITLE=                          $
                                "integration time [base-time unit]", $
                                     VALUE=state.par.time_integ,     $
                                     UVALUE="time_integ",            $
                                     /COLUMN,                        $
                                     /INTEGER,                       $
                                     /ALL_EVENTS                     )

      state.id.time_delay = cw_field(time_base_id,                         $
                                     TITLE="delay time [base-time unit]", $
                                     VALUE=state.par.time_delay,          $
                                     UVALUE="time_delay",                 $
                                     /COLUMN,                             $
                                     /INTEGER,                            $
                                     /ALL_EVENTS                          )

   ; noise parameters
 
;NOISE base
;==========

;;;;noise = WIDGET_BASE(par_base_id, COLUMN=2,/FRAME)
noise = WIDGET_BASE(par_base_id2, COLUMN=2,/FRAME)
noise1= WIDGET_BASE(noise,/COL)
noise2= WIDGET_BASE(noise,/COL)

state.id.noise =                                                            $
  CW_BGROUP(noise1,['Photon Noise'],  $
            UVALUE='noise',/NONEXCLUSIVE,/COL,SET_VALUE=state.par.noise)

state.id.background =                                                            $
  CW_BGROUP(noise1,['Background Noise'],  $
            UVALUE='background',/NONEXCLUSIVE,/COL,SET_VALUE=state.par.background)


state.id.rnoise=                                                   $
  CW_FIELD(noise2, TITLE='Read-out   [e- rms]', /ROW, /FLOATING,        $
           VALUE=state.par.rnoise,UVALUE="rnoise",/ALL_EVENTS)

state.id.dark=                                                   $
  CW_FIELD(noise2, TITLE='Dark-current [e-/s]', /ROW, /FLOATING,        $
           VALUE=state.par.dark,UVALUE="dark",/ALL_EVENTS)
               

state.id.threshold=                                                   $
  CW_FIELD(noise2, TITLE='threshold [e-/s]', /ROW, /INTEGER,        $
           VALUE=state.par.threshold,UVALUE="threshold",/ALL_EVENTS)
               
 
   ; CCD spectral parameters base
;;;;state.id.spec_base = WIDGET_BASE(par_base_id, ROW=2, /FRAME)
   state.id.spec_base = WIDGET_BASE(par_base_id2, ROW=2, /FRAME)
   dummy = WIDGET_LABEL(state.id.spec_base,                        $
                        VALUE='sensor spectral sensitivity', /FRAME)
   spec_base_id = WIDGET_BASE(state.id.spec_base, /ROW)

      state.id.qe = cw_fslider(spec_base_id,           $
                             TITLE='total efficiency', $
                             VALUE=state.par.qe,       $
                             /EDIT,                    $
                             UVALUE="qe",              $
                             MAXI=1,                   $
                             SCROLL=.05,               $
                             /DRAG                     )

      state.id.lambda = cw_field(spec_base_id,               $
                                 TITLE='wavelength [nm]',    $
                                 /COLUMN,                    $
                                 VALUE=state.par.lambda*1e9, $
                                 UVALUE="lambda",            $
                                 /FLOATING,                  $
                                 /ALL_EVENTS                 )

      state.id.width = cw_field(spec_base_id,                $
                                TITLE='band-width [nm]',     $
                                /COLUMN,                     $
                                VALUE=state.par.width*1e9,   $
                                UVALUE="width",              $
                                /FLOATING,                   $
                                /ALL_EVENTS                  )
   ; Additional notes about the two outputs
;;;;note = WIDGET_LABEL(par_base_id, VALUE='NOTES: In App.Builder BOTTOM box (=1st ouput) contains the four pupil sub-images  ')
   note = WIDGET_LABEL(par_base_id1, VALUE='NOTES: In App.Builder BOTTOM box (=1st ouput) contains the four pupil sub-images  ')
;;;;note = WIDGET_LABEL(par_base_id, VALUE='       while UPPER box (=2nd ouput) stores the image on the vertex of the pyramid.')
   note = WIDGET_LABEL(par_base_id1, VALUE='       while UPPER box (=2nd ouput) stores the image on the vertex of the pyramid.')
 
 ; STANDART BUTTONS
   ; button base for control buttons (standard buttons)
   btn_base_id = widget_base(root_base_id, FRAME=10, /ROW)
      dummy = widget_button(btn_base_id, VALUE="HELP", UVALUE="help")
      cancel_id = widget_button(btn_base_id, VALUE="CANCEL", UVALUE="cancel")
      if modal then widget_control, cancel_id, /CANCEL_BUTTON
      dummy = widget_button(btn_base_id, VALUE="RESTORE PARAMETERS", $
                            UVALUE="restore"                         )
      save_id = widget_button(btn_base_id, VALUE="SAVE PARAMETERS",  $
                              UVALUE="save"                          )
      if modal then widget_control, save_id, /DEFAULT_BUTTON

pyr_gui_set, state

; save the state structure of the GUI in the top base uvalue
widget_control, root_base_id, SET_UVALUE=state

; draw the GUI
widget_control, root_base_id, /REALIZE

; launch xmanager
xmanager, 'pyr_gui', root_base_id, GROUP_LEADER=group

; back to the main calling program
return, error
end
