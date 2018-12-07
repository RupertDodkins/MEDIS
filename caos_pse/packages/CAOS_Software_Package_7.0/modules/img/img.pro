; $Id: img.pro,v 7.0 2016/04/21 marcel.carbillet $
;+
; NAME:
;    img 
;
; ROUTINE'S PURPOSE:
;    img manages the simulation for the IMaGe (IMG) module,
;    that is:
;       1-calls the module's initialisation routine img_init at the first
;         iteration of the simulation project
;       2-calls the module's program routine img_prog otherwise, managing
;         at the same time the possible time integration/delay.
;
; MODULE'S PURPOSE:
;
;    IMG executes the simulation of the image formation process on a image
;    sensor, be it a standard CCD or a Quad-cell usually employed for
;    Tip-Tilt sensing. Thus, IMG is basically a copy of the TTS module with
;    some features extracted from the PSF module, both existing in v 1.0 (LAOS)
;    of this software. For the sake of clarity the purpose of the PSF and TTS
;    modules are reproduced here:
;
;       TTS MODULE
;       ----------
;       Usually a Tip Tilt Sensor system assumes a detector with a square
;       array of pixels and placed at the focal plane of a collecting
;       lens. This lens receives a collimated beam which previously has
;       gone through a turbulent atmosphere and a telescope (this being
;       simulated with the GPR module). The presence of an overall Tip-Tilt
;       manifests itself as a displacement of the observed intensity
;       diffraction pattern with respect to the case where no Tip-Tilt is
;       present (in this case the image appears to be centred at the
;       optical axis of the system). A measurement of the position of the
;       image (carried out by TCE module) is strongly related to the
;       overall Tip-Tilt across the telescope pupil. 
;
;          The purpose of the TTS module is to simulate the process of
;       imaging through a focusing lens on an intensity detector. Such
;       simulation is carried out in the framework of Fraunhofer
;       diffraction theory involving an FFT operation. The algorithm also
;       takes into account the change of resolution involved when binning
;       the intensity pattern with a resolution imposed by pixelization of
;       Input wavefront to the resolution imposed by pixel size of detector
;       as chosen by user. Such a binning process is performed with
;       rebin_ccd and involves no interpolation unlike standard IDL routine
;       CONGRID. The output is Shack-Hartman intensity type structure
;       containing the intensity on the detector and information on the
;       geometry of the detector and method.
;
;          Concerning the detector characteristics the user provides, via
;       the Graphic User Interface (GUI), the number of pixels on intensity
;       detector, their angular size when placed on focal plane of focusing
;       lens, the possible delay time required by detector as well as the
;       integration time when a measurement is performed (both times in
;       units of atmosphere evolution time) and the wavelength at which TTS
;       operates. The user must also provide which kind of detector is used
;       (Quad-cell detector or CCD) and has the choice of performing
;       simulation with or without effects of photon noise (understood as
;       Poisson noise and independent between different pixels), dark-current
;       noise (also modeled as a Poisson noise) and read-out noise (as a
;       truncated Gaussian process). In case a Quad-cell detector is used, the
;       user must specify via the GUI the Gaussian optical fiber to be used in 
;       the calibration to be carried out by TCE.
;
;       PSF MODULE
;       ----------
;       psf computes the PSF of the system or the image of the object 
;       through it. This program manages the initialization and calibration
;       steps as well as the time behaviour, and then calls the appropriate
;       programs (psf_init and psf_prog).
;
; CATEGORY:
;    main module's routine
;
; CALLING SEQUENCE:
;    error = img(inp_wfp_t, out_img_t1, out_img_t2, par, INIT=init, TIME= time)
;
; OUTPUT:
;    error: long scalar (error code). see !caos_error var in caos_init.pro.
;
; INPUTS:
;    inp_wfp_t: structure of type wfp_t.tructure containing the
;               wavefront to be analysed and several other needed
;               information (pupil, optical path perturbations, ...)
;
;    par      : parameters structure from img_gui. In addition to the tags
;               associated to the management of program, the tags containing
;               the parameters for the scientific calculations are:
;
;                 par.time_integ: No. of iterations to integrate
;                 par.time_delay: No. of iterations to delay
;                 par.foc_dist  : Distance at which IMG focalises [m]
;                 par.npixel    : Nb. detector pixels along x- & y-axes
;                 par.pxsize    : Detector pixel size [arcsec]
;                 par.qeff      : Quantum efficiency
;                 par.lambda    : Mean working wavelength [m]
;                 par.width     : Bandwidth [m]
;                 par.noise     : 0/1=no/yes for Photon, read-out, dark 
;                                 current noises.
;                 par.read_noise: rms for Read-out noise. [e- rms]
;                 par.dark_noise: mean for Dark current noise [e-/s]
;                 par.backgradd : 0/1=no/yes for sky background adding
;                 par.increase  : Factor by which dimensions of arrays
;                                 are enlarged to increase sampling of PSF
;
; INCLUDED OUTPUTS:
;    out_img_t2: structure of type img_t. Structure containing the IMAGE on
;                dedicated sensor plus info on CCD used (#pixels, pixel size, 
;                covered field, ...)
;
;    out_img_t1: IDEM, but the image it stores is the PSF.
;
; KEYWORD PARAMETERS:
;    INIT: named variable undefined or containing a scalar when IMG is
;          called for the first time. As output the named variable will
;          contain a structure of the initialization data. For the following
;          calls of IMG, the keyword INIT has to be set to the structure
;          returned by the first call. 
;
;    TIME: time-evolution structure.
;
; COMMON BLOCKS:
;    common caos_block, tot_iter, this_iter
;
;    tot_iter   : int scalar. Total number of iteration during the
;                 simulation run.
;    this_iter  : int scalar. Number of the current iteration. It is
;                 defined only while status eq !caos_status.run.
;                 (this_iter >= 1).
;
; SIDE EFFECTS:
;    None.
;
; RESTRICTIONS:
;    None.
;
; CALLED NON-IDL FUNCTIONS:
;    None.
;
; EXAMPLE:
;    Write here an example!
;
; ROUTINE MODIFICATION HISTORY:
;    program written: Oct 1998, (TTS module)
;                     B. Femenia (OAA) [bfemenia@arcetri.astro.it]
;
;                     Nov 1998, (PSF module)
;                     F. Delplancke (ESO) [fdelplan@eso.org].
;
;                     Jan 2000, (IMG module) 
;                     B. Femenia (OAA) [bfemenia@arcetri.astro.it]
;
;    modifications  : february 2000,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -the PSF output is rendered as the IMAGE output now (in
;                     terms of number of photons and noise considerations).
;                    -quantum efficiency + noise problems fixed.
;                   : September 2001
;                     B. Femenia (OAA) [bfemenia@arcetri.astro.it]
;                    -IDL 5.4 handles SEEDs in calls to RANDOM such that now
;                     the initial seed has to be fed. Now having control
;                     over seeds to generate noise.
;                   : September 2002,
;                     B. Femenia (GTC) [bfemenia@ll.iac.es]
;                    -controlling noise seeds via COMMON blocks will result
;                     ambiguous in project with two or more IMG modules.
;                   : october 2002,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -adding sky background noise to the PSF and the image is now
;                     an option only (=> added tag/condition par.backgradd).
;                   : january 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -use of variable "calibration" eliminited for version 4.0
;                     of the whole CAOS Software System.
;                   : March 2003,
;                     B. Femenia (GTC) [bfemenia@ll.iac.es]
;                    -merging versions at OAA and GTC.
;                   : may 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;
; MODULE MODIFICATION HISTORY:
;    module written : Oct 1998, (TTS module)
;                     B. Femenia (OAA) [bfemenia@arcetri.astro.it]
;                   : Nov 1998, (PSF module)
;                     F. Delplancke (ESO) [fdelplan@eso.org].
;                   : Jan 2000, (IMG module)
;                     B. Femenia (OAA) [bfemenia@arcetri.astro.it]
;
;    modifications  : for version 4.0,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -no more use of the common variable "calibration" and
;                     the tag "calib" (structure "info") for version 4.0 of
;                     the whole CAOS Software System.
;                   : for version 4.0 as well,
;                     B. Femenia (GTC) [bfemenia@ll.iac.es]:
;                    -merging versions at OAA and GTC.
;                   : for version 7.0,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted.
;-
;
FUNCTION img, inp_wfp_t    , $  ; input wavefront
              out_img_t1   , $  ; output IMG-type: BOTTOM BOX => psf
              out_img_t2   , $  ; output IMG-type: TOP    BOX => image
              par          , $  ; parameters from img_gui
              TIME= time   , $  ; time managing structure
              INIT= init        ; initialisation structure

COMMON caos_block, tot_iter, this_iter

error = !caos_error.ok                    ; Init error code: no error as default

IF (this_iter EQ 0) THEN BEGIN            ; INITIALIZATION 
                                          ;===============
   error = img_init(inp_wfp_t, out_img_t1, out_img_t2, par, INIT=init)
   
ENDIF ELSE BEGIN                          ; NORMAL RUNNING
                                          ;===============
   ;Neither integration nor delay.
   ;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   IF (par.time_integ EQ 1) AND (par.time_delay EQ 0) THEN BEGIN

      error = img_prog(inp_wfp_t, out_img_t1, out_img_t2, par, INIT= init)

      dummy = out_img_t2.image*init.n_phot
      dumdu = out_img_t1.image*init.n_phot

      ; adding sky background to both the outputs (PSF and image) IF option selected
      ;=============================================================================
      if par.backgradd then begin
         dummy = dummy + init.bg_sky
         dumdu = dumdu + init.bg_sky
      endif

      ;Adding noises to OUT_IMG_T2 (and now also out_img_t1) as required by user
      ;=========================================================================
      np = LONG(par.npixel)

      IF par.noise[0] THEN BEGIN                            ;PHOTON NOISE
         r1 = WHERE((dummy GT 0.) AND (dummy LT 1e8),c1)    ;------------
         seed_pn = init.seed_pn

         FOR i=0l,c1-1l DO                              $   ;For values higher than 1e8
           dummy[r1[i]]=                                $   ; ... should one worry about     
           RANDOMN(seed_pn,POISSON=dummy[r1[i]],/DOUBLE)    ; the SNR?? 
                            
         r1 = WHERE((dumdu GT 0.) AND (dumdu LT 1E8),c1)
         FOR i=0l,c1-1l DO dumdu[r1[i]] =               $   ; On the other hand
           RANDOMN(seed_pn,POISSON=dumdu[r1[i]],/DOUBLE)    ; RANDOMN(seed,POI=1e9) breaks down!!

         init.seed_pn = seed_pn                             ;Updating seed.
      ENDIF                                

      IF (par.noise[2]*par.dark_noise GT 0) THEN BEGIN      ;DARK-CURRENT NOISE
         seed_dark = init.seed_dark                         ;------------------
         
         pmean = par.dark_noise*inp_wfp_t.delta_t
         dummy = dummy+RANDOMN(seed_dark,np,np,POISSON=pmean,/DOUBLE)
         dumdu = dumdu+RANDOMN(seed_dark,np,np,POISSON=pmean,/DOUBLE)

         init.seed_dark = seed_dark                         ;Updating seed.
      ENDIF

      IF (par.noise[1]*par.read_noise GT 0) THEN BEGIN      ;READ-OUT NOISE
         seed_ron = init.seed_ron                           ;--------------

         dummy= dummy+FLOOR(RANDOMN(seed_ron,np,np,/DOUBLE)*par.read_noise)
         idx  = WHERE(dummy LT 0, c)                        ;Truncating: pixels < 0
         IF (c GT 0) THEN dummy[idx]= 0.                    ;  unread by detector

         dumdu= dumdu+FLOOR(RANDOMN(seed_ron,np,np,/DOUBLE)*par.read_noise)
         idx  = WHERE(dumdu LT 0, c)                        ;Truncating: pixels < 0
         IF (c GT 0) THEN dumdu[idx]= 0.                    ;  unread by detector

         init.seed_ron = seed_ron                           ;Updating seed.
      ENDIF

      out_img_t2.image       = dummy       ;Image in Nb. photons
      out_img_t2.data_status = !caos_data.valid
                                           ;OUTPUT is VALID

      out_img_t1.image       = dumdu       ;PSF in Nb. photons
      out_img_t1.data_status = !caos_data.valid
                                           ;OUTPUT is VALID

      RETURN, error                        ;and ERROR code.

   ENDIF

   ;Time integration and/or delay is required: 
   ;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   IF ((SIZE(time))[0] EQ 0) THEN BEGIN   ;Time undefined or scalar means
      error = img_prog(inp_wfp_t, out_img_t1, out_img_t2, $
                                          ;that a new loop is to start now.
                       par, INIT=init)      

      time = {total_loops: par.time_integ+par.time_delay, $ ;Total nb of loops
              iter       : 0                            , $ ;Iteration nb init.
              output1    : out_img_t1                   , $ ;Output image
              output2    : out_img_t2                     $ ;Output psf
             }
   ENDIF

   time.iter = time.iter + 1                                ;Iteration nb update

   IF ((time.iter GT 1) AND                               $ ;Time integration
       (time.iter LE par.time_integ)) THEN BEGIN                     
      error= img_prog(inp_wfp_t, out_img_t1, out_img_t2, par, INIT=init)
      time.output1.image= (time.output1.image +           $ ;Summing up PSF's
                           out_img_t1.image)
      time.output2.image= (time.output2.image +           $ ;Summing up IMAGEs
                           out_img_t2.image)
   ENDIF

   IF (time.iter EQ time.total_loops) THEN BEGIN

      out_img_t1 = time.output1                             ;Rendering PSF.
      out_img_t2 = time.output2                             ;Rendering IMAGE.

      time  = 0                                             ;Re-init. time struc
      dummy = out_img_t2.image*init.n_phot
      dumdu = out_img_t1.image*init.n_phot

      ; adding sky background to both the outputs (PSF and image) IF option selected
      ;=============================================================================
      if par.backgradd then begin
         dummy = dummy + init.bg_sky*par.time_integ
         dumdu = dumdu + init.bg_sky*par.time_integ
      endif

      ;Adding noises to OUT_IMG_T2 (and now out_img_t1 also) as required by user
      ;=========================================================================
      np = LONG(par.npixel)

      IF par.noise[0] THEN BEGIN                            ;PHOTON NOISE
         r1 = WHERE((dummy GT 0.) AND (dummy LT 1e8), c1)   ;------------
         seed_pn = init.seed_pn

         FOR i=0l,c1-1l DO dummy[r1[i]] =                 $      
           RANDOMN(seed_pn,POISSON=dummy[r1[i]],/DOUBLE)

         r1 = WHERE((dumdu GT 0.) AND (dumdu LT 1E8),c1)
         FOR i=0l,c1-1l DO dumdu[r1[i]] =                 $      
           RANDOMN(seed_pn,POISSON=dumdu[r1[i]],/DOUBLE)

         init.seed_pn = seed_pn                             ;Updating seed.
      ENDIF


      IF (par.noise[2]*par.dark_noise GT 0) THEN BEGIN      ;DARK-CURRENT NOISE
         seed_dark = init.seed_dark                         ;------------------

         pmean = par.dark_noise*inp_wfp_t.delta_t*par.time_integ
         dummy = dummy+RANDOMN(seed_dark,np,np,POISSON=pmean,/DOUBLE)
         dumdu = dumdu+RANDOMN(seed_dark,np,np,POISSON=pmean,/DOUBLE)

         init.seed_dark = seed_dark                         ;Updating seed.
      ENDIF


      IF (par.noise[1]*par.read_noise GT 0) THEN BEGIN      ;READ-OUT NOISE
         seed_ron = init.seed_ron                           ;--------------

         dummy= dummy+FLOOR(RANDOMN(seed_ron,np,np,/DOUBLE)*par.read_noise)
         idx  = WHERE(dummy LT 0, c)                        ;Truncating pixels<0
         IF (c GT 0) THEN dummy[idx]= 0.                    ; unread by detector

         dumdu= dumdu+FLOOR(RANDOMN(seed_ron,np,np,/DOUBLE)*par.read_noise)
         idx  = WHERE(dumdu LT 0, c)                        ;Truncating pixels<0
         IF (c GT 0) THEN dumdu[idx]= 0.                    ; unread by detector

         init.seed_ron = seed_ron                           ;Updating seed.
      ENDIF

      out_img_t2.image       = dummy                        ;Image in Nb. phot.
      out_img_t2.data_status = !caos_data.valid             ;OUTPUT is VALID

      out_img_t1.image       = dumdu                        ;PSF in Nb. phot.
      out_img_t1.data_status = !caos_data.valid             ;OUTPUT is VALID

      RETURN, error                                         ;RETURNING ERROR

   ENDIF ELSE BEGIN
      out_img_t1.data_status= !caos_data.wait               ; return a wait-for
                                                            ;-the-next output
      out_img_t2.data_status= !caos_data.wait               ; return a wait-for
                                                            ;-the-next output
   ENDELSE 

ENDELSE 

RETURN, error                                               ; back to calling
END