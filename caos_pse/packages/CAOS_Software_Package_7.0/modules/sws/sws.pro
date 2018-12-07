; $Id: sws.pro,v 7.0 2016/05/19 marcel.carbillet $
;+
; NAME:
;    sws
;
; ROUTINE'S PURPOSE:
;
;    SWS manages the simulation for the Shack-Hartmann Wavefront Sensor
;    (SWS) module, that is:
;       1-calls the module's initialisation routine sws_init at the first
;         iteration of the simulation (or calibration) project
;       2-calls the module's program routine sws_prog otherwise, managing
;         at the same time the possible time integration/delay.
;
; MODULE'S PURPOSE:
;
;       SWS executes the simulation of the Shack-Hartmann Wavefront sensor,
;       adopting a similar procedure as the IMG module to enlarge the phase
;       screen in the incoming inp_wfp_t so that the SWS CCD pixel is n times (n
;       integer) the size of the pixel size due to FFTing the phase screen. By
;       doing this we won't need any interpolation process but a fater and
;       accurate standard REBIN call. Another improvement concerns the use of
;       the much faster FFTW routines over the standard IDL routines. On the
;       other hand this module is kept as its minimum so it lacks all the
;       advanced features in the original CAOS SHS module. The geometry is
;       always assumed to be of Fried type.
;
; CATEGORY:
;       main module's routine
;
; CALLING SEQUENCE:
;       error = sws(inp_wfp_t, out_mim_t, par, INIT=init, TIME= time)
;
; OUTPUT:
;       error: long scalar (error code). see !caos_error var in caos_init.pro.
;
; INPUTS:
;       inp_wfp_t: structure of type wfp_t.tructure containing the
;                  wavefront to be analysed and several other needed
;                  information (pupil, optical path perturbations, ...)
;
;       par      : parameters structure from sws_gui. Contains the tags
;                  associated to the management of program as well as the tags
;                  containing the parameters for the scientific calculations.
;                  (See GUI DESCRIPTION section below for further details)
;
; INCLUDED OUTPUTS:
;       out_mim_t: structure of type mim_t. Structure containing the SHWFS image
;                  on the CCD and the sensor geometry structure.
;
; KEYWORD PARAMETERS:
;       INIT     : named variable undefined or containing a scalar when SWS is
;                  called for the first time. As output the named variable will
;                  contain a structure of the initialization data. For the
;                  following calls of SWS, the keyword INIT has to be set to
;                  the structure returned by the first call. 
;
;       TIME     : time-evolution structure.
;
; OPTIONAL OUTPUTS:
;       None.
;
; COMMON BLOCKS:
;       common caos_block, tot_iter, this_iter
;
;       tot_iter   : int scalar. Total number of iteration during the
;                    simulation run.
;       this_iter  : int scalar. Number of the current iteration. It is
;                    defined only while status eq !caos_status.run.
;                    (this_iter >= 1).
;
; SIDE EFFECTS:
;       None.
;
; RESTRICTIONS:
;       -Only Fried geometry is allowed in initial version.
;       -Unlike SHS module, no advanced parameters are allowed.
;       -Program assumes that each subaperture samples a square WF with an integer number of
;        sampling WF pixels. If this is not the case report error and exit.
;
; ROUTINE MODIFICATION HISTORY:
;       program written: Dec 2003,
;                        B. Femenia (GTC) [bfemenia@ll.iac.es].
;       modifications  : december 2003,
;                        Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                       -use of variable "calibration" eliminited from version 4.0
;                        of the whole system CAOS.
;                      : may 2016,
;                        Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                       -adapted to Soft. Pack. CAOS 7.0.
;
; MODULE MODIFICATION HISTORY:
;       module written : Dec 2003,
;                        B. Femenia (GTC) [bfemenia@ll.iac.es].
;       modifications  : for CAOS 4.0+ compatibility,
;                        Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                       -no more use of the common variable "calibration" and
;                        the tag "calib" (structure "info") from version 4.0 of
;                        the whole system CAOS.
;                      : for version 7.0,
;                        Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                       -adapted.
;-
;
FUNCTION sws, inp_wfp_t, $                                  ; input wavefront
              out_mim_t, $                                  ; output MIM-type
              par,       $                                  ; parameters from sws_gui
              INIT=init, $                                  ; initialisation structure
              TIME=time                                     ; time managing structure

   COMMON caos_block, tot_iter, this_iter

   error = !caos_error.ok                                   ; Init error code: no error as default

                                                            ;===============
   IF (this_iter EQ 0) THEN BEGIN                           ; INITIALIZATION 
                                                            ;===============
      error = sws_init(inp_wfp_t, out_mim_t, par, INIT=init)

                                                            ;===============
   ENDIF ELSE BEGIN                                         ; NORMAL RUNNING
                                                            ;===============
      ;;Neither integration nor delay.
      ;;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      IF (par.time_integ EQ 1) AND (par.time_delay EQ 0) THEN BEGIN

         error = sws_prog(inp_wfp_t, out_mim_t, par, INIT=init)
         dummy = out_mim_t.image
         
         ;;Adding noises to OUT_MIM_T as required by user
         ;;==============================================
         IF par.noise[0] THEN BEGIN                         ;PHOTON NOISE
            r1 = WHERE((dummy GT 0) AND (dummy LT 1e8), c1) ;------------
            seed_pn = init.seed_pn
            FOR i=0l, c1-1l DO dummy[r1[i]] =             $ ;For values higher than 1e8, should one
              RANDOMN(seed_pn, /DOUB, POISSON=dummy[r1[i]]) ; worry about the SNR?   
            init.seed_pn = seed_pn                          ;Updating seed for photon noise.
         ENDIF


         IF (par.noise[2]*par.dark_noise GT 0) THEN BEGIN   ;DARK-CURRENT NOISE
            seed_dark = init.seed_dark                      ;------------------
            pmean = par.dark_noise*inp_wfp_t.delta_t
            np    = N_ELEMENTS(dummy[0, *])
            dummy = dummy+RANDOMN(seed_dark, np, np,  $
                                  POISSON=pmean, /DOUBLE)
            init.seed_dark = seed_dark                      ;Updating seed.
         ENDIF


         IF (par.noise[1]*par.read_noise GT 0) THEN BEGIN   ;READ-OUT NOISE
            seed_ron = init.seed_ron                        ;--------------
            np    = N_ELEMENTS(dummy[0, *])
            dummy = FLOOR(RANDOMN(seed_ron, np, np, /DOUB)*$
                          par.read_noise) + dummy
            idx  = WHERE(dummy LT 0, c)                     ;Truncating: pixels < 0
            IF (c GT 0) THEN dummy[idx] = 0.                ;  unread by detector
            init.seed_ron = seed_ron                        ;Updating seed.
         ENDIF


         dummy = dummy*init.subap_mask                      ;To avoid pixels outside of valid supapertures

         IF par.threshold GT 0. THEN BEGIN                  ;APPLYING THRESHOLD 
            r1 = WHERE(dummy LT init.threshold, c1)         ;==================
            IF (c1 GT 0) THEN dummy[r1] = 0
         ENDIF 

         IF TOTAL(ABS(par.noise) GT 0) THEN  $
           out_mim_t.image = FLOOR(dummy)    $              ;Quantification of the image if NOISE is considered.
         ELSE                                $
           out_mim_t.image = dummy
         out_mim_t.data_status = !caos_data.valid           ;OUTPUT is VALID

         RETURN, error

      ENDIF 


      ;;Time integration and/or delay is required: 
      ;;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      IF ((SIZE(time))[0] EQ 0) THEN BEGIN                  ;Time undefined or scalar means
         error = sws_prog(inp_wfp_t, out_mim_t, par, $      ;   that a new loop starts now.
                          INIT=init)
                                                            
         time = {total_loops: par.time_integ+par.time_delay, $ ;Total nb of loops
                 iter:        0,                             $ ;Iteration nb init.
                 output:      out_mim_t                      $ ; output to be integrated
                }
      ENDIF 

      time.iter = time.iter + 1                             ;Iteration number update


      IF ((time.iter GT 1) AND                               $ ;Time integration
          (time.iter LE par.time_integ)) THEN BEGIN                     
         error = sws_prog(inp_wfp_t, out_mim_t, par, INIT=init)
         time.output.image = time.output.image+out_mim_t.image ;Summing up SWS images.
      ENDIF   


      IF (time.iter EQ time.total_loops) THEN BEGIN

         out_mim_t = time.output                            ;Rendering integrated output.
         time  = 0                                          ;Re-init. time struc
         dummy = out_mim_t.image 


         ;;Adding noises to OUT_MIM_T as required by user
         ;;==============================================
         IF par.noise[0] THEN BEGIN                         ;PHOTON NOISE
            r1 = WHERE((dummy GT 0) AND (dummy LT 1e8), c1) ;------------
            seed_pn = init.seed_pn
            FOR i=0l, c1-1l DO dummy[r1[i]] =             $ ;For values higher than 1e8, should one
              RANDOMN(seed_pn, /DOUB, POISSON=dummy[r1[i]]) ; worry about the SNR?   
            init.seed_pn = seed_pn                          ;Updating seed for photon noise.
         ENDIF


         IF (par.noise[2]*par.dark_noise GT 0) THEN BEGIN   ;DARK-CURRENT NOISE
            seed_dark = init.seed_dark                      ;------------------
            np    = N_ELEMENTS(dummy[0, *])
            pmean = par.dark_noise*inp_wfp_t.delta_t* $
                    par.time_integ
            dummy = dummy+RANDOMN(seed_dark, np, np,  $
                                  POISSON=pmean, /DOUBLE)
            init.seed_dark = seed_dark                      ;Updating seed.
         ENDIF


         IF (par.noise[1]*par.read_noise GT 0) THEN BEGIN   ;READ-OUT NOISE
            seed_ron = init.seed_ron                        ;--------------
            np    = N_ELEMENTS(dummy[0, *])
            dummy = FLOOR(RANDOMN(seed_ron, np, np, /DOUB)*$
                          par.read_noise) + dummy
            idx  = WHERE(dummy LT 0, c)                     ;Truncating: pixels < 0
            IF (c GT 0) THEN dummy[idx] = 0.                ;  unread by detector
            init.seed_ron = seed_ron                        ;Updating seed.
         ENDIF


         dummy = dummy*init.subap_mask                      ;To avoid pixels outside of valid supapertures

         IF par.threshold GT 0. THEN BEGIN                  ;APPLYING THRESHOLD 
            r1 = WHERE(dummy LT init.threshold, c1)         ;==================
            IF (c1 GT 0) THEN dummy[r1] = 0
         ENDIF 

         IF TOTAL(ABS(par.noise) GT 0) THEN  $
           out_mim_t.image = FLOOR(dummy)    $              ;Quantification of the image if NOISE is considered.
         ELSE                                $
           out_mim_t.image = dummy
         out_mim_t.data_status = !caos_data.valid           ;OUTPUT is VALID

         RETURN, error

      ENDIF ELSE BEGIN 

         out_mim_t.data_status = !caos_data.wait            ;Return a wait-for-the-next output

      ENDELSE

   ENDELSE

   RETURN, error                                            ;Back to calling program.

END