; $Id: rft_gui.pro,v 1.0 last revision 2016/04/29 Andrea La Camera $
;+
; NAME:
;    rft_gui
;
; PURPOSE:
;    rft_gui generates the Graphical User Interface (GUI) for
;    setting the parameters of the RFT module.
;    A parameter file called rft_nnnnn.sav is created, where nnnnn
;    is the number n_module associated to the module instance.
;    the file is stored in the project directory proj_name located
;    in the working directory.
;    (see rft.pro's header --or file airy_help.html-- for details
;    about the module itself).
;
; CATEGORY:
;    module's Graphical User Interface routine
;
; CALLING SEQUENCE:
;    error = rft_gui(n_module, $
;                    proj_name )
;
; INPUTS:
;    n_module : number associated to the instance of the RFT module
;               [integer scalar -- n_module > 0].
;    proj_name: name of the current project [string].
;
; OUTPUTS:
;    error: error code [long scalar].
;
; COMMON BLOCKS:
;    wavelengths, band_tab, lambda_tab, width_tab, flag_band, f_band
;
; CALLED NON-IDL FUNCTIONS:
;    none.
;
; ROUTINE MODIFICATION HISTORY:
;    routine written: july 2000,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it].
;    modifications  : october 2000,
;                     Serge Correia (OAA) :
;                    -remove the generic filename obligation
;                     (.fits file can now have any desirable extension)
;                   : february 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -adapted to version 4.0 of the whole system CAOS
;                     (variable "pack_name" added, and variable "mod_type"
;                     changed into "mod_name").
;                    -(rft_info()).help stuff added (instead of !caos_env.help).
;                   : november 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -better selection of central wavelength and band-width through
;                     pre-defined bands selection and combination.
;                   : semptember 2005
;                     Barbara Anconelli (DISI) [anconelli@disi.unige.it]
;                    -added help for windows version
;                   : december 2005,
;                     Gabriele Desidera' (DISI) [desidera@disi.unige.it]:
;                    -possibility to insert integration times for loaded data cube
;                     in a dedicated gui.
;                   : may 2007, 
;                     Gabriele Desidera' (DISI) [desidera@disi.unige.it]:
;                    -simpler way to call AIRY_HELP.
;                   : december 2010,
;                     Marcel Carbillet (Fizeau) [marcel.carbillet@unice.fr],
;                     Andrea La Camera (DISI) [lacamera@disi.unige.it]:
;                    -package version control eliminated.
;                   : february 2011,
;                     Andrea La Camera (DISI) [lacamera@disi.unige.it]:
;                    -"Insert hour angle" button and table added;
;                    -"Insert integration time" button and table changed. 
;                    -New GUI design.
;                   : february 2012,
;                     Andrea La Camera (DISI) [lacamera@disi.unige.it]:
;                    -file "rft_time_gui.pro" and folder "rft_gui_lib" removed
;                     [unused and no more necessary]
;                    -New way to call AIRY_HELP. By using the "online_help" 
;                     routine, we resolved a known-issue of the Soft.Pack.
;                   : from CAOS_PSE v 7.0 (2016) 
;                    -this module has been moved from AIRY 6.1 to the new 
;                     package "Utilities". Version number has been
;                     reset to 1.0. 
;                    -the Angle input has been removed (not really used)
;                    -the parameters can be read from the FITS header
;                    -the header of the FITS can be visualized on screen
;                    -the GUI has been re-drawn
;-
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; status setting provedure ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
pro rft_gui_set, state
COMMON wavelengths, band_tab, lambda_tab, width_tab, flag_band, f_band

if state.par.int_time_ok then begin
  widget_control, state.id.int_time, /SENSITIVE
  widget_control, state.id.reset_int_time, /SENSITIVE
endif else begin
  widget_control, state.id.int_time, SENSITIVE = 0
  widget_control, state.id.reset_int_time, SENSITIVE = 0
endelse

;;Indicating in GUI which bands have been selected
;;------------------------------------------------

dummy  = CLOSEST(state.par.lambda,lambda_tab)
value  = INTARR(N_ELEMENTS(band_tab))
n_band = N_ELEMENTS(band_tab)
f_band = FLTARR(n_band)

IF ((state.par.lambda*state.par.width NE 0) AND (dummy GT -1)) THEN BEGIN
   IF (((state.par.lambda - lambda_tab[dummy]) LT 1e-12)  AND        $
       ((state.par.width  - width_tab[dummy ]) LT 1e-12)) THEN BEGIN
      flag_band     = 0B           ;Indicates a single band!!
      value[dummy]  = 1
      f_band[dummy] = 1.
   ENDIF ELSE BEGIN
      flag_band = 1B               ;Indicates wavelength range spans over more than 1 band
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

ENDIF

WIDGET_CONTROL,state.id.band  ,SET_VALUE= value

end

;;;;;;;;;;;;;;;;;;;
; GUI events loop ;
;;;;;;;;;;;;;;;;;;;
;
pro rft_gui_event, event
COMMON wavelengths, band_tab, lambda_tab, width_tab, flag_band, f_band

; rft_gui error management block
common error_block, error

; read the GUI state structure
widget_control, event.top, GET_UVALUE=state

; handle a kill request (considered as a cancel event).
if tag_names(event, /STRUCTURE_NAME) eq 'WIDGET_KILL_REQUEST' then begin
   error = !caos_error.cancel
   widget_control, event.top, /DESTROY
endif

; handle all the other events
widget_control, event.id, GET_UVALUE=uvalue
case uvalue of

   'filename'     : state.par.filename  = event.value
   
   'read_keywords': begin
      if state.par.filename EQ '' then return
      header = headfits(state.par.filename) ;Read header
      dummy = fxpar(header, 'PSF', count = a)
      if (a) then begin
         state.par.psf = dummy
         widget_control, state.id.psf, set_value=dummy
      endif
      dummy = fxpar(header, 'RESOLUT', count = a)
      if (a) then begin
         state.par.resolution = dummy
         widget_control, state.id.resolution, set_value=dummy
      endif
      dummy = fxpar(header, 'LAMBDA', count = a)
      if (a) then begin
         state.par.lambda = dummy
         dummy= CLOSEST(state.par.lambda,lambda_tab)
         widget_control, state.id.lambda, SET_VALUE=state.par.lambda
        rft_gui_set, state
      endif
      dummy = fxpar(header, 'WIDTH', count = a)
      if (a) then begin
         state.par.width = dummy
         widget_control, state.id.width, SET_VALUE=state.par.width
        rft_gui_set, state
      endif
      dummy = fxpar(header, 'EXPTIME', count = a)
      if (a) then begin
         state.par.int_time_ok = 1B
         widget_control, state.id.int_time_ok, set_value=state.par.int_time_ok
         int_time= make_array(360,2)
         int_time[*,1]=1.
         int_time[0,0]=dummy
         widget_control, state.id.int_time,      SET_VALUE=transpose(int_time)
         state.par.int_time = int_time
         rft_gui_set, state
      endif
      dummy = fxpar(header, 'EXPTIME*', count = a)
      if (a GT 0) then begin
         state.par.int_time_ok = 1B
         widget_control, state.id.int_time_ok, set_value=state.par.int_time_ok
         P=fxpar(header, 'NAXIS')
         int_time= make_array(360,2)
         int_time[*,1]=1.
         int_time[0:P-1,0]=dummy[0] ; unique value is assumed! TO BE MODIFIED!
         widget_control, state.id.int_time,      SET_VALUE=transpose(int_time)
         state.par.int_time = int_time
         rft_gui_set, state
      endif
      rft_gui_set, state
   end
   'show_header' : begin
      if state.par.filename EQ '' then return
      header = headfits(state.par.filename);Read header
      xdispstr, header, TITLE="FITS HEADER", group_leader=event.top
   end
   
   'resolution'   : state.par.resolution  = event.value
   
   'int_time_ok' : begin
      widget_control, state.id.int_time_ok, GET_VALUE=dummy
      state.par.int_time_ok=dummy
      rft_gui_set, state
   end
   
   
   'int_time'  : begin
      dummyx = event.x
      dummyy = event.y
      widget_control, state.id.int_time, get_Value=dummy
      
                                ; check whether multi-frame images are set up  or not.
      a=where(state.par.int_time[*,1] GT 1., num)
      if (event.x EQ 1) AND (dummy[dummyx,dummyy] GT 1) then begin
         a=dialog_message("Multi-frame images loading: NOT "+$
                          "YET IMPLEMENTED!", DIALOG_PARENT=event.top,      $
                          TITLE='RFT error',/ERROR )
         dummy[dummyx,dummyy]=1
      endif
      
      if dummyx eq 0 then begin
         state.par.int_time[dummyy,dummyx]=double(dummy[dummyx,dummyy])
      endif else begin
         state.par.int_time[dummyy,dummyx]=double(fix(dummy[dummyx,dummyy]))
         widget_control, state.id.int_time,  SET_Value=transpose(state.par.int_time)             
      endelse
   end
   
   'reset_int_time' : begin
      state.par.int_time[*,0]=0
      state.par.int_time[*,1]=1
      widget_control, state.id.int_time, SET_Value=transpose(state.par.int_time)
   end
   
   'lambda'       : begin
      state.par.lambda  = event.value
      dummy= CLOSEST(state.par.lambda,lambda_tab)
      rft_gui_set, state
   end
   
   'width'        : begin
      state.par.width  = event.value
      rft_gui_set, state
   end

   'menu_band': BEGIN
      WIDGET_CONTROL, event.id , GET_VALUE=dummy
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
      WIDGET_CONTROL, state.id.lambda, SET_VALUE=state.par.lambda
      WIDGET_CONTROL, state.id.width,  SET_VALUE=state.par.width
      rft_gui_set, state
   END
   
   'reset':BEGIN
      state.par.lambda = 0.
      state.par.width  = 0.
      WIDGET_CONTROL,state.id.lambda, SET_VALUE=state.par.lambda
      WIDGET_CONTROL,state.id.width , SET_VALUE=state.par.width
      rft_gui_set, state
   END
   
   'psf'          : begin
      state.par.psf  = event.value
   end

   'save': begin
                                ; check if the filename of the data
                                ; cube to restore is empty
      if (state.par.filename eq '') then begin
         dummy = dialog_message("Invalid image filename!", DIALOG_PARENT=event.top, $
                                TITLE='RFT error', /ERROR)
         return
      endif
                                ; check before saving the parameter
                                ; file if filename already exists
      check_file = findfile(state.sav_file)
      if check_file[0] ne "" then begin
         answ = dialog_message(['file '+state.sav_file+' already exists.', $
                                'do you want to overwrite it ?'],          $
                               DIALOG_PARENT=event.top,                    $
                               TITLE='RFT warning',                        $
                               /QUEST)
                                ; return without saving if the
                                ; user doesn't want to overwrite  
                                ; the existing parameter file
         if strlowcase(answ) eq "no" then return
      endif else begin
         answ = dialog_message(['file '+state.sav_file+' will be saved.'], $
                               DIALOG_PARENT=event.top,                    $
                               TITLE='RFT information',                    $
                               /INFO                                       )
                                ; inform were the parameters will be saved
      endelse
      
                                ; save the parameter data file
      par = state.par
      save, par, FILENAME = state.sav_file
      
                                ; kill the GUI returning a null error
      error = !caos_error.ok
      widget_control, event.top, /DESTROY
      return
      
   end
   
                                ; handle event from standard help button
   'help': begin
      online_help, book=(rft_info()).help, /FULL_PATH
   end
   
                                ; handle event from standard restore button
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
      widget_control, state.id.filename,      SET_VALUE=par.filename
      widget_control, state.id.int_time_ok, set_value=par.int_time_ok
      widget_control, state.id.int_time,      SET_VALUE=transpose(par.int_time)
      widget_control, state.id.psf,           SET_VALUE=par.psf
      widget_control, state.id.resolution,    SET_VALUE=par.resolution
      widget_control, state.id.lambda,        SET_VALUE=par.lambda
      widget_control, state.id.width,         SET_VALUE=par.width
      dummy= CLOSEST(par.lambda,lambda_tab)
      WIDGET_CONTROL, state.id.band, SET_VALUE=dummy
                                ; update the state structure
      state.par = par
      rft_gui_set, state
   end
   
   'cancel': begin
      error = !caos_error.cancel
      widget_control, event.top, /DESTROY
      return
   end
   
endcase

; write the GUI state structure
widget_control, event.top, SET_UVALUE=state

return

end

;;;;;;;;;;;;;;;;;;;;;;;
; GUI generation code ;
;;;;;;;;;;;;;;;;;;;;;;;
;
function rft_gui, n_module,  $
                  proj_name, $
                  GROUP_LEADER=group

COMMON wavelengths, band_tab, lambda_tab, width_tab, flag_band, f_band
; error status from the event handler procedure
common error_block, error

; retrieve the module information
info = rft_info()

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
endif else begin
   restore, sav_file
   if (par.module.mod_name ne info.mod_name) then $
      message, 'the parameter file '+sav_file     $
              +' is from another module: please generate a new one'
   if (par.module.ver ne info.ver) then       $
      message, 'the parameter file '+sav_file $
              +' is not compatible: please generate it again'
endelse

; build the widget id structure where all the needed (in rft_gui_event)
; widget's id will be stored
id = $
   { $                     ; widget id structure
      par_base     : 0L, $ ; parameter base id
      filename     : 0L, $ ; file address field id
      read_keywords : 0L, $ ; read_keywords from header
      show_header  : 0L, $ ; show header of the FITS file
      resolution   : 0L, $
      int_time_ok  : 0L, $
      int_time     : 0L, $
      reset_int_time : 0L, $
      lambda       : 0L, $
      width        : 0L, $
      band         : 0L, $
      reset        : 0L, $
      psf          : 0L  $
   }

; build the state structure were par, id, sav_file and def_file will be stored
; (and passed to rft_gui_event).
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
;   dummy = widget_label(state.id.par_base, VALUE='parameters', /FRAME)
par_base_id = widget_base(state.id.par_base, /COL)


; filename
par_base_file = widget_base (par_base_id, /col)
state.id.filename = cw_filename(par_base_file,TITLE="image filename",  $
                                VALUE=state.par.filename,UVALUE="filename",$
                                /ALL_EVENTS, xsize=50)
par_base_file2 = widget_base (par_base_file, /ROW)
state.id.read_keywords = widget_button(par_base_file2, $
              value='Retrieve parameters from header', $
              UVALUE = 'read_keywords' )
state.id.show_header = widget_button(par_base_file2, $
              value='Show header', $
              UVALUE = 'show_header' )

dummy     = WIDGET_LABEL(par_base_id,VALUE=' Image type parameters: ', /align_center)

param   = widget_base(par_base_id, /row)

;Integration Times
param_left = widget_base(param, /col, /frame)
state.id.int_time_ok = cw_bgroup(param_left, 'Insert integration time for loaded image',$
                                 SET_VALUE=state.par.int_time_ok, COLUMN=2, $
                                 UVALUE='int_time_ok', /NONEXCLUSIVE)
int_time_table=widget_base(param_left,xsize=300,ysize=160)
rlabel=make_array(360,/string,value='Angle #')
num=indgen(360)
rlabel=rlabel+strcompress(string(num),/remove_all)
button_int_time=widget_base(int_time_table,xoffset=8,yoffset=18,xsize=64,ysize=26)
state.id.reset_int_time=widget_button(button_int_time,$
                         VALUE="Reset Val", UVALUE="reset_int_time")
state.id.int_time = widget_table(int_time_table,$
                ALIGNMENT=2,$
                xoffset=5,yoffset=15,$
                value=transpose(state.par.int_time),$
                uvalue="int_time",$
                editable=1,$
                COLUMN_LABELS=['Integration x frame [s]','Frames #'],$
                ROW_LABELS=rlabel,$
                COLUMN_WIDTHS=[145,60],$
                y_scroll_size=5   )

param_right = widget_base(param, /col, /frame)
; it's a psf?
state.id.psf   = cw_bgroup(param_right, LABEL_LEFT='Is it a PSF ?', $
                           ['no', 'yes'], COLUMN=2, SET_VALUE = state.par.psf, $
                           UVALUE = 'psf', /EXCLUSIVE  )
; resolution
state.id.resolution  = cw_field(param_right, TITLE='Pixel size [arcsec]    ', $
                         /FLOATING,  VALUE=state.par.resolution,      $
                          UVALUE='resolution', /ALL_EVENTS )


;;;;;;;;;  Wavelength 
bandbase  = widget_base(param_right, /COL)
dummy     = WIDGET_LABEL(bandbase,VALUE='Wavelength band',/FRAME)

bandstuff = widget_base(bandbase, /COL)
; lambda
state.id.lambda = cw_field(bandstuff,                      $
                           TITLE='Center wavelength [m] ', $
                           /FLOATING,                      $
                           VALUE=state.par.lambda,         $
                           UVALUE='lambda',                $
                           /ALL_EVENTS                     )

; width
state.id.width = cw_field(bandstuff,                      $
                          TITLE='Band-width [m]        ', $
                          /FLOATING,                      $
                          VALUE=state.par.width,          $
                          UVALUE='width',                 $
                          /ALL_EVENTS                     )

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Determining which bands have been chosen
;=> If a band is partially selected then it appears as having been chosen,
;   unless lambda AND width coincide exactly with values in band_tab

dummy     = N_PHOT(1.,BAND=dummy1,LAMBDA=dummy2,WIDTH=dummy3)
band_tab  = dummy1[3:9]
lambda_tab= dummy2[3:9]
width_tab = dummy3[3:9]

det_base2= WIDGET_BASE(bandbase, /ROW, /BASE_ALIGN_CENTER)

state.id.reset = WIDGET_BUTTON(det_base2,UVALUE='reset',VALUE='Reset Bands')

dummy  = CLOSEST(state.par.lambda,lambda_tab)
value  = INTARR(N_ELEMENTS(band_tab))
n_band = N_ELEMENTS(band_tab)
f_band = FLTARR(n_band)

IF (((state.par.lambda - lambda_tab[dummy]) LT 1e-12)  AND        $
    ((state.par.width  - width_tab[dummy ]) LT 1e-12)) THEN BEGIN

   flag_band     = 0B                        ;Indicates a single band!!
   value[dummy]  = 1
   f_band[dummy] = 1.
   state.id.band =                                                             $
     CW_BGROUP(det_base2, band_tab, /ROW, SET_VALUE=value, UVALUE='menu_band', $
               BUTTON_UVALUE= INDGEN(n_band),/NONEXCL)

ENDIF ELSE BEGIN                             ;The selected wavelength range
                                             ;spans over two or more bands

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
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


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

; save the state structure of the GUI in the top base uvalue
widget_control, root_base_id, SET_UVALUE=state

; draw the GUI
widget_control, root_base_id, /REALIZE

rft_gui_set, state

; launch xmanager
xmanager, 'rft_gui', root_base_id, GROUP_LEADER=group

; back to the main calling program
return, error
end
