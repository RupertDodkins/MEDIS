;**
;*******************************************************************************
;** HOW TO USE THIS TEMPLATE:                                                  *
;**                                                                            *
;** 0-READ THE WHOLE TEMPLATE ONCE !!                                          *
;** 1-CHANGE EVERYWHERE THE STRINGS "XXX" IN THE CHOSEN 3-CHAR MODULE NAME     *
;**   (CHANGE AS WELL THE POSSIBLE "YYY", "ZZZ", "AAA", AND "BBB" STRINGS INTO *
;**    THE, RESPECTIVELY, FIRST INPUT STRUCTURE TYPE NAME, SECOND INPUT        *
;**    STRUCTURE TYPE NAME, FIRST OUTPUT STRUCTURE TYPE NAME, AND SECOND       *
;**    OUTPUT STRUCTURE TYPE NAME)                                             *
;** 2-ADAPT THE TEMPLATE ONTO THE NEW MODULE CASE FOLLOWING THE EXAMPLES,      *
;**   RECOMMENDATIONS, AND ADVICES FOUND THROUGH THE TEMPLATE                  *
;** 3-DELETE ALL THE LINES OF CODE BEGINNING WITH ";**"                        *
;**                                                                            *
;*******************************************************************************
;**
;**
;** here is the routine identification
;**
; $Id: xxx.pro,v 5.1 2006/01/25 marcel.carbillet $
;**
;** line here above automatically generated...
;**
;+
; NAME:
;    xxx
;
; ROUTINE'S PURPOSE:
;    xxx manages the simulation for the [PUT HERE THE NAME] (XXX) module,
;    that is:
;       1-call the module's initialisation routine xxx_init at the first
;         iteration of the simulation project,
;       2-call the module's program routine xxx_prog otherwise, managing
;         at the same time the possible time integration/delay.
;**
;** put here all other possible informations about how the routine works.
;**
;
; MODULE'S PURPOSE:
;**
;** place here a DETAILED descrition about the module and its Graphical User
;** Interface. this will be used used as the module help in the global CAOS
;** hyper-text help file xyz_help.html.
;**
;** here is a general description of the overall set of module's routines:
;**
;*******************************************************************************
;** HOW A MODULE IS ORGANISED:                                                 *
;**                                                                            *
;** EACH MODULE IS MADE OF A GIVEN GROUP OF STANDARD ROUTINES (SIX). TWO OF    *
;** THEM ARE DIRECTLY CALLABLE BY THE USER:                                    *
;**                                                                            *
;**   xxx_gui.pro: GUI definition for saving the parameters associated to an   *
;**                instance of a module in a standard location and structure.  *
;**   xxx.pro    : function to call in order to run the module simulation. the *
;**                inputs are tested, time behaviour of the module is managed  *
;**                and the right code is called depending on the current status*
;**                of the simulation: initialization status or running status. *
;**                                                                            *
;** AND THE REMAINING FOUR ARE MODULE'S UTILITY ROUTINES:                      *
;**                                                                            *
;**   xxx_info.pro       : function returning info on the module: description, *
;**                        input, output, initialization is needed or not, etc.*
;**   xxx_gen_default.pro: function where the parameters needed by the module  *
;**                        are defined and saved in a standard location and    *
;**                        structure (the file xxx_default.sav). it is used    *
;**                        only during the module developing.                  *
;**   xxx_init.pro       : function called during the initialization process,  *
;**                        by xxx.pro (this is where the initialisation data   *
;**                        are computed). do not call it directly.             *
;**   xxx_prog.pro       : function containing the algorithm that simulates    *
;**                        the module. this is where the main code of the      *
;**                        module is. it has to be called from xxx.pro, do not *
;**                        call it directly.                                   *
;**                                                                            *
;** IN ADDITION, TWO SUB-FOLDERS CAN BE USED TO STORE SUB-ROUTINES USED EITHER *
;** FOR THE GUI OR THE MODULE'S ROUTINES:                                      *
;**                                                                            *
;**    xxx_gui_lib: library of routines specific to the program xxx_gui.pro.   *
;**                                                                            *
;**    xxx_lib    : library of routines specific to the program(s) xxx.pro,    *
;**                 xxx_init.pro, and/or xxx_prog.pro.                         *
;**                                                                            *
;** NOTE THAT UTILITY ROUTINES OF GENERAL INTEREST FOR THE PACKAGE (I.E. FOR   *
;** SEVERAL MODULES OF THE SAME PACKAGE OR AS A STANDALONE ROUTINE) COULD BE   *
;** THOUGHT TO BE STORED IN THE PACKAGE FOLDER !CAOS_ENV.PACK_LIB, OR EVEN, IF *
;** OF MORE GENERAL INTEREST IN THE CAOS SYSTEM FOLDER !CAOS_ENV.LIB.          *
;**                                                                            *
;*******************************************************************************
;
; CATEGORY:
;    main module's routine
;
; CALLING SEQUENCE:
;    error = xxx(inp_yyy_t, $ ; 1st input structure
;                inp_zzz_t, $ ; 2nd input structure
;                out_aaa_t, $ ; 1st output structure
;                out_bbb_t, $ ; 2nd output structure
;                par,       $ ; parameter structure
;                INIT=init, $ ; initialisation data structure
;                TIME=time  ) ; time integration/delay structure
;**
;** in this example we describe the generic example of a module with 2 inputs
;** and 2 outputs, that needs initialisation data and time integration/delay
;** management.
;** if your module needs just one or even no input, and/or just one or even no
;** output, and/or no time integration/delay management, just DELETE
;** the concerned lines above and below.
;** 
;
; OUTPUT:
;    error: long scalar (error code, see !caos_error var in caos_init.pro).
;
; INPUTS:
;    inp_yyy_t: structure of type yyy_t.
;**
;** describe here this input
;**
;    inp_zzz_t: structure of type zzz_t.
;**
;** describe here this input
;**
;    par      : parameters structure.
;**
;** describe here the parameters file
;**
;
; INCLUDED OUTPUTS:
;    out_aaa_t: structure of type aaa_t.
;**
;** describe here this output
;**
;    out_bbb_t: structure of type bbb_t.
;**
;** describe here this output
;**
;
; KEYWORD PARAMETERS:
;**
;** the keyword INIT is needed only if an initialisation is requested
;**
;    INIT: initialisation data structure.
;**
;** the keyword TIME is needed only if time integration/delay is requested
;**
;    TIME: time-evolution structure.
;
; COMMON BLOCKS:
;    common caos_block, tot_iter, this_iter
;
;    tot_iter   : total number of iteration during the simulation run.
;    this_iter  : current iteration number.
;
; SIDE EFFECTS:
;    none.
;**
;** describe here the possible side effects
;**
;
; RESTRICTIONS:
;    none.
;**
;** describe here the possible restrictions using the module
;**
;
; CALLED NON-IDL FUNCTIONS:
;    none.
;**
;** describe here the non-IDL routines used by xxx.pro, if any.
;** these routines must be put either in the module's sub-folder
;** !caos_env.modules+"xxx/xxx_lib/", or in the Package library
;** folder !caos_env.pack_lib, or even in the CAOS system library
;** !caos_env.lib.
;**
;
; ROUTINE MODIFICATION HISTORY:
;    routine written: date,
;                     author (institute) [e-mail].
;    modifications  : date,
;                     author (institute) [e-mail]:
;                    -description of the modifications.
;                   : date,
;                     author (institute) [e-mail]:
;                    -description of the modifications.
;
; MODULE MODIFICATION HISTORY:
;    module written : author (institute) [e-mail].
;    modifications  : for version software_version,
;                     author (institute) [e-mail]:
;                    -modifications made.
;**
;** ROUTINE'S TEMPLATE MODIFICATION HISTORY:
;**    routine written: may 1998,
;**                     Armando Riccardi (OAA) [riccardi@arcetri.astro.it].
;**    modifications  : november 1998,
;**                     Armando Riccardi (OAA) [riccardi@arcetri.astro.it]:
;**                    -completely re-written in order to manage the
;**                     initialization process, calibration loop and timing
;**                     support.
;**                   : january/february 1999,
;**                     Armando Riccardi (OAA) [riccardi@arcetri.astro.it],
;**                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;**                    -some modifications/corrections for version 1.0.
;**                   : november 1999,
;**                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;**                    -enhanced and adapted to version 2.0 (CAOS).
;**                    -help lines completely modified.
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
;**                   : january 2006,
;**                     Marcel Carbillet (LUAN) [marcel.carbillet@unice.fr]:
;**                    -xxx_par --> par (!).
;**
;** MODULE'S TEMPLATES MODIFICATION HISTORY:
;**    module written : Armando Riccardi (OAA) [riccardi@arcetri.astro.it].
;**    modifications  : for version 1.0,
;**                     Armando Riccardi (OAA) [riccardi@arcetri.astro.it],
;**                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;**                    -enhanced and adapted to version 1.0.
;**                   : for version 2.0,
;**                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;**                    -enhanced and adapted to version 2.0 (CAOS).
;**                   : for version 3.0,
;**                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;**                    -enhanced for version 3.0 of CAOS (package-oriented).
;**                   : for version 4.0 of the whole 'system CAOS',
;**                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;**                    -no more use of the COMMON variable "calibration" and
;**                     the tag "calib" (structure "info").
;**                    -no more use of the initialisation file and, obviously,
;**                     the calibration file.
;**                   : for version 5.0 of the Soft.Pack.CAOS,
;**                         version 3.0 of the Soft.Pack.AIRY,
;**                         version 1.0 of the Soft.Pack.MAOS,
;**                     Marcel Carbillet (LUAN) [marcel.carbillet@unice.fr]:
;**                    -no more crash provoked when controlling the Soft.Pack.
;**                     version for existing parameter files - just a warning.
;**                     (seems to be nothing but this is a definitive improvement
;**                     for users freedom ;-) !!)
;**
;-
;
;**
;** here begins the main module's code
;**
;
function xxx, inp_yyy_t,   $ ; 1st input structure  ;** DELETE if no input
              inp_zzz_t,   $ ; 2nd input structure  ;** DELETE if no 2nd input
              out_aaa_t,   $ ; 1st output structure ;** DELETE if no output
              out_bbb_t,   $ ; 2nd output structure ;** DELETE if no 2nd output
              par,         $ ; XXX parameters structure
                             ;**
                             ;** the INIT structure contains the quantities to
                             ;** compute just once in a simulation made of several
                             ;** iterations.
                             ;**
              INIT=init,   $ ; XXX initialization structure
                             ;**
                             ;** DELETE the following line if no time
                             ;** integration/delay management is required for
                             ;** the module XXX.
                             ;**
              TIME=time      ; time managing structure

; CAOS global common block
common caos_block, tot_iter, this_iter

; error code initialisation
error = !caos_error.ok

; module's actions
if (this_iter eq 0) then begin
   ; initialisation section
   error = xxx_init(inp_yyy_t, $ ;** DELETE argument if no input
                    inp_zzz_t, $ ;** DELETE if no 2nd input
                    out_aaa_t, $ ;** DELETE if no output
                    out_bbb_t, $ ;** DELETE if no 2nd output
                    par,       $
                    INIT=init  )
endif else begin
   ; run section
   ;**
   ;** DELETE this section (untill "END OF THE RUN SECTION") if no time
   ;** integration and/or delay is managed by the module, and substitute
   ;** it with:
   ;**     error = xxx_prog(inp_yyy_t, $ ;** DELETE argument if no input
   ;**                      inp_zzz_t, $ ;** DELETE if no 2nd input
   ;**                      out_aaa_t, $ ;** DELETE if no output
   ;**                      out_bbb_t, $ ;** DELETE if no 2nd output
   ;**                      par,       $
   ;**                      INIT=init  )
   ;**

   if (par.time_integ eq 1) and (par.time_delay eq 0) then begin
      ; neither integration nor delay over several iterations.
      error = xxx_prog(inp_yyy_t, $ ;** DELETE argument if no input
                       inp_zzz_t, $ ;** DELETE if no 2nd input
                       out_aaa_t, $ ;** DELETE if no output
                       out_bbb_t, $ ;** DELETE if no 2nd output
                       par,       $
                       INIT=init  )
      return, error
   endif

   if ((size(time))[0] eq 0) then begin
   ; time integration and/or delay over several iterations.
   ; the structure time is undefined or a scalar: start a new integration
   ; (or/and delay) loop.

      ; computes the new output data to integrate.
      error = xxx_prog(inp_yyy_t, $ ;** DELETE argument if no input
                       inp_zzz_t, $ ;** DELETE if no 2nd input
                       out_aaa_t, $ ;** DELETE if no output
                       out_bbb_t, $ ;** DELETE if no 2nd output
                       par,       $
                       INIT=init  )

      ; check data status
      if (out_aaa_t.data_status ne !caos_data.valid) or   $
         (out_bbb_t.data_status ne !caos_data.valid) then $
         message, 'invalid output data status to integrate and/or to delay.'

      ; structure time
      time = $
         {   $
         total_loops: par.time_integ  $
                     +par.time_delay, $ ; total nb of loops
         iter       : 0,              $ ; iteration nb initialisation
         output     : out_aaa_t,      $ ; output to be integrated
         output1    : out_bbb_t       $ ; second output (if present)
         }                              ;** DELETE output1 tag if xxx has
                                        ;** no 2nd output
   endif

   time.iter = time.iter + 1                ; iteration number update

   if ( (time.iter gt 1) and (time.iter le par.time_integ) ) then begin
   ; time integration
      error = xxx_prog(inp_yyy_t, $ ;** DELETE argumentif no input
                       inp_zzz_t, $ ;** DELETE if no 2nd input
                       out_aaa_t, $ ;** DELETE if no output
                       out_bbb_t, $ ;** DELETE if no 2nd output
                       par,       $
                       INIT=init  )

      ; check data status
      if (out_aaa_t.data_status ne !caos_data.valid) or   $
         (out_bbb_t.data_status ne !caos_data.valid) then $
         message, 'invalid output data status to integrate and/or to delay.'

      ;**
      ;** the following two TAGS integrated are only examples...
      ;** please note that if two outputs need to be integrated, they
      ;** cannot be integrated following two different integration times.
      ;**
      ; integrate the TAG "image" of the output "out_aaa_t"
      time.output.image = time.output.image + out_aaa_t.image
      ; integrate the TAG "psf" of the output "out_bbb_t"
      time.output1.psf = time.output1.psf + out_bbb_t.psf
   endif                                     ; else do nothing

   if (time.iter eq time.total_loops) then begin

      ; update the output when the integration is performed
      out_aaa_t = time.output
      ;**
      ;** DELETE next line if xxx has no 2nd output
      ;**
      ; update the 2nd output when the integration is performed
      out_bbb_t = time.output1

      ; re-initialise time structure
      time = 0

   endif else begin
      ; return wait-for-the-next output(s)
      out_aaa_t.data_status = !caos_data.wait
      ;**
      ;** DELETE next line if xxx has no 2nd output
      ;**
      out_bbb_t.data_status = !caos_data.wait

   endelse

;**
;** END OF THE RUN SECTION
;**
endelse

; back to calling program.
return, error
end
