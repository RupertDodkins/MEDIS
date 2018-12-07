;**
;*******************************************************************************
;** HOW TO USE THIS TEMPLATE:                                                  *
;**                                                                            *
;** 0-READ THE WHOLE TEMPLATE ONCE !!                                          *
;** 1-CHANGE EVERYWHERE THE STRINGS "XXX" INTO THE CHOSEN 3-CHAR MODULE NAME   *
;**   (CHANGE AS WELL THE POSSIBLE "YYY", "ZZZ", "AAA", AND "BBB" STRINGS INTO *
;**    THE, RESPECTIVELY, FIRST INPUT STRUCTURE TYPE NAME, SECOND INPUT        *
;**    STRUCTURE TYPE NAME, FIRST OUTPUT STRUCTURE TYPE NAME, AND SECOND       *
;**    OUTPUT STRUCTURE TYPE NAME)                                             *
;** 2-ADAPT THE TEMPLATE ONTO THE NEW MODULE CASE FOLLOWING THE EXAMPLES,      *
;**   RECOMMENDATIONS, AND ADVICES FOUND THROUGH THE TEMPLATE                  *
;** 3-DELETE *ALL* THE LINES OF CODE BEGINNING WITH ";**"                      *
;**                                                                            *
;*******************************************************************************
;**
;**
;** here is the routine identification
;**
; $Id: xxx_prog.pro,v 5.1 2005/07/04 marcel.carbillet $
;**
;** put right version, date, and main author name of last update in the line
;** here above following the formats:
;** -n.m for the version (n=software release version, m=module update version).
;** -YYYY/MM/DD for the date (YYYY=year, MM=month, DD=day).
;** -first_name.last_name for the (last update) main author name.
;**
;+
; NAME:
;    xxx_prog
;
; PURPOSE:
;    xxx_prog represents the program routine for the [PUT HERE THE NAME]
;    (XXX) module, that is:
;
;**
;**  DESCRIBE HERE WHAT KIND OF OPERATIONS THE ROUTINE XXX_PROG PERFORMS,
;**  (POSSIBLY IN FUNCTION OF THE INPUTS DATA STATUS -- valid, not_valid,
;**  wait -- AND THE FACT THAT THEY WERE DEFINED AS OPTIONAL OR NOT IN
;**  XXX_INFO).
;**
;
;    (see xxx.pro's header --or file xyz_help.html-- for details about the
;    module itself).
;
; CATEGORY:
;    module's program routine
;
; CALLING SEQUENCE:
;    error = xxx_prog(inp_yyy_t, $ ; yyy_t input structure
;                     inp_zzz_t, $ ; zzz_t input structure
;                     out_aaa_t, $ ; aaa_t output structure
;                     out_bbb_t, $ ; bbb_t output structure 
;                     par,       $ ; parameters structure
;                     INIT=init  $ ; initialisation data structure
;                     ) 
;
; INPUTS/OUTPUTS/KEYWORDS/ETC.:
;    see module help for a detailed description. 
;
; ROUTINE MODIFICATION HISTORY: 
;    routine written: date,
;                     author (institute) [e-mail].
;    modifications  : date,
;                     author (institute) [e-mail]:
;                    -description of modifications made.
;                   : date,
;                     author (institute) [e-mail]:
;                    -description of modifications made.
;** 
;** ROUTINE'S TEMPLATE MODIFICATION HISTORY: 
;**    routine written: november 1998,
;**                     Armando Riccardi (OAA) [riccardi@arcetri.astro.it].
;**    modifications  : february 1999,
;**                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;**                    -a few modifications for version 1.0.
;**                   : november 1999,
;**                     Marcel Carbillet (OAA) [marcel@arcetro.astro.it]:
;**                    -enhanced and adapted to version 2.0 (CAOS).
;**                   : march+june 2001,
;**                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;**                    -enhanced for version 3.0 of CAOS (package-oriented).
;**                   : january 2003,
;**                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;**                    -simplified templates for the version 4.0 of the
;**                     whole CAOS system (no more use of the COMMON variable
;**                     "calibration" and no more use of the possible
;**                     initialisation file and, obviously, of the calibration
;**                     file as well).
;**
;-
; 
;**
;** here begins the module's program routine code
;**
function xxx_prog, inp_yyy_t, $ ; 1st input struc.  ;** DELETE if no input
                   inp_zzz_t, $ ; 2nd input struc.  ;** DELETE if no 2nd input
                   out_aaa_t, $ ; 1st output struc. ;** DELETE if no output
                   out_bbb_t, $ ; 2nd output struc. ;** DELETE if no 2nd output
                   par,       $ ; XXX parameters structure
                   INIT=init    ; XXX initialization data structure

;**
;** DELETE the following common call if the number of iterations is not
;** required here
;**
; CAOS global common block
common caos_block, tot_iter, this_iter

; error code initialization
error = !caos_error.ok

;**
;** check here the inp_yyy_t.data_status and inp_zzz_t.data_status
;** in order to choose the behaviour of the routine xxx for the different
;** cases.
;**
;** in the following we give a somehow complicate example where the 1st input
;** is not optional, and the 2nd input can be optional (as defined in xxx_info)
;**
;** in most of the cases, especially when there is no input, the whole present
;** routine will only contain the few following lines that updates the output:
;** (note that the output structures were already defined during the
;** initialisation process -- see xxx_init)
;**
;**    out_aaa_t.data_status = !caos_data.valid
;**    fill here the other tags in out_aaa_t structures
;**
;**    out_bbb_t.data_status = !caos_data.valid
;**    fill here the other tags in out_bbb_t structures
;**
;** if this is the case, do not take into account the example, delete untill
;** the last lines of this file, and fill it with the above described lines of
;** code.
;**

ds1 = inp_yyy_t.data_status
ds2 = inp_zzz_t.data_status

; the 1st input is not optional in this example
if ds1 eq !caos_data.not_valid then message, $
   'the 1st input cannot have a not_valid data status.'

if ds1 eq !caos_data.wait then begin
   ;**
   ;** rise an error here if wait data status is not allowed,
   ;** otherwise check the 2nd input (if present):
   ;**
   case 1B of
      (ds2 eq !caos_data.not_valid) or (ds2 eq !caos_data.wait): begin
         ; no valid input, so a wait data status is sent to the next modules
         ;**
         ;** it's only an example...
         ;**
         out_aaa_t.data_status = !caos_data.wait
         out_bbb_t.data_status = !caos_data.wait

         return, error
      end

      ds2 eq !caos_data.valid: begin
         ;**
         ;** put here the code needed to handle this case
         ;**

         ; build the suitable output
         ;**
         ;** for instance:
         ;** out_aaa_t.data_status = !caos_data.valid
         ;** fill here the other tags in out_aaa_t structures
         ;**
         ;** out_bbb_t.data_status = !caos_data.valid
         ;** fill here the other tags in out_bbb_t structures
         ;**

         return, error
      end

      else: begin
         ; this is the case in which the 2nd input does not match
         ; any defined data status
         message, 'the 2nd input has an invalid data status'
      end
   endcase
end

if ds1 eq !caos_data.valid then begin
   case 1B of
      (ds2 eq !caos_data.not_valid) or (ds2 eq !caos_data.wait): begin
         ;**
         ;** put here the code to manage this case
         ;**

         ; build the suitable output
         ;**
         ;** for instance:
         ;**
         ;** out_aaa_t.data_status = !caos_data.valid
         ;** fill here the other tags in out_aaa_t structures
         ;**
         ;** out_bbb_t.data_status = !caos_data.valid
         ;** fill here the other tags in out_bbb_t structures
         ;**

         return, error
      end

      ds2 eq !caos_data.valid: begin
         ;**
         ;** put here the code to manage this case
         ;**

         ; build the suitable output
         ;**
         ;** for instance:
         ;**
         ;** out_aaa_t.data_status = !caos_data.valid
         ;** fill here the other tags in out_aaa_t structures
         ;**
         ;** out_bbb_t.data_status = !caos_data.valid
         ;** fill here the other tags in out_bbb_t structures
         ;**

         return, error
      end

      else: begin
         ; this is the case in which the 2nd input does not match any
         ; defined data status
         message, 'the 2nd input has an invalid data status'
      end
   endcase
endif

; this is the case in which the 1st input does not match
; any defined data status
message, 'the 1st input has an invalid data status'

return, error
end
