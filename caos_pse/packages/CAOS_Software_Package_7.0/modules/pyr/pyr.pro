; $Id: pyr.pro,v 7.0 2016/05/19 marcel.carbillet $
;+
; NAME:
;    pyr
;
; ROUTINE'S PURPOSE:
;    pyr manages the simulation for the "Pyramid WFS"
;    (pyr) module, that is:
;       1-calls the module's initialisation routine pyr_init at the first
;         iteration of the simulation project
;       2-calls the module's program routine pyr_prog otherwise, managing
;         at the same time the possible time integration/delay.
;
; MODULE'S PURPOSE:
;    During the initialization (first loop), PYR computes the sensor
;    geometry and many other useful parameters for the computation of 
;    the sensor image. Up to now only the squared geometry issupported.
;    The main parameters to adjust are the linear number of sub-pupils
;    over the diameter, the mini. illumination ratio and the
;    modulation  parameters (best is circular with ~8steps per modulation
;    angle expressed in lambda/D: if +- 2 lambda/D --> 16 points).
;
;    The 4 quadrant images of the sensor are computed by Fourier
;    optics with two possible algorithms.
;    First the complex amplitude in the image plane is computed, then
;    it is multiplied by either the transmission mask function
;    equivalent to pyramid facets or by a pyramidic phasor (phase
;    mask); The latter is faster and permits to take into account
;    interferences between the 4 quadrants.
;    Finally, a reverse Fourier Transform permits to compute the
;    image on the sensor in the pupil plane. In case of modulation, 
;    the complex amplitude in image plane is shifted in a few steps,
;    describing a square (ols version) or circular figure  of the
;    image. For each step, the same computation is done and the
;    squared moduli of the final image in pupil plane at each step
;    are summed up.
;
;    Rem:  Extended source and laser not yet supported.   
;
;
; CATEGORY:
;       main module's routine
;
; CALLING SEQUENCE:
;       error = pyr(inp_wfp_t, out_mim_t1, out_img_t2, par, INIT=init, TIME=time)
;
; OUTPUT:
;       error: long scalar (error code). see !caos_error var in caos_init.pro.
;
; INPUTS:
;       inp_wfp_t: structure of type wfp_t.tructure containing the
;                  wavefront to be analysed and several other needed
;                  information (pupil, optical path perturbations, ...)
;
;       par      : parameters structure from pyr_gui with tags associated to 
;                  the management of program and tags containing relevant
;                  parameters for the scientific calculations.
;                  (See GUI DESCRIPTION section below for further details)
;
; INCLUDED OUTPUTS:
;       out_mim_t1: structure of type mim_t. Structure containing the 4 pupil image
;                   on the CCD and the sensor geometry structure.
;
;	out_img_t2: structure of type img_t. Structure containing the image
;                   plane on top of pyramid, integrated during dynamic
;		    modulation.
;                  
; KEYWORD PARAMETERS:
;       INIT     : named variable undefined or containing a scalar when pyr is
;                  called for the first time. As output the named variable will
;                  contain a structure of the initialization data. For the
;                  following calls of pyr, the keyword INIT has to be set to
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
;       None.
;
; GUI DESCRIPTION:
;       see pyr help.
;
; ROUTINE MODIFICATION HISTORY:
;       program written: june 2001,
;                        Christophe Verinaud (OAA) [verinaud@arcetri.astro.it].
;
;       modifications  : october 2002,
;                        Christophe Verinaud (OAA) [verinaud@arcetri.astro.it]:
;                       -phase mask alternative added.
;                      : january 2003,
;                        Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                       -use of variable "calibration" eliminited for version 4.0
;                        of the whole CAOS System.
;                       -second output from mim_t to img_t.
;                      : may 2016,
;                        Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                       -adapted to Soft. Pack. CAOS 7.0.
;
; MODULE MODIFICATION HISTORY:
;       module written : Christophe Verinaud (OAA) [verinaud@arcetri.astro.it].
;
;       modifications  : october 2002,
;                        Christophe Verinaud (OAA) [verinaud@arcetri.astro.it]:
;                       -phase mask alternative added.
;                      : january 2003,
;                        Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                       -no more use of the common variable "calibration" and
;                        the tag "calib" (structure "info") for version 4.0 of
;                        the whole CAOS Software System.
;                       -second output from mim_t to img_t.
;                      : february 2003,
;                        Christophe Verinaud (ESO) [cverinau@eso.org]:
;                       - bug correction for dark noise.
;                      : october 2004,
;                        Marcel Carbillet (LUAN) [marcel.carbillet@unice.fr]:
;                       - stupid one-value-vector IDL6+ bug corrected (in pyrccd_circ.pro: px->px[0]).
;                      : may 2016,
;                        Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                       -adapted to Soft. Pack. CAOS 7.0.
;
;-
;
FUNCTION pyr, inp_wfp_t , $  ; input wavefront
              out_mim_t1, $  ; output multiple image type
	      out_img_t2, $  ; output image type
	      par       , $  ; parameters from pyr_gui
              INIT=init , $  ; initialisation structure
              TIME=time      ; time managing structure

COMMON caos_block, tot_iter, this_iter
COMMON noise_seed, seed_pn,seed_ron,seed_dk

error = !caos_error.ok                ; Init error code: no error as default

info = pyr_info()

IF (this_iter EQ 0) THEN BEGIN                              ; INITIALIZATION 
                                                            ;===============
   error = pyr_init(inp_wfp_t, out_mim_t1, out_img_t2, par, INIT=init)

ENDIF ELSE BEGIN                                            ; NORMAL RUNNING
                                                            ;===============
   ;Neither integration nor delay.
   ;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   IF (par.time_integ EQ 1) AND (par.time_delay EQ 0) THEN BEGIN

      error = pyr_prog(inp_wfp_t, out_mim_t1, out_img_t2, par, INIT=init)

      if par.background eq 1B then out_mim_t1.image=out_mim_t1.image+init.skynph
      ;Adding sky background to image.
   
      for kk=0,par.n_pyr-1 do begin
      ; ONLY ONE STAR HERE n_pyr=1 (compatibility with MAOS)
      ; Adding noises to OUT_MIM_T as required by user

         dummy = out_mim_t1.image[*,*,kk]
      
         IF init.noise THEN BEGIN 
    
            np= N_ELEMENTS(dummy[0,*])
                                                                ;PHOTON NOISE
            r1= WHERE((dummy(*,*) GT 0.) AND (dummy LT 1e8),c1) ;============
     
            FOR i=0l,c1-1l DO BEGIN
               dummy[r1[i]]= RANDOMN(seed_pn,POISSON=dummy[r1[i]],/DOUBLE)
            ENDFOR
            ;dummy=poidev(dummy)
 
            IF (init.dark GT 0) THEN BEGIN            ;DARK-CURRENT NOISE
               pmean = init.dark                      ;==================
               dummy = dummy+RANDOMN(seed_dk,np,np,POISSON=pmean)
            ENDIF 

            IF (init.rnoise GT 0) THEN BEGIN          ;READ-OUT NOISE
               dummy= dummy + $                       ;==============
                      FLOOR(RANDOMN(seed_ron,np,np)*init.rnoise)
               idx  = WHERE(dummy LT 0, c)            ;Truncating: pixels < 0
               IF (c GT 0) THEN dummy[idx]= 0.        ;unread by detector
            ENDIF

            IF init.threshold GT 0. THEN BEGIN        ;APPLYING THRESHOLD 
               r1 = WHERE(dummy LT init.threshold,c1) ;==================
               IF (c1 GT 0) THEN dummy[r1] = 0
            ENDIF 

            out_mim_t1.image[*,*,kk] = FLOOR(dummy)   ; quantification of the image

         ENDIF 

      endfor

      out_mim_t1.data_status = !caos_data.valid     ;OUTPUT is VALID

   ENDIF 

   ;Time integration and/or delay is required: 
   ;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   IF ((SIZE(time))[0] EQ 0) THEN BEGIN         ; Time undefined or scalar means
      error= pyr_prog(inp_wfp_t, out_mim_t1, out_img_t2, par, INIT=init)
                                                ; that a new loop starts now.

      time = $
         {   $
         total_loops: par.time_integ+par.time_delay, $ ; Total nb of loops
         iter       : 0                            , $ ; Iteration nb init.
         output     : out_mim_t1                      $ ; output to be integrated
         }

   ENDIF 

   time.iter = time.iter + 1                      ; iteration number update

   IF ((time.iter GT 1) AND                     $ ; Time integration
       (time.iter LE par.time_integ)) THEN BEGIN                     

      error= pyr_prog(inp_wfp_t,out_mim_t1,out_img_t2, par,INIT=init)


      time.output.image = time.output.image+out_mim_t1.image
                                                  ; Summing up pyr images.

   ENDIF   


   IF (time.iter EQ time.total_loops) THEN BEGIN

      out_mim_t1= time.output                      ; Rendering integrated output.
      time     = 0                                 ; re-initialise time struc.

      if par.background eq 1B then out_mim_t1.image $
                                   = out_mim_t1.image + init.skynph*par.time_integ
                                                   ; Adding sky backgr. to image

      for kk=0,par.n_pyr -1 do begin

         dummy = out_mim_t1.image[*,*,kk]

         ;Adding noises to OUT_MIM_T as required by user
         ;==============================================

         IF init.noise THEN BEGIN 
         
            np= N_ELEMENTS(dummy[0,*])
                                                  ; PHOTON NOISE
                                                  ; ============
            r1= WHERE((dummy GT 0.) AND (dummy LT 1e8),c1)
        
	    FOR i=0l,c1-1l DO BEGIN 
               dummy[r1[i]]= RANDOMN(seed_pn,POISSON=dummy[r1[i]]) 
            ENDFOR 

            IF (init.dark GT 0) THEN BEGIN        ; DARK-CURRENT NOISE
               pmean = init.dark*par.time_integ   ; ==================
                    
               dummy = dummy+RANDOMN(seed_dk,np,np,POISSON=pmean)
            ENDIF 

            IF (init.rnoise GT 0) THEN BEGIN         ; READ-OUT NOISE
               dummy= dummy + $                      ; ==============
                 FLOOR(RANDOMN(seed_ron,np,np)*init.rnoise)
               idx  = WHERE(dummy LT 0, c)           ; Truncating: pixels < 0
               IF (c GT 0) THEN dummy[idx]= 0.       ; unread by detector
            ENDIF

            IF init.threshold GT 0. THEN BEGIN        ; APPLYING THRESHOLD 
               r1 = WHERE(dummy LT init.threshold,c1) ; ==================
               IF (c1 GT 0) THEN dummy[r1] = 0
            ENDIF 

            out_mim_t1.image[*,*,kk] = FLOOR(dummy)  ; quantification

         ENDIF
      endfor

      out_mim_t1.data_status = !caos_data.valid     ; OUTPUT is VALID

   ENDIF ELSE BEGIN 

   out_mim_t1.data_status = !caos_data.wait         ; return a
                                                    ; wait-for-the-next output
   ENDELSE

ENDELSE

return, error
END