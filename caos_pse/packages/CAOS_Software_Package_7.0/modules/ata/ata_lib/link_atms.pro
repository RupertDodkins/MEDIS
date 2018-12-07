; $Id: link_atms.pro,v 7.0 2016/05/19 marcel.carbillet $
;+
; NAME:
;       link_atms
;
; PURPOSE:
;       Given two inputs of type atm_t gives the order in which phase screens
;       must be ordered to form a single atm_t output containing the "sum" of
;       the two inputs
;
; CATEGORY:
;       ...
;
; CALLING SEQUENCE:
;       ...
;
; INPUTS/OUTPUTS/KEYWORDS/ETC.:
;       see module help for a detailed description. 
;
; MODIFICATION HISTORY:
;       program written: March 2001,
;                        Bruno Femenia (OAA)  [bfemenia@arcetri.astro.it]
;                      : april 2016,
;                        Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                       -adapted to Soft. Pack. CAOS 7.0.
;-
;
PRO link_atms, inp_atm_t1, inp_atm_t2, par, atm1_to_atm, atm2_to_atm, alt_layers, dir_layers, nlayers

   nel_x1 = N_ELEMENTS(inp_atm_t1.screen[*,0,0])
   nel_y1 = N_ELEMENTS(inp_atm_t1.screen[0,*,0])
   nel_x2 = N_ELEMENTS(inp_atm_t2.screen[*,0,0])
   nel_y2 = N_ELEMENTS(inp_atm_t2.screen[0,*,0])

   ;;Checking compatibility of both inputs.
   ;;======================================
   IF (nel_x1 NE nel_x2) THEN $
     MESSAGE,'Input wavefronts not sampled with same number of pixels along x-dimension'

   IF (nel_y1 NE nel_y2) THEN $
     MESSAGE,'Input wavefronts not sampled with same number of pixels along y-dimension'

   IF inp_atm_t1.scale NE inp_atm_t2.scale THEN $
     MESSAGE,'Wavefronts in inputs have different spatial sampling'

   IF (inp_atm_t1.correction NE 0) AND (inp_atm_t2.correction NE 0) THEN $
     MESSAGE,'Both input atmospheres are flagged as CORRECTION!!'

   IF inp_atm_t1.delta_t NE inp_atm_t2.delta_t THEN $
     MESSAGE,'Atmospheres have different delta_t. Feature not yet supported!!'


   ;; Layers in different inp_atm_t are assumed to be at same height if differ by more threshold
   ;;-------------------------------------------------------------------------------------------

   threshold= par.threshold                                 ;Meters for layers to differ in order to be 
   nlay_1   = N_ELEMENTS(inp_atm_t1.screen[0,0,*])          ;  considered at different altitudes.
   nlay_2   = N_ELEMENTS(inp_atm_t2.screen[0,0,*])
   nlay_c   = 0l                                            ;Number of common layers between both inputs

   alt_atm1 = inp_atm_t1.alt[0:nlay_1-1]
   alt_atm2 = inp_atm_t2.alt[0:nlay_2-1]

   dir_atm1 = inp_atm_t1.dir[0:nlay_1-1]
   dir_atm2 = inp_atm_t2.dir[0:nlay_2-1]

   FOR i=0,nlay_1-1 DO BEGIN 
      r1     = WHERE(ABS(alt_atm1[i]-alt_atm2) LE threshold, count)
      nlay_c = nlay_c+count
      IF (count GT 0) THEN BEGIN 
         PRINT,''
         PRINT,'WARNING:'
         PRINT,'--------'
         PRINT,' layer '+STRCOMPRESS(r1,/REMO)+' of 2nd Input at'          + $
           ' altitude'+STRCOMPRESS(alt_atm2[r1])+' [m] is now associated'  + $
           ' to layer'+STRCOMPRESS(i)+' of 1st input at altitude '         + $
           STRCOMPRESS(alt_atm1[i])+' [m] and directions are set to the '  + $
           'same ones as in 1st input, ie from '+STRCOMPRESS(dir_atm2[r1]) + $
           ' [rads] to '+STRCOMPRESS(dir_atm1[i])
         alt_atm2[r1] = alt_atm1[i]
         dir_atm2[r1] = dir_atm1[i]
      ENDIF 
   ENDFOR 

   dummy1 = TRANSPOSE([[alt_atm1,alt_atm2],[dir_atm1,dir_atm2]])  ;; First col: altitudes, Second col: directions
   remove_repeated, dummy1, dummy2

   alt_layers = REFORM(dummy2[0,*])
   dir_layers = REFORM(dummy2[1,*])

   atm1_to_atm = INTARR(nlay_1)
   FOR i=0,nlay_1-1 DO BEGIN 
      idx = CLOSEST(alt_atm1[i],alt_layers)
      atm1_to_atm[i] = idx
   ENDFOR 

   atm2_to_atm = INTARR(nlay_2)
   FOR i=0,nlay_2-1 DO BEGIN 
      idx = CLOSEST(alt_atm2[i],alt_layers)
      atm2_to_atm[i] = idx
   ENDFOR 

   nlayers = nlay_1+nlay_2-nlay_c                           ;Final number of layers
   IF (N_ELEMENTS(alt_layers) NE nlayers) THEN      $
     MESSAGE,'Error with Nb of layers!! Check!!'

   return

END 