; $Id: img_prog.pro,v 7.0 2016/05/27 marcel.carbillet $
;+
; NAME:
;    img_prog
;
; PURPOSE:
;    img_prog represents the scientific algorithm for the 
;    IMaGer (IMG) module.
; 
;    (see img.pro's header --or file caos_help.html-- for details
;     about the module itself). 
; 
; CATEGORY:
;    scientific program
;
; CALLING SEQUENCE:
;    error = img_prog(inp_wfp_t, out_img_t1, out_img_t2, par, INIT= init)
;
; INPUTS/OUTPUTS/KEYWORDS/ETC.:
;    see module help for a detailed description. 
;
; MODIFICATION HISTORY:
;    program written: Jan 2000,
;                     Bruno Femenia (OAA) [bfemenia@arcetri.astro.it].
;    modifications  : february 2000,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -PSF is no more at unit volume, but with the right number
;                     of photons.
;                   : May 2000,
;                     B. Femenia (OAA) [bfemenia@arcetri.astro.it]:
;                    -Debugged (unexpectedly previous modifications were done 
;                     on a buggy outdated version). Fixed.
;                   : september 2000,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -wait status problem fixed.
;                   : january 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -!caos_error.dmi.* variables eliminated for
;                     compliance with the CAOS Software System, version 4.0.
;                   : March 2003,
;                     B. Femenia (GTC) [bfemenia@ll.iac.es]
;                    -merging versions at OAA and GTC.
;                   : september 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -now can accept also a complex field as input (in
;                     addition to the standard case of a wave-front).
;                   : may 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;-
;
FUNCTION img_prog, inp_wfp_t    , $  ; input wavefront
                   out_img_t1   , $  ; output IMG-type: BOTTOM BOX => psf
                   out_img_t2   , $  ; output IMG-type: TOP    BOX => image
                   par          , $  ; parameters from img_gui
                   INIT= init

error = !caos_error.ok                   ;Init error code: no error as default

;1/ CHECKS: - standard checks performed within img_init.pro
;========== - here checking inp_wfp_t.data_status is always valid.

ds1 = inp_wfp_t.data_status

CASE ds1 OF
   !caos_data.not_valid: MESSAGE,'Input wfp_t cannot be not_valid.' 
   !caos_data.wait     : begin
                            out_img_t1.data_status = !caos_data.wait
                            out_img_t2.data_status = !caos_data.wait
                            return, error
                         end
   !caos_data.valid    : ds1= ds1
   ELSE                : MESSAGE,'Input wfp_t has an invalid data status.'
ENDCASE

;2/ OBTAINING FIELD DISTRIBUTION ON FOCAL PLANE OF IMG DETECTOR.
;===============================================================

dummy = (SIZE(inp_wfp_t.map))[0]
nx    = N_ELEMENTS(inp_wfp_t.pupil[*,0])         ;Linear Nb pxls in WF
np    = par.npixel                               ;Linear Nb pxls in detector

CASE dummy OF
   0: n_layers=1                                 ;Point-like source
   2: n_layers=1                                 ;Extended 2D source
   3: BEGIN
      n_layers=N_ELEMENTS(inp_wfp_t.map[0,0,*])  ;3D source => Nb of NLS layers
      dummy1  =TOTAL(inp_wfp_t.map)
      IF (dummy1 EQ 0.) THEN BEGIN
         MESSAGE,'3D source empty, possibly out of fiel'+ $
                                                 ;For debugging purposes
                 'd of view. CHECK!', CONT=NOT(!caos_debug)
         error = !caos_error.module_error
         RETURN,error
      ENDIF
      pointing= DBLARR(2)                        ;Stores pointing position for
                                                 ; detector: detector assumed to
                                                 ; point towards object to be
                                                 ; imaged.
      dummy1= DBLARR(2,n_layers)
      FOR i = 0,n_layers-1 DO dummy1[1,i]=   $   ;Weights chosen so that most
        1./SQRT(TOTAL(inp_wfp_t.map[*,*,i]))     ;luminous layer weights more!!
                                                 ;See STDEV_WEIGHTED to
                                                 ;understand 
                                                 ;the weights.
      dummy1[0,*]= inp_wfp_t.coord[3,*]
      pointing[0]= STDEV_WEIGHTED(dummy1,dummy2) ;POINTING{0]= x-coordinate
      pointing[0]= dummy2                        ;   of "center" of spot
      
      dummy1[0,*]= inp_wfp_t.coord[4,*]
      pointing[1]= STDEV_WEIGHTED(dummy1,dummy2) ;POINTING{1]= y-coordinate
      pointing[1]= dummy2                        ;   of "center" of spot

   END
    
   ELSE: BEGIN
      MESSAGE,'check inp_wfp_t.map. It should be point-'+ $
                                                 ;FOR DEBUGGING PURPOSES
        'like, 2D or 3D!!', CONT= NOT(!caos_debug)
      error = !caos_error.module_error
      RETURN, error
   END

ENDCASE 

ul  = COMPLEXARR(init.dim,init.dim)              ;To contain phasor
psf = FLTARR(init.dim,init.dim)                  ;To contain PSF
IF (dummy NE 0) THEN image = FLTARR(init.dim,init.dim)
                                                 ;To contain PSF@map
                                                 ;(@=convolution)

rd1= par.foc_dist                                ;RD1=Dist Entrance Pupil to IMG
                                                 ;conjug plane
IF (n_layers EQ 1) THEN rd2= inp_wfp_t.dist_z $  ;RD2=Dist Entrance Pupil to source/NLS-layer
ELSE rd2= TRANSPOSE(inp_wfp_t.coord[2,*])

FOR i=0,n_layers-1 DO  BEGIN

   dummy1= init.r2_array*(1./rd2[i]-1./rd1)/2.   ;Defocus aberration

   ; check what the input is exactly: is it a complex field ? or is it a wave-front ?
   ;
                                                   ;;;;;;;;;;;;;;;;;;;;;;;;;;
   if (size(inp_wfp_t.screen))[3] eq 9 then begin  ; input is a complex field
                                                   ;;;;;;;;;;;;;;;;;;;;;;;;;;;

      ul[0:nx-1,0:nx-1] = inp_wfp_t.screen*inp_wfp_t.pupil*exp(init.wedge*init.scale)
;;      Etot = total (abs(inp_wfp_t.screen)^2.*inp_wfp_t.pupil)/total(inp_wfp_t.pupil)

      psf0 = FLOAT((ABS(FFT(ul,-1)))^2)
                                                   ;;;;;;;;;;;;;;;;;;;;;;;
   endif else begin                                ; input is a wave-front
                                                   ;;;;;;;;;;;;;;;;;;;;;;;

      ul[0:nx-1,0:nx-1]= inp_wfp_t.pupil*EXP((dummy1+inp_wfp_t.screen+init.wedge)*init.scale)
                                                 ;Phasor*Pupil.
                                                 ;Pupil function contains 
                                                 ; atm. aberrations+DEFOCUS+half-pixel
                                                 ; tilt(wedge) to properly sample image.
      psf0 = FLOAT((ABS(FFT(ul,-1)))^2)
      psf0 = SHIFT(psf0,init.dim/2,init.dim/2)   ;PSF for THIS LAYER.
                                                 ;It's a (dim,dim) array.

   endelse

   psf0 = psf0/TOTAL(psf0)                       ;PSF conserves energy.

   psf  = psf + psf0                             ;"Cumulative" PSF.

   IF (dummy NE 0) THEN BEGIN

      ;i/ Defining axes on TYPE of input map
      ;________________________________________

      nmap  = N_ELEMENTS(inp_wfp_t.map[0,*,0])

      IF (dummy EQ 2) THEN BEGIN
         row1  = nmap/2-1
         row2  = nmap/2
         col1  = nmap/2-1
         col2  = nmap/2
         dummy2= (FINDGEN(nmap)-(nmap-1.)/2.)
      ENDIF ELSE BEGIN
         row1  = nmap/2-1
         row2  = nmap/2+1
         col1  = nmap/2-1
         col2  = nmap/2+1
         dummy2= (FINDGEN(nmap)-nmap/2)
      ENDELSE

      ;ii/ Finding indexes where map will be interp at PSF resolution
      ;_______________________________________________________________

      off=DBLARR(2)                             ;These lines are required
      IF (dummy EQ 3) THEN BEGIN                ;to "center" each layer of         
         off[0]=ATAN(inp_wfp_t.coord[3,i] - pointing[0], $
                                                ;3D. With these lines, weighted
                     inp_wfp_t.coord[2,i])      ;center of 3D spot is at center
         off[1]=ATAN(inp_wfp_t.coord[4,i] - pointing[1], $
                                                ;of FOV of IMG detector so that
                                                ;any   
                     inp_wfp_t.coord[2,i])      ;displacement of image is only
                                                ;due 
      ENDIF                                     ;to atmospheric turbulence!!      
      axisMapx=dummy2*inp_wfp_t.map_scale+off[0];x-axis for MAP matrix in [rads]
      axisMapx = axisMapx/4.848e-6              ;Now in [arcsec]
      
      axisMapy=dummy2*inp_wfp_t.map_scale+off[1];y-axis for MAP matrix in [rads]
      axisMapy = axisMapy/4.848e-6              ;Now in [arcsec]

      index_x= (init.axisPsf-axisMapx[0])/ $    ;"Indexes" of axisPsf within
        (axisMapx[1]-axisMapx[0])               ;  axisMapx array.

      index_y= (init.axisPsf-axisMapy[0])/ $    ;"Indexes" of axisPsf within
        (axisMapy[1]-axisMapy[0])               ;  axisMapy array.

      r1= WHERE(index_x GT 0 AND index_x LE nmap-1, c1)
                                                ;Finding idx of pts along x &  
      r2= WHERE(index_y GT 0 AND index_y LE nmap-1, c2)
                                                ;y where map will be interp'd. 

      IF (c1 EQ 0) OR (c2 EQ 0) THEN BEGIN
         MESSAGE,'Extend source out of field of view?? '+ $
                                                ;For debugging purposes
           'CHECK!',CONT = NOT(!caos_debug)
         error = !caos_error.module_error
         RETURN,error
      ENDIF

      ;iii/ Bilinear interpolation and axis of resulting box
      ;_____________________________________________________       

      dummy1= INTERPOLATE(inp_wfp_t.map[*,*,i],index_x[r1], index_y[r2],/GRID)
      ;Bilinear interp. of source map to points where PSF is sampled.
 
      axis_xInterp= (axisMapx[1]-axisMapx[0])*index_x[r1]+$
                                                ;x-axis of box resulting
        axisMapx[0]                             ;   from interpolation

      axis_yInterp= (axisMapx[1]-axisMapx[0])*index_y[r2]+$
                                                ;y-axis of box resulting
        axisMapy[0]                             ;   from interpolation
                  
      ;iv/ Inserting interpolation into appropriate 2D array
      ;_____________________________________________________
        
      col1 = CLOSEST(axis_xInterp[0],init.axispsf)
                                                ;col2= col index lower left
      col2 = col1 + N_ELEMENTS(dummy1[*,0])-1   ;  corner of box within MAP  
                                              
      row1 = CLOSEST(FLOAT(axis_yInterp[0]),init.axispsf)
                                                ;row2= row index lower left
      row2 = row1+N_ELEMENTS(dummy1[0,*])-1     ;  corner of box within MAP  

      map                     = FLTARR(init.dim,init.dim)
      map[col1:col2,row1:row2]= dummy1

      image= image + CONVOLVE_EVEN(map,psf0,/REDIM,/ORIGIN)

   ENDIF ELSE image = psf

ENDFOR

psf   = psf/TOTAL(psf)                          ;PSF conserves energy.
image = image/TOTAL(image)                      ;Later normalized with
                                                ;  number of photons.

;3/ GOING TO RESOLUTION IMPOSED BY PIXEL SIZE OF CCD / QUAD-CELL
;===============================================================

b1=init.b1
b2=init.b2

IF (init.rebin_fac GT 1) THEN BEGIN

   new_dim         = (b2-b1+1)/init.rebin_fac
   dummy           = psf[b1:b2,b1:b2]
   out_img_t1.image= init.rebin_fac^2*REBIN(dummy,new_dim,new_dim)
                                                 ;Rebining PSF and conserving
                                                 ;energy
   out_img_t1.psf  = 1B                          ;Marking this IS a PSF

   dummy           = image[b1:b2,b1:b2]
   out_img_t2.image= init.rebin_fac^2*REBIN(dummy,new_dim,new_dim)
                                                 ;Rebining IMAGE and conserving
                                                 ;energy
   out_img_t2.psf  = 0B                          ;Marking this IS NOT a PSF
   
ENDIF ELSE BEGIN

   out_img_t1.image= psf[  b1:b2,b1:b2]          ;Extracting image & PSF
                                                 ;portions  
   out_img_t2.image= image[b1:b2,b1:b2]          ;  of FOV sampled by IMG
                                                 ;  detector.
ENDELSE

;;                                                ;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;if (size(inp_wfp_t.screen))[3] eq 9 then begin  ; input is a complex field
;;                                                ; => outputs * Etot
;;                                                ;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;   out_img_t1.image = out_img_t1.image*Etot
;;   out_img_t2.image = out_img_t2.image*Etot
;;
;;endif

RETURN, error
END