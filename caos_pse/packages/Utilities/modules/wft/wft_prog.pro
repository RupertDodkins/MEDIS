; $Id: wft_prog.pro,v 7.0 last revision 2016/06/10 Andrea La Camera $
;+
; NAME:
;    wft_prog
;
; PURPOSE:
;    wft_prog represents the scientific algorithm for the
;    Write Fits file formaT (WFT) module.
;
; CATEGORY:
;    module's program routine
;
; CALLING SEQUENCE:
;    error = wft_prog(inp_img_t, $ ; img_t input structure
;                     par )        ; parameters structure
;
; INPUTS/OUTPUTS/KEYWORDS/ETC.:
;       see module help for a detailed description. 
;
; ROUTINE MODIFICATION HISTORY: 
;    routine written: october 2000,
;                     Serge Correia (OAA) [correia@arcetri.astro.it].
;    modifications  : february 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -use of variable "calibration" eliminited for version 4.0
;                     of the whole system CAOS.
;                    :january 2005,
;                     Gabriele Desidera' (DISI) [desidera@disi.unige.it]
;                    -add the possibility to write multiple images for multiple iterations  
;                   : for version 5.0,
;                     Andrea La Camera (DISI) [lacamera@disi.unige.it]:
;                    -INIT eliminated (obsolete).
;                   : from CAOS_PSE v 7.0 (2016) 
;                    -this module has been moved from AIRY 6.1 to the new 
;                     package "Utilities". Version number has been
;                     reset to 1.0. 
;                   : may 2016,
;                     Andrea La Camera (DIBRIS) [andrea.lacamera@unige.it]:
;                    -header (if present, defined by previous modules) is
;                     saved, together with the usual WFT keywords. To
;                     do this, a copy of the input structure is needed. 
;                     Two new routines have been added for this purpose. 
;                    -TIME_IN change in EXPTIME (worldwide used)
;                    -small changes in imstruc_to_fits.pro:
;                     simplified call sequence, passing the header, etc.
;
;-
;
function wft_prog, inp_img_t, par
  
; CAOS global common block
  common caos_block, tot_iter, this_iter
  
; initialization of the error code: no error as default
  error = !caos_error.ok
  
; save image every wich nb of iterations ?
  if par.end_iter eq 1 then begin 
     iteration=tot_iter 
     n_struc = 1
  endif else begin 
     iteration=long(par.iteration)
     n_struc = tot_iter/iteration
  endelse
  
; Is the header within the inp_img_t structure? If so, delete the
; header (as a pointer) from the structure and treat it as a
; "standard" header for the following mwrfits and imstruct_to_fits 
; procedures...
; Moreover (IMPORTANT!) we need to operate on a copy of the structure 
; and not on the structure itself! 
  inp_img_t_copy = inp_img_t
  
  if TAG_EXIST(inp_img_t_copy, 'HEADER') then begin
     header = *inp_img_t_copy.header
     struct_delete_field, inp_img_t_copy, 'header'
  endif else begin 
     mkhdr, header, inp_img_t_copy.image ;create new header otherwise
  endelse
  pos=strpos(par.data_file,'.',/reverse_search)
; program itself
  if inp_img_t.data_status EQ !caos_data.valid then begin
                                ; FITS case
     if (this_iter mod iteration EQ 0) then begin
        if ((size(inp_img_t_copy.image))[0]) eq 3 then begin 
           if n_struc gt 1 then begin
              name=strmid(par.data_file,0,pos)+'_'+strcompress(string(0),/remove_all)+'.fits'    
              mwrfits, inp_img_t_copy, name
           endif else begin
              mwrfits, inp_img_t_copy, par.data_file
           endelse
        endif else begin
           mwrfits, inp_img_t_copy, par.data_file
        endelse
     endif
     
     if (this_iter mod tot_iter EQ 0) then begin 
        if ((size(inp_img_t_copy.image))[0]) eq 3 then begin
           if n_struc gt 1 then begin 
              name=strmid(par.data_file,0,pos)+'_'+strcompress(string(0),/remove_all)+'.fits'
              imstruc_to_fits, name, n_struc, header
           endif else begin
              imstruc_to_fits, par.data_file, n_struc, header
           endelse
        endif else begin
           imstruc_to_fits, par.data_file, n_struc, header
        endelse
     endif
  end
  
; back to calling program
  return, error
end
