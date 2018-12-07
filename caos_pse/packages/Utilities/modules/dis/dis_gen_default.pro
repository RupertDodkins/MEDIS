; $Id: dis_gen_default.pro,v 7.0 2016/04/21 marcel.carbillet $
;+
; NAME:
;    dis_gen_default
;
; PURPOSE:
;    dis_gen_default generates the default parameter structure
;    for the module DIS of package "Utilities" and save it in the
;    rigth location.
;
; CATEGORY:
;    module's utility routine
;
; CALLING SEQUENCE:
;    dis_gen_default
; 
; MODIFICATION HISTORY:
;    program written: april 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr],
;                     Andrea La Camera (DIBRIS) [andrea.lacamera@unige.it]:
;                    -global merging of dsp_gen_default of module DSP (from Soft.
;                     Pack. AIRY 6.1 ) and dis_gen_default of module DIS (from Soft.
;                     Pack. CAOS 5.2) for new CAOS Problem-Solving Env. 7.0.
;    modifications  : date,
;                     author (institute) [email@address]:
;                    -description of modification.
;
;-
;
pro dis_gen_default

; obtain module infos
info = dis_info()

; generate module description structure.
module = gen_def_module(info.mod_name, info.ver)

device, GET_SCREEN_SIZE=dim

par = $
   {  $
   dis,                  $ ; structure named dis
   module    : module,   $ ; module description structure
   title     : 0,        $ ; control flag for optional title
   title_info: "",       $ ; string for user-defined title
   iteration : 1,        $ ; iterations for each display operation
   type      : 0,        $ ; display type (0=normal, 1=log10, 2=power)
   power     : 1.,       $ ; power at which the display has to be done
   color     : 0,        $ ; color table (by loadct)
   xsize     : dim[0]/3, $ ; default size of the frame - X - 
   ysize     : dim[1]/3, $ ; default size of the frame - Y -   
   zoom_fac  : 1         $ ; zoom-in factor at which the display has to be done
   }

; save the default parameter structure in the file def_file
save, par, FILENAME=info.def_file

end