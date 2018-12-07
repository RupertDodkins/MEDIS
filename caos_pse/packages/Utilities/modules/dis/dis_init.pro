; $Id: dis_init.pro,v 7.0 2016/04/21 marcel.carbillet $
;+ 
; NAME: 
;    dis_init 
; 
; PURPOSE: 
;    dis_init executes the initialization for the DISplay (DIS)
;    module of package "Utilities".
; 
; CATEGORY: 
;    initialisation program 
; 
; CALLING SEQUENCE: 
;    error = dis_init(inp_yyy_t, $ ; yyy_t input structure
;                     par,       $ ; parameters structure
;                     INIT=init  ) ; initialisation structure
; 
; INPUTS/OUTPUTS/KEYWORDS/ETC.: 
;    see module help for a detailed description. 
; 
; ROUTINE MODIFICATION HISTORY:
;    program written: april 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr],
;                     Andrea La Camera (DIBRIS) [andrea.lacamera@unige.it]:
;                    -global merging of dsp_init of module DSP (from Soft.
;                     Pack. AIRY 6.1 ) and dis_init of module DIS (from Soft.
;                     Pack. CAOS 5.2) for new CAOS Problem-Solving Env. 7.0.
;    modifications  : date,
;                     author (institute) [email@address]:
;                    -description of modification.
;
;- 
;
function dis_init, inp_yyy_t, $
                   par,       $
                   INIT=init 

; CAOS global common block
common caos_block, tot_iter, this_iter

; initialization of the error code: no error as default
error = !caos_error.ok 

; retrieve the input and output information
info = dis_info()
 
; get the individual output structure types
if info.out_type ne '' then out_type = str_sep(info.out_type,",")

; compute and test the requested number of dis arguments
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

; test the number of passed parameters
if n_params() ne n_par then message, 'wrong number of parameters'

; test the parameter structure
if test_type(par, /STRUCTURE, N_ELEMENTS=n) then $
   message, 'DIS error: par must be a structure'
if n ne 1 then message, 'DIS error: par cannot be a vector of structures'
if strlowcase(tag_names(par, /STRUCTURE_NAME)) ne info.mod_name then $
   message, 'par must be a parameter structure for the module DIS'

; test if any optional input exists
if n_inp gt 0 then begin
   inp_opt = info.inp_opt
endif

; check the input arguments
dummy = test_type(inp_yyy_t, TYPE=type)
if type eq 0 then begin         ; undefined variable
   inp_yyy_t = $
      {        $
      data_type  : inp_type[0],         $
      data_status: !caos_data.not_valid $
      }
endif
if test_type(inp_yyy_t, /STRUC, N_EL=n, TYPE=type) then $
   message, 'DIS error: wrong definition for the first input.'
if n ne 1 then message, $
   'DIS error: first input cannot be a vector of structures'

; test the data type
if inp_type[0] ne 'gen_t' then begin
   if inp_yyy_t.data_type ne inp_type[0] then                $
      message, 'wrong input data type: '+inp_yyy_t.data_type $
              +' ('+inp_type[0]+' expected).'
endif

if inp_yyy_t.data_status eq !caos_data.not_valid and not inp_opt[0] then $
      message, 'undefined input is not allowed'

; initialisation structure building

type = inp_yyy_t.data_type
mod_n = strtrim(string(par.module.n_module),2)

unit_run   = 0L

; initialisation structure

if type eq 'img_t' then begin
   if (((size(inp_yyy_t.image))[0] eq 3) || ((size(inp_yyy_t.image))[0] eq 4))then begin
      n_images  = (size(inp_yyy_t.image))[3]
      win_index = lindgen(n_images)
   endif else win_index = 0L
endif else win_index = 0L

init = $
   {   $
   type            : inp_yyy_t.data_type, $
   unit_run        : unit_run,            $
   dis_counter     : 0L,                  $
   win_xsize       : par.xsize,           $
   win_ysize       : par.ysize,           $
   win_index       : win_index,           $
   win_wait_confirm: 0L,                  $
   win_quit        : 0L                   $
   }

if par.title_info EQ " " then                                        $
   title = 'displaying '+init.type+' data from DIS module # '+mod_n  $
else title = par.title_info

;load color table
loadct, par.color, /SILENT

case init.type of

   'wfp_t': begin
   nll = n_elements(inp_yyy_t.pos_ang)
   if nll gt 1 then begin
      init.win_xsize = nll * init.win_ysize $
           + (init.win_xsize-init.win_ysize)
      dummy = win_pos_manager( init.win_index $
                             , init.win_xsize $
                             , init.win_ysize $
                             , TITLE=title    )
      init.win_index = !D.WINDOW
   endif else begin
   dummy = win_pos_manager( init.win_index $
                          , init.win_xsize $
                          , init.win_ysize $
                          , TITLE=title    )
   init.win_index = !D.WINDOW
   endelse
   end

   'atm_t': begin
     n_layers = n_elements(inp_yyy_t.alt)
     init.win_xsize = n_layers * init.win_ysize $
               + (init.win_xsize-init.win_ysize)
     dummy = win_pos_manager( init.win_index $
                            , init.win_xsize $
                            , init.win_ysize $
                            , TITLE=title    )
     init.win_index = !D.WINDOW
   end

   'img_t': begin
      if (((size(inp_yyy_t.image))[0] eq 3) || ((size(inp_yyy_t.image))[0] eq 4)) $
      then begin
         for i=0, (size(init.win_index))[1]-1 do begin
            dummy = win_pos_manager( init.win_index[i]             $
                                   , init.win_xsize                $
                                   , init.win_ysize                $
                                   , TITLE=title+" #"+strtrim(i,2) )
            init.win_index[i] = !D.WINDOW
         endfor
      endif else begin
         dummy = win_pos_manager( init.win_index $
                                , init.win_xsize $
                                , init.win_ysize $
                                , TITLE=title    )
         init.win_index = !D.WINDOW
      endelse
   end

   'src_t': begin
      if ((size(inp_yyy_t.map))[0] eq 0) then begin
         dummy = dialog_message("point-like source: quitting display !!")
      endif else begin
         dummy = win_pos_manager( init.win_index $
                                , init.win_xsize $
                                , init.win_ysize $
                                , TITLE=title    )
         init.win_index = !D.WINDOW
      endelse
   end

   'com_t':begin
      case inp_yyy_t.flag of
        0: begin
           dummy = dialog_message('Displaying commands data on log window' $
                                 , /INFO ,TITLE=title)
           init.win_index =-1L
        end
        1: begin
           dummy = dialog_message('Displaying modes data on log window' $ 
                                 , /INFO ,TITLE=title)
           init.win_index =-1L
        end
        -1: begin
           dummy = win_pos_manager( init.win_index $
                                  , init.win_xsize $
                                  , init.win_ysize $
                                  , TITLE=title    )
           init.win_index = !D.WINDOW
        end
        else: print, 'unknown display case in com_t data !!!!'
      endcase
   end

   'mes_t': begin
      if (size(inp_yyy_t.meas))[0] eq 2 then begin 
         nll = (size(inp_yyy_t.meas))[2]
         init.win_xsize = nll * init.win_xsize *2 $
              + (init.win_xsize-init.win_ysize)
         dummy = win_pos_manager( init.win_index $
                                , init.win_xsize $
                                , init.win_ysize $
                                , TITLE=title    )
         init.win_index = !D.WINDOW
      endif else begin
         dummy = win_pos_manager( init.win_index $
                                , init.win_xsize*2 $
                                , init.win_ysize $
                                , TITLE=title    )
         init.win_index = !D.WINDOW
      endelse
   end
   
   'mim_t' : begin
      if (size(inp_yyy_t.image))[0] eq 3 then begin
         nll = (size(inp_yyy_t.image))[3]
         init.win_xsize = nll * init.win_ysize $
              + (init.win_xsize-init.win_ysize)
         dummy = win_pos_manager( init.win_index $
                                , init.win_xsize $
                                , init.win_ysize $
                                , TITLE=title    )
         init.win_index = !D.WINDOW
      endif else begin
         dummy = win_pos_manager( init.win_index $
                                , init.win_xsize $
                                , init.win_ysize $
                                , TITLE=title    )
         init.win_index = !D.WINDOW
      endelse
   end

   else: begin
      dummy = win_pos_manager( init.win_index $
                             , init.win_xsize $
                             , init.win_ysize $
                             , TITLE=title    )
      init.win_index = !D.WINDOW
   end

endcase

return, error 
end
