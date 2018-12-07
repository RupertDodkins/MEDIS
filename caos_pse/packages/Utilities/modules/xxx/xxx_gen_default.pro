;**
;*******************************************************************************
;** HOW TO USE THIS TEMPLATE:                                                  *
;**                                                                            *
;** 0-READ THE WHOLE TEMPLATE ONCE !!                                          *
;** 1-CHANGE EVERYWHERE THE STRINGS "XXX" IN THE CHOSEN 3-CHAR MODULE NAME     *
;** 2-ADAPT THE TEMPLATE ONTO THE NEW MODULE CASE FOLLOWING THE EXAMPLES,      *
;**   RECOMENDATIONS, AND ADVICES THROUGH THE TEMPLATE                         *
;** 3-DELETE ALL THE LINES OF CODE BEGINNING WITH ";**"                        *
;**                                                                            *
;*******************************************************************************
;**
;**
;** here is the routine identification
;**
; $Id: xxx_gen_default.pro,v 5.1 2005/07/04 marcel.carbillet $
;**
;** put the right version, date, and main author name of last update in the line
;** here above following the formats:
;** -n.m for the version (n=software release version, m=module update version).
;** -YYYY/MM/DD for the date (YYYY=year, MM=month, DD=day).
;** -first_name/last_name for the (last update) main author name.
;**
;
;**
;** here begins the header of the routine
;**
;+
; NAME:
;    xxx_gen_default
;
; PURPOSE:
;    xxx_gen_default generates the default parameter structure for the XXX
;    module and save it in the rigth location.
;    (see xxx.pro's header --or file xyz_help.html-- for details about the
;     module itself).
;
; CATEGORY:
;    module's utility routine
;
; CALLING SEQUENCE:
;    xxx_gen_default
; 
; ROUTINE MODIFICATION HISTORY:
;    routine written: date,
;                     author (institute) [email].
;    modifications  : date,
;                     author (institute) [email]:
;                    -description of modification.
;                   : date,
;                     author (institute) [email]:
;                    -description of modification.
;
;**
;** TEMPLATE MODIFICATION HISTORY:
;**     program written: may 1998,
;**                      Armando Riccardi (OAA) [riccardi@arcetri.astro.it].
;**     modifications  : november 1998, Armando Riccardi:
;**                     -init_file and init_save tags added in the par
;**                     structure, in order to allow saving and restoring
;**                     of the initialization structure.
;**                    : february 1999,
;**                      Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;**                     -a few modifications for version 1.0.
;**                    : november 1999, Marcel Carbillet (OAA):
;**                     -enhanced and adapted to version 2.0 (CAOS).
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
;**                    -"mod_type"->"mod_name".
;**
;-
;
;**
;** here actually begins the routine code
;**
pro xxx_gen_default

; obtain module infos
info = xxx_info()

; generate module description structure
module = gen_def_module(info.mod_name, info.ver)

;**
;** the tags named time_integ and time_delay are mandatory for the
;** modules that allows to integrate and/or delay the output (modules
;** containing analog-to-digital device like CCD detectors, for
;** instance). these modules MUST have (xxx_info()).time eq 1B.
;**
;** DELETE the lines where time_integ and time_delay are defined if
;** time integration and delay are not allowed.
;**

time_integ = fix(1)>1           ; short integer, scalar and ge 1.
                                ; number of iterations for which the output
                                ; is integrated (summed).
                                ;**
                                ;** 1 means no integration: the input
                                ;** is processed and the output is
                                ;** returned. n gt 1 means that a
                                ;** valid output is returned every n
                                ;** iterations of the main loop and is
                                ;** given by the sum of n outputs
                                ;**

time_delay = fix(0)>0           ; short integer, scalar and ge 0.
                                ; the number of iteration for which the output
                                ; is delayed.
                                ;**
                                ;** 0 means no delay.
                                ;**

;**
;** the other following tags (choice, choice0_param, choice1_param, and
;** choice1_type in this example) are module-dependent tags and the names
;** are stated by the developer of the module.
;**
; parameter structure
par = $
   {  $
   xxx,                          $ ; structure named xxx
   module       : module,        $ ; module description structure
   ;**
   ;** DELETE the two following lines if no time integration/delay management
   ;** is required
   ;**
   time_integ   : time_integ,    $ ; integration time [base-time unit]
   time_delay   : time_delay,    $ ; delay time [base-time unit]
   ;**
   ;** the following tags follow the examples described in detail within the
   ;** GUI template xxx_gui.pro. these are, then, only examples...
   ;**
   choice       : 1,             $ ;** chosen choice (0 or 1)
   choice0_param: 12,            $ ;** parameter for choice 0 (integer)
   choice1_param: .5,            $ ;** first parameter for choice 1
                                   ;** (float between 0 and 1)
   choice1_type :  3             $ ;** second parameter for choice 1 (integer)
   }

; save the default parameters structure in the file def_file
save, par, FILENAME=info.def_file

;back to calling program
end
