;**
;********************************************************************************
;** HOW TO USE THIS TEMPLATE:                                                   *
;**                                                                             *
;** 0-PLEASE READ THE WHOLE TEMPLATE FIRST (AND AT LEAST ONCE) !!               *
;** 1-CHANGE EVERYWHERE THE STRINGS "XXX" INTO THE CHOSEN 3-CHAR MODULE NAME    *
;** 2-CHANGE EVERYWHERE THE STRINGS "XYZ" INTO THE NAME OF THE SOFTWARE PACKAGE *
;** 3-ADAPT THE TEMPLATE ONTO THE NEW MODULE CASE FOLLOWING THE EXAMPLES,       *
;**   RECOMMENDATIONS, AND ADVICES FOUND THROUGH THE TEMPLATE                   *
;**   (A SPECIAL ONE FOR THE GRAPHICAL USER INTERFACE IS TO FIRST ADAPT THE     *
;**    XXX_GUI FUNCTION THAT CREATES THE GUI, THEN ADAPT THE XXX_GUI_EVENT      *
;**    PROCEDURE THAT MANAGES THE EVENTS COMMING FROM EACH ACTIVE WIDGET OF     *
;**    THE GUI, AND EVENTUALLY ADAPT THE XXX_GUI_SET PROCEDURE THAT DEALS WITH  *
;**    THE SENSITIVE SETTING OF THE WIDGETS AND OTHER PARAMETER SETTINGS THAT   *
;**    HAVE TO BE MANAGED WHENEVER AN EVENT OCCURS -- I.E. WITHIN THE EVENT     *
;**    LOOP)                                                                    *
;** 4-DELETE ALL THE LINES OF CODE BEGINNING WITH ";**"                         *
;**                                                                             *
;********************************************************************************
;**
;**
;** here is the routine identification
;**
; $Id: xxx_gui.pro,v 5.0 2006/02/01 marcel.carbillet $
;**
;** put right version, date, and main author name of last update in the line
;** here above following the formats:
;** -n.m for the version (n=software release version, m=module update version).
;** -YYYY/MM/DD for the date (YYYY=year, MM=month, DD=day).
;** -first_name.last_name for the (last update) main author name.
;**
;
;**
;** here begins the header of the routine
;**
;+
; NAME:
;    xxx_gui
;
; PURPOSE:
;    xxx_gui generates the Graphical User Interface (GUI) for
;    setting the parameters of the [PUT HERE THE NAME] (XXX) module.
;    a parameter file called xxx_nnnnn.sav is created, where nnnnn
;    is the number n_module associated to the module instance.
;    the file is stored in the project directory proj_name located
;    in the working directory.
;    (see xxx.pro's header --or file xyz_help.html-- for details
;    about the module itself).
;
; CATEGORY:
;    module's Graghical User Interface routine
;
; CALLING SEQUENCE:
;    error = xxx_gui(n_module, $
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
;** describe here the non-IDL routines used by xxx_gui, if any.
;** these routines must be put either in the module's sub-folder
;** !caos_env.modules+"xxx/xxx_gui_lib/", or in the Software
;** Package library folder, or even in the
;** CAOS system library folder !caos_env.lib.
;
; ROUTINE MODIFICATION HISTORY:
;    routine written: date,
;                     author (institute) [email].
;    modifications  : date,
;                     author (institute) [email]:
;                    -description of the modifications.
;                   : date,
;                     author (institute) [email]:
;                    -description of the modifications.
;
;**
;** ROUTINE'S TEMPLATE MODIFICATION HISTORY:
;**    routine written: may 1998,
;**                     Armando Riccardi (OAA) [riccardi@arcetri.astro.it].
;**    modifications  : january 1999,
;**                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;**                    -completed (with more examples)
;**                    -adapted to version 1.0 regarding the initialisation and
;**                     calibration process.
;**                   : february 1999,
;**                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;**                    -a few other modifications for version 1.0.
;**                   : november 1999,
;**                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;**                    -enhanced and adapted to version 2.0 (CAOS), mainly
;**                     regarding the new calibration process.
;**                   : june 2001,
;**                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;**                    -enhanced for version 3.0 of CAOS (package-oriented).
;**                   : january 2003,
;**                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;**                    -simplified templates for the version 4.0 of the
;**                     whole CAOS system (no more use of the COMMON variable
;**                     "calibration" and no more use of the possible
;**                     initialisation file and, obviously, of the calibration
;**                     file as well).
;**                    -now use of the variable info.pack_name, and the
;**                     variable info.mod_type is changed into info.mod_name.
;**                    -(xxx_info()).help stuff added (instead of !caos_env.help).
;**                   : december 2004,
;**                     Marcel Carbillet (LUAN) [marcel.carbillet@unice.fr]:
;**                    -the lack of compatibility between the Software Package
;**                     version presently used within the CAOS Application Builder
;**                     and the Soft. Pack. version under which the parameter file
;**                     was created no longer provoke a crash but only a warning...
;**                     This account from version 5.0 of the Software Package CAOS,
;**                     version 3.0 of the Software Package AIRY, and version 1.0
;**                     of the Software Package MAOS (and any future Soft. Pack.).
;**                    : february 2006,
;**                     Marcel Carbillet (LUAN) [marcel.carbillet@unice.fr]:
;**                    -version-check warning stuff debugged.
;**
;-
;
;**
;** here begins the xxx_gui_set procedure: just eliminate it all if no
;** sensitive checking or other parameter setting is needed
;**
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; status setting procedure ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
pro xxx_gui_set, state

;**
;** show an hourglass if the setting calculus could be a bit long...
;**
widget_control, /HOURGLASS

;**
;** example of sensitive setting/unsetting of sub-bases of the GUI in function
;** of the option chosen in a group of buttons.
;**
case state.par.choice of
    0: begin
        widget_control, state.id.choice0_base, /SENSITIVE
        widget_control, state.id.choice1_base, SENSITIVE=0
    end
    1: begin
        widget_control, state.id.choice0_base, SENSITIVE=0
        widget_control, state.id.choice1_base, /SENSITIVE
    end
endcase

;**
;** example of updating of a widget that gives an indicative parameter
;** (in this simple example twice the value of the parameter needed by
;** "choice0")
;**
dummy = 2*state.par.choice0_param
widget_control, state.id.choice0_test, SET_VALUE=dummy

end

;**
;** here is the event handler procedure xxx_gui_event
;**
;;;;;;;;;;;;;;;;;;;
; GUI events loop ;
;;;;;;;;;;;;;;;;;;;
;
pro xxx_gui_event, event

; xxx_gui error management block
common error_block, error

; read the GUI state structure
widget_control, event.top, GET_UVALUE=state

; handle a kill request (considered as a cancel event).
;**
;** the right error returning is guaranteed only if GROUP_LEADER keyword
;** is set to a valid parent id in the xxx_gui call.
;**
if tag_names(event, /STRUCTURE_NAME) eq 'WIDGET_KILL_REQUEST' then begin
   error = !caos_error.cancel
   widget_control, event.top, /DESTROY
endif

; handle all the other events
widget_control, event.id, GET_UVALUE=uvalue
case uvalue of

   ;**
   ;** the first following cases (before the time integration and delay events
   ;** management) are only a consequence of the examples taken here. take it
   ;** as a widget tutorial.
   ;**

   ;**
   ;** chosen "choice" event management (choice0 or choice1)
   ;** (case of a cw_bgroup widget)
   ;**
   'choice': state.par.choice = event.value

   ;**
   ;** choice0's integer parameter event management
   ;** (case of an editable cw_field widget with an integer value)
   ;**
   'choice0_param': state.par.choice0_param = event.value

   ;**
   ;** choice1's parameter event management
   ;** (case of a cw_fslider widget)
   ;**
   'choice1_param': state.par.choice1_param = event.value

   ;**
   ;** choice1's type event management
   ;** (case of a droplist widget)
   ;**
   'choice1_type': state.par.choice1_type = event.index

   ;**
   ;** the two following event management cases are necessary if time
   ;** integration and/or delay is required for the module. otherwise
   ;** just eliminate this part.
   ;**
   'time_integ': state.par.time_integ = event.value

   'time_delay': state.par.time_delay = event.value

   ;**
   ;** the four following event management are for the standard buttons.
   ;** as a consequence, this part must not be eliminated !!
   ;**
   ; handle event from standard save button
   'save': begin

      ;**
      ;** put in the following cross-check controls among the parameters.
      ;** here are just some examples...
      ;**
      ; cross-check controls among the parameters

      if state.par.choice0_param eq 0 then begin
         dummy = dialog_message(["choice 0 parameter cannot be 0"], $
                                DIALOG_PARENT=event.top,            $
                                TITLE='XXX error',                  $
                                /ERROR                              )
         ;**
         ;** return without saving if the test failed
         ;**
         return
      endif
        
      if state.par.choice1_param eq 0 then begin
         dummy = dialog_message(["choice 1 parameter cannot be 0"], $
                                DIALOG_PARENT=event.top,            $
                                TITLE='XXX error',                  $
                                /ERROR                              )
         ;**
         ;** return without saving if the test failed
         ;**
         return
      endif

      ;**
      ;** end of the cross-check controls
      ;**
 
      ; check before saving the parameter file if filename already exists
      check_file = findfile(state.sav_file)
      if check_file[0] ne "" then begin
         answ = dialog_message(['file '+state.sav_file+' already exists.', $
                                'do you want to overwrite it ?'],          $
                               DIALOG_PARENT=event.top,                    $
                               TITLE='XXX warning',                        $
                               /QUEST)
         ; return without saving if the user doesn't want to overwrite the
         ; existing parameter file
         if strlowcase(answ) eq "no" then return
      endif else begin
         answ = dialog_message(['file '+state.sav_file+' will be saved.'], $
                               DIALOG_PARENT=event.top,                    $
                               TITLE='XXX information',                    $
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
      widget_control, /HOURGLASS
      spawn, !caos_env.browser+" "+(xxx_info()).help+"\#" $
            +strupcase(state.par.module.mod_name)+"&"
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
      ;**
      ;** as usual here, this is based on the present example...
      ;** it must be adapted to the actual case of the module.
      ;**
      widget_control, state.id.choice,        SET_VALUE=par.choice
      widget_control, state.id.choice0_param, SET_VALUE=par.choice0_param
      widget_control, state.id.choice1_param, SET_VALUE=par.choice1_param
      widget_control, state.id.choice1_type,  SET_DROPLIST_SELECT= $
                                                 par.choice1_type
      widget_control, state.id.time_integ,    SET_VALUE=par.time_integ
      widget_control, state.id.time_delay,    SET_VALUE=par.time_delay

      ; update the state structure
      state.par = par

   end

   ; handle event of standard cancel button (exit without saving)
   'cancel': begin
      error = !caos_error.cancel
      widget_control, event.top, /DESTROY
      return
   end

endcase

; reset the setting parameters status
xxx_gui_set, state

; write the GUI state structure
widget_control, event.top, SET_UVALUE=state

return

end

;**
;** here is the actual GUI generation function xxx_gui
;**
;;;;;;;;;;;;;;;;;;;;;;;
; GUI generation code ;
;;;;;;;;;;;;;;;;;;;;;;;
;
function xxx_gui, n_module,  $
                  proj_name, $
                  GROUP_LEADER=group

; error status from the event handler procedure
common error_block, error

; retrieve the module information
info = xxx_info()

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

; build the widget id structure where all the needed (in xxx_gui_event)
; widget's id will be stored
id = $
   { $                     ; widget id structure
   par_base        : 0L, $ ; parameter base id
      choice       : 0L, $ ; choice bgroup id
      choice0_base : 0L, $ ; choice 0 base id
      choice0_param: 0L, $ ; choice 0 parameter field id
      choice0_test : 0L, $ ; choice 0 test parameter field id
      choice1_base : 0L, $ ; choice 1 base id
      choice1_param: 0L, $ ; choice 1 parameter slider id
      choice1_type : 0L, $ ; choice 1 type droplist id
      tab_base     : 0L, $ ; table base id
      tab_row_nb   : 0L, $ ; table number of row id
      tab          : 0L, $ ; table id
      sub_gui      : 0L, $ ; sub-gui call button id
      graphic      : 0L, $ ; graphic id
      time_base    : 0L, $ ; time evolution base id
      time_integ   : 0L, $ ; time integration field id
      time_delay   : 0L  $ ; time delay field id
   }

; build the state structure were par, id, sav_file and def_file will be stored
; (and passed to xxx_gui_event).
state = $
   {    $                ; widget state structure
   sav_file: sav_file, $ ; actual name of the file where save params
   def_file: def_file, $ ; default name of the file where save params
   id      : id,       $ ; widget id structure
   par     : par       $ ; parameter structure
   }

;**
;** the following lines of code defines the whole GUI. it is based on two
;** main sub-bases: the paramaters one, and the standard buttons one.
;** both are mandatory (except for the time evolution management part of
;** the parameters sub-base).
;**
; root base definition
modal = n_elements(group) ne 0
dummy = strupcase(info.mod_name)+' parameters setting GUI'
root_base_id = widget_base(TITLE=dummy, MODAL=modal, /COL, GROUP_LEADER=group)

; set the status structure
widget_control, root_base_id, SET_UVALUE=state

   ; parameters base
   state.id.par_base = widget_base(root_base_id, FRAME=10, ROW=2)
   dummy = widget_label(state.id.par_base, VALUE='parameters', /FRAME)
   par_base_id = widget_base(state.id.par_base, /ROW)

   ;**
   ;** in this example there are two parameters sub-bases (choice_base_id
   ;** and state.id.time_base) that are distibuted in two colums (keyword /ROW
   ;** above).
   ;**

      ; parameters sub-bases:
      ; example: choice between two cases/methods/algorithms/etc.
      choice_base_id = widget_base(par_base_id, $
                                   /FRAME,      $
                                   ROW=4        )

         ; label widget for the base 'choice_base_id'
         dummy = widget_label(choice_base_id,                               $
                              VALUE=                                        $
                    'here are a choice to make and some parameters to set', $
                              /FRAME                                        )

         ; example of an exclusive bgroup
         state.id.choice = cw_bgroup(choice_base_id,                $
                                     label_left = 'which choice ?', $
                                     ['choice 0','choice 1'],       $
                                     COLUMN=2,                      $
                                     SET_VALUE=state.par.choice,    $
                                     /EXCLUSIVE,                    $
                                     UVALUE='choice'                )

         ; sub-base for choice0
         state.id.choice0_base = widget_base(choice_base_id, $
                                             COL=3           )
            ; example of an editable integer field
            state.id.choice0_param = cw_field(state.id.choice0_base,          $
                                              TITLE='choice 0 param. [unit]', $
                                              /COLUMN,                        $
                                              VALUE=state.par.choice0_param,  $
                                              /INTEGER,                       $
                                              UVALUE="choice0_param",         $
                                              /ALL_EVENTS                     )
            ; example of a non-editable integer field
            state.id.choice0_test = cw_field(state.id.choice0_base,            $
                                            TITLE='(twice choice 0 param is)', $
                                            /COLUMN,                           $
                                            VALUE=2*state.par.choice0_param,   $
                                            /INTEGER,                          $
                                            /NOEDIT                            )

         ; choice 1 sub-base
         state.id.choice1_base = widget_base(choice_base_id, $
                                             COL=2           )
            ; example of an editable float field with a slider
            state.id.choice1_param = cw_fslider(state.id.choice1_base,         $
                                                TITLE='choice 1 parameter',    $
                                                VALUE=state.par.choice1_param, $
                                                MAXIMUM=1, SCROLL=.05,         $
                                                UVALUE="choice1_param",        $
                                                /EDIT,                         $
                                                /DRAG                          )
            ; array for droplist
            dummy = $
               [    $
               'first  type', $
               'second type', $
               'third  type', $
               'fourth type', $
               'fifth  type', $
               'sixth  type'  $
               ]
            ; example of a droplist widget
            state.id.choice1_type = widget_droplist(state.id.choice1_base,   $
                                                    TITLE='choice 1 type: ', $
                                                    VALUE=dummy,             $
                                                    UVALUE='choice1_type'    )
            ; set droplist default value
            widget_control, state.id.choice1_type, $
                            SET_DROPLIST_SELECT=state.par.choice1_type

      ; time evolution
      state.id.time_base = widget_base(par_base_id, $
                                       /FRAME,      $
                                       ROW=3        )
         ; label widget for the base 'state.id.time_base'
         dummy = widget_label(state.id.time_base,VALUE='time evolution',/FRAME)
         ; integration time widget
         state.id.time_integ = cw_field(state.id.time_base,                   $
                                        TITLE='integration [base-time unit]', $
                                        /COLUMN,                              $
                                        VALUE=state.par.time_integ,           $
                                        /INTEGER,                             $
                                        UVALUE='time_integ',                  $
                                        /ALL_EVENTS                           )
         ; delay time widget
         state.id.time_delay = cw_field(state.id.time_base,                   $
                                        TITLE='delay [base-time unit]',       $
                                        /COLUMN,                              $
                                        VALUE=state.par.time_delay,           $
                                        /INTEGER,                             $
                                        UVALUE='time_delay',                  $
                                        /ALL_EVENTS                           )

   ;**
   ;** the following lines of code deal with the standard buttons.
   ;**

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

;**
;** eliminate the following line if the function xxx_gui_set is not required
;**
; initialize all the sensitive states
xxx_gui_set, state

;**
;** do not modify the following lines (except for changing xxx onto the
;** module three-characters name).
;**
; save the state structure of the GUI in the top base uvalue
widget_control, root_base_id, SET_UVALUE=state

; draw the GUI
widget_control, root_base_id, /REALIZE

; launch xmanager
xmanager, 'xxx_gui', root_base_id, GROUP_LEADER=group

; back to the main calling program
return, error
end
