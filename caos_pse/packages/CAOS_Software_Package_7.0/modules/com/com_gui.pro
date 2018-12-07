; $Id: com_gui.pro,v 7.0 2016/05/19 marcel.carbillet@unice.fr $
;+
; NAME:
;    com_gui
;
; PURPOSE:
;    com_gui generates the Graphical User Interface (GUI) for
;    setting the parameters of the COMbine measurements (COM) module.
;    a parameter file called com_nnnnn.sav is created, where nnnnn
;    is the number n_module associated to the module instance.
;    the file is stored in the project directory proj_name located
;    in the working directory.
;    (see com.pro's header --or file caos_help.html-- for details
;    about the module itself).
;
; CATEGORY:
;    module's Graghical User Interface routine
;
; CALLING SEQUENCE:
;    error = com_gui(n_module, proj_name )
; 
; INPUTS:
;    n_module : number associated to the intance of the COM module
;               [integer scalar -- n_module > 0].
;    proj_name: name of the current project [string].
;
; OUTPUTS:
;    error: error code [long scalar].
;
; COMMON BLOCKS:
;    none.
;
; ROUTINE MODIFICATION HISTORY:
;    routine written: february 2001,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it].
;    modifications  : march 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -adapted to new CAOS system (4.0) and building of
;                     Software Package MAOS 1.0.
;                   : april 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;
;-
;
function com_gui, n_module,  $
                  proj_name, $
                  GROUP_LEADER=group

; error status from the event handler procedure
common error_block, error

; initialization of the error code
error = !caos_error.ok

; retrieve the module information
info = com_info()

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
   if (par.module.ver ne info.ver) then       $
      message, 'the parameter file '+sav_file $
              +' is not compatible: please generate it again'
endelse

save, par, FILE=sav_file

; back to the main calling program
return, error
end