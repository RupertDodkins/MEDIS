; $Id: sws_prog.pro,v 7.0 2016/05/19 marcel.carbillet $
;+
; NAME:
;    sws_prog
;
; PURPOSE:
;    sws_prog represents the scientific algorithm for the 
;    Shack-Hartmann Wavefront Sensor (SWS) module.
; 
;    (see sws.pro's header --or file caos_help.html-- for details
;     about the module itself). 
; 
; CATEGORY:
;    scientific program
;
; CALLING SEQUENCE:
;    error = sws_init(inp_wfp_t, $ ; wfp_t input structure
;                     out_mim_t, $ ; mim_t output structure 
;                     par      , $ ; parameters structure
;                     INIT=init  ) ; initialisation data structure
;
;
; INPUTS/OUTPUTS/KEYWORDS/ETC.: 
;    see sws.pro's help for a detailed description. 
;
; ROUTINE MODIFICATION HISTORY:
;    program written: Dec 2003,
;                     B. Femenia (GTC) [bfemenia@ll.iac.es]
;   modifications   : may 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;-
;
FUNCTION sws_prog, inp_wfp_t, $  ;; input wavefront
                   out_mim_t, $  ;; SH spots image
                   par,       $  ;; parameters structure from sws_gui
                   INIT = init   ;; initialisation data structure

   error = !caos_error.ok                                   ;Init error code: no error as default


   ;;1/BILINEAR INTERPOLATION OF WF IF NEEDED
   ;;========================================
   IF init.interpol THEN BEGIN 
      wf = INTERPOLATE(inp_wfp_t.screen, init.AxisWF_1,  $
                       init.AxisWF_1, /GRID) 
      pupil = init.pupil
   ENDIF ELSE BEGIN 
     wf    = inp_wfp_t.screen
     pupil = inp_wfp_t.pupil
  ENDELSE



   ;;2/ USEFUL QUANTITIES
   ;;====================
   src_nbD = (SIZE(inp_wfp_t.map))[0]                       ;Number of Dimensions of source map.
   nx      = N_ELEMENTS(wf[*, 0])/par.nsubap                ;Nb WF pixels on a side of a square subaperture.
   np      = par.nsubap*par.npixel                          ;Linear number of SWS pixels along pupil diameter.



   ;;3/ CHECKS: - standard checks performed within img_init.pro
   ;;========== - here checking inp_wfp_t.data_status is always valid.
   ;;            -current version does not support 3D LGS.

   ds1 = inp_wfp_t.data_status
   CASE ds1 OF
      !caos_data.not_valid: MESSAGE, 'Input wfp_t cannot be not_valid.' 
      !caos_data.wait     : MESSAGE, 'Input wfp_t data cannot be wait.'
      !caos_data.valid    : ds1 = ds1
      ELSE                : MESSAGE, 'Input wfp_t has an invalid data status.'
   ENDCASE


   CASE src_nbD OF

      0: n_layers = 1                                       ;Point-like source

      2: n_layers = 1                                       ;Extended 2D source

      3: BEGIN
         MESSAGE, '3D sources handle not yet operative', /INFO
         error = !caos_error.sws.NOT_yet_implemented
         RETURN, error

         ;;-----------------------------------------------------------------------------------
         ;;3D LGS with Shack-Hartmann requires generating an array of 2D sources, each of them
         ;;the projection of the 3d LGS as seen by each of the active subapertures: TO BE DONE
         ;;-----------------------------------------------------------------------------------

         n_layers = N_ELEMENTS(inp_wfp_t.map[0, 0, *])      ;3D source => Nb of NLS layers
         dummy1  = TOTAL(inp_wfp_t.map)
         IF (dummy1 EQ 0.) THEN BEGIN
            MESSAGE, '3D source empty, possibly out of'+ $  ;For debugging purposes
                     ' FoV. CHECK!', CONT=NOT(!caos_debug)
            error = !caos_error.sws.map_out_fov
            RETURN, error
         ENDIF
         pointing = DBLARR(2)                               ;Stores pointing position for
                                                            ; detector: detector assumed to
                                                            ; point towards object to be
                                                            ; imaged.
         dummy1 = DBLARR(2, n_layers)
         FOR i = 0, n_layers-1 DO dummy1[1, i] =   $        ;Weights chosen so that most
           1./SQRT(TOTAL(inp_wfp_t.map[*, *, i]))           ;luminous layer weights more!!
                                                            ;See STDEV_WEIGHTED to
                                                            ;understand 
                                                            ;the weights.
         dummy1[0, *] = inp_wfp_t.coord[3, *]
         pointing[0] = STDEV_WEIGHTED(dummy1, dummy2)       ;POINTING[0]= x-coordinate
         pointing[0] = dummy2                               ;   of "center" of spot
         
         dummy1[0, *] = inp_wfp_t.coord[4, *]
         pointing[1] = STDEV_WEIGHTED(dummy1, dummy2)       ;POINTING[1]= y-coordinate
         pointing[1] = dummy2                               ;   of "center" of spot

      END
      
      ELSE: BEGIN
         MESSAGE, 'check inp_wfp_t.map. It should be '+ $   ;FOR DEBUGGING PURPOSES
                  '1D, 2D or 3D!!', CONT=NOT(!caos_debug)
         error = !caos_error.img.invalid_map_dim
         RETURN, error
      END

   ENDCASE 



   ;;4/ LOOPING OVER SUBAPERTURES TO GET MULTIIMAGE
   ;;==============================================

   rd1 = par.foc_dist                                       ;RD1=Dist Entrance Pupil to plane where CCD is conjugated.
   IF (n_layers EQ 1) THEN rd2 = inp_wfp_t.dist_z   $       ;RD2=Dist Entrance Pupil to source/NLS-layer.
   ELSE rd2 = TRANSPOSE(inp_wfp_t.coord[2, *])

   dummy     = par.nsubap*par.npixel
   multi_img = FLTARR(dummy, dummy)


   rd2_rd1 = DOUBLE(1./rd2-1./rd1)/2.                       ;Amplitude of defocus term
   FOR isa = 0, init.nsub_ap-1 DO BEGIN                     ;LOOP ON THE ACTIVE SUBAPERTURES: isa=subaperture index.

      ;;Generating subaperture binary pupil function
      ;;--------------------------------------------
      irow = init.sub_ap[isa]  /   par.nsubap               ;Row    index of this VALID subaperture.
      icol = init.sub_ap[isa] MOD par.nsubap                ;Column index of this VALID subaperture.
      
      ix1 = icol*nx   &    iy1 = irow*nx
      ix2 = ix1+nx-1  &    iy2 = iy1+nx-1

      sapupil = pupil[ix1:ix2, iy1:iy2]                     ;This VALID subaperture BINARY pupil function.
      phase   = wf[ix1:ix2, iy1:iy2] +                    $ ;Atmospheric turbulence phase screen on THIS subaperture.
                init.r2_array[ix1:ix2, iy1:iy2]*rd2_rd1 + $ ;Defocus aberration function on THIS subaperture.
                init.wedge                                  ;Half-pixel wedge to properly sample PSF.

      ul  = DCOMPLEXARR(init.dim, init.dim)                 ;Phasor for this subaperture
      ul[0:nx-1, 0:nx-1] = sapupil*EXP(phase*init.scale)    ;Phasor: using subaperture pupil function!!

      psf = ABS(FFT(ul, -1, /DOUBLE))^2
      psf = SHIFT(psf, init.dim/2, init.dim/2)              ;PSF. It's a [dim,dim] array.
      psf = psf/TOTAL(psf)                                  ;PSF conserves energy.
      
      IF (src_nbD EQ 1) THEN                              $
        image = CONVOLVE_EVEN(init.map, psf, /ORI, /DOUB) $
      ELSE image = psf

      image = image/TOTAL(image)*                         $ ;Normalizing image to number of photons collected
              (init.fluxsubap*init.illumin[icol, irow])     ;by this subaperture.
      
      image = image*init.FoV_PSF                            ;Simulating Field Stop in optical system.


      ;;Going to CCD/QUAD-CELL resolution
      ;;---------------------------------
      b1 = init.b1
      b2 = init.b2
      IF (init.rebin_fac GT 1) THEN BEGIN
         nd    = (b2-b1+1)/init.rebin_fac                   ;Check against par.npixel
         dummy = REBIN(image[b1:b2, b1:b2], nd, nd)         ;Rebining IMAGE by subaperture.
         dummy = init.rebin_fac^2*dummy                     ;Energy conservation.
      ENDIF ELSE dummy = image[b1:b2, b1:b2]

      ix1 = icol*par.npixel &  ix2 = ix1+par.npixel-1
      iy1 = irow*par.npixel &  iy2 = iy1+par.npixel-1


      multi_img[ix1:ix2, iy1:iy2] = multi_img[ix1:ix2, iy1:iy2] + dummy + $           ;;Adding sky background if ANY
        init.FoV_CCD*init.illumin[icol, irow]*init.bg_sky*(TOTAL(ABS(par.noise)) < 1) ;;KIND OF NOISE is considered.

   ENDFOR 

   out_mim_t.image = multi_img


   RETURN, error

END