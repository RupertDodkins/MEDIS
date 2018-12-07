; $Id: launch_dis.pro,v 7.0 2016/04/21 marcel.carbillet$
; +
; NAME:
;    launch_dis.pro
;
; PURPOSE:
;    display management for module DIS of package "Utilities"
;
; MODIFICATION HISTORY:
;    program written: april 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr],
;                     Andrea La Camera (DIBRIS) [andrea.lacamera@unige.it]:
;                    -global merging of launch_dsp of module DSP (from Soft.
;                     Pack. AIRY 6.1 ) and launch_disp of module DIS (from Soft.
;                     Pack. CAOS 5.2) for new CAOS Problem-Solving Env. 7.0.
;    modifications  : date,
;                     author (institute) [email@address]:
;                    -description of modification.
;       
; -
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;function ask_question, par, init, mod_n
;error = !caos_error.ok
;if init.win_wait_confirm then begin
;    if par.title_info EQ " " then                                      $
;      title = 'displaying '+init.type+' data from DIS module # '+mod_n $
;    else title = par.title_info
;    dummy = dialog_message('shall I stop again at the next iteration ?' $
;                           ,/QUEST $
;                           ,TITLE=title)
;   if strlowcase(dummy) eq 'no' then begin
;       init.win_wait_confirm=0B
;       dummy = dialog_message('Quit the data display operation?' $
;                              ,/QUEST $
;                              ,TITLE=title)
;      if strlowcase(dummy) eq 'yes' then begin
;          init.win_quit = 1B
;          if init.win_index GT 0 then wdelete, init.win_index
;      endif else begin
;          init.win_quit = 0B
;      endelse
;  endif
;endif
;return, error
;end
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
function launch_dis, inp, par, init
  
  error = !caos_error.ok
  
  mod_n = strtrim(par.module.n_module,2)
  
if init.win_quit EQ 0B then begin
   
   if !D.NAME eq "WIN" then cs=0.7 else cs=1.0
   
   case init.type of
      
;;;;;;;;;;;;;;;
; atm_t display
      'atm_t': begin
         wset, init.win_index
         nl = n_elements(inp.alt)
         res = size(inp.screen)
         nx = res(1)
         ny = res(2)
         arr2disp = inp.screen*1E9 ; converts the layers into nm
         if nl GT 1 then arr2disp = reform(transpose(arr2disp,[0,2,1]),nx*nl,ny)
         image_show2, arr2disp, /SH, /AS, DIG=1              $
                      , /XS, XR=[-.5,.5]*nx*nl*inp.scale       $
                      , /YS, YR=[-.5, .5]*ny*inp.scale         $
                      , XTIT='[m]', YTIT='[m]', BAR_TITLE="nm" $
                      , CHARSIZE=cs
      end
      
;;;;;;;;;;;;;;;
; wfp_t display
      'wfp_t': begin
         nl = n_elements(inp.pos_ang)
         arr2disp = inp.screen
         wset, init.win_index
         res = size(inp.pupil)
         nx = res(1)
         ny = res(2)
         if nl gt 1 then begin
            arr2disp = reform(transpose(arr2disp,[0,2,1]), nx * nl, ny)
            for kk=0,nl-1 do arr2disp[kk*nx:(kk+1)*nx-1,*] = (inp.screen[*,*,kk]*1E9)*inp.pupil 
         endif else arr2disp = (inp.screen*1E9)*inp.pupil ; converts the wf into nm
         ind = where(inp.pupil GT 0.9) ; points inside the pupil
         res = moment(arr2disp[ind])
         mean = strtrim(string(res[0], FORMAT="(G9.3)"),2)
         minv = min(arr2disp[ind])
         ind = where(inp.pupil LT 0.9) ; points outside the pupil
         if nl eq 1 then arr2disp[ind] = minv ; in order to use the whole dinamical range
                                ; of the display
         rms = strtrim(string(sqrt(res[1]), FORMAT="(G9.3)"),2)
         image_show2, arr2disp, /SH, /AS, DIG=1              $
                      , /XS, XR=[-.5,.5]*nx*inp.scale_atm      $
                      , /YS, YR=[-.5,.5]*ny*inp.scale_atm      $
                      , XTIT='[m]', YTIT='[m]', BAR_TITLE='nm' $
                      , TIT='Mean='+mean+'nm rms='+rms+'nm'    $
                      , CHARSIZE=cs
      end
      
;;;;;;;;;;;;;;;
; img_t display
      'img_t': begin
;      if (size(inp.image))[0] eq 3 then begin
;         nl = (size(inp.image))[3]
;         arr2disp = inp.image
;         wset, init.win_index
;         res = size(inp.image(*,*,0))
;         nx = res(1)
;         ny = res(2)
;         ; for kk=0, nl-1 do arr2disp[*,*,kk]/=max(arr2disp[*,*,kk])
;         arr2disp = reform(transpose(arr2disp,[0,2,1]), nx*nl, ny)	 
;         image_show2, arr2disp, /SH, /AS, DIG=1             $
;                    , /XS, XR=[-0.5, 0.5]*nx*inp.resolution $
;                    , /YS, YR=[-0.5, 0.5]*ny*inp.resolution $
;                    , XTIT='[arcsec]', YTIT='[arcsec]'      $
;                    , TITLE=title, BAR_TITLE = 'ph'         $
;                    , CHARSIZE=cs
;         dummy = ask_question(par, init, mod_n)
;      endif else begin
;         wset, init.win_index
;         res = size(inp.image)
;         nx = res(1)
;         ny = res(2)
;         arr2disp = inp.image
;         wl = strtrim(long(inp.lambda*1e9),2)
;         dwl = strtrim(long(inp.width*1e9),2)
;         Nph = strtrim(string(total(arr2disp),FORM='(G8.3)'),2)
;         title = "!4k!X="+wl+"nm !4Dk!X="+dwl+"nm N!Iph!N="+Nph
;         image_show2, arr2disp, /SH, /AS, dig = 1  $
;              , /xstyle, xrange=[-0.5, 0.5]*nx*inp.resolution $
;              , /ystyle, yrange=[-0.5, 0.5]*ny*inp.resolution $
;              , xtit='[arcsec]', ytit='[arcsec]' $
;              , TITLE=title $
;              , BAR_TITLE = 'ph' $
;              , CHARSIZE=cs
;         dummy = ask_question(par, init, mod_n)
         case (size(inp.image))[0] of 
            1: begin
               wset,init.win_index
               res = size(inp.image)
               nx = res(1)
               x2disp=(indgen(nx/par.zoom_fac)-nx/(2*par.zoom_fac))*inp.resolution
               y2disp = inp.image[nx/2-nx/(2*par.zoom_fac):nx/2+nx/(2*par.zoom_fac)-1]
               if par.type eq 1 then y2disp = alog10(1.+y2disp)
               if par.type eq 2 then y2disp = y2disp^par.power
               plot, x2disp, y2disp, /XS, XTIT='[arcsec]', YTIT='[counts]', TIT=title, CHARSIZE=cs
            end
            2: begin
               wset, init.win_index
               res = size(inp.image)
               nx = res(1)
               ny = res(2)
               arr2disp = inp.image
               wl = strtrim(long(inp.lambda*1e9),2)
               dwl = strtrim(long(inp.width*1e9),2)
               Nph = strtrim(string(total(arr2disp),FORM='(G8.3)'),2)
               title = "!4k!X="+wl+"nm !4Dk!X="+dwl+"nm N!Iph!N="+Nph
               if par.type eq 1 then arr2disp = alog10(1.+arr2disp)
               if par.type eq 2 then arr2disp = arr2disp^par.power
               image_show2, arr2disp[nx/2-nx/(2*par.zoom_fac):nx/2+nx/(2*par.zoom_fac)-1, $
                                     ny/2-ny/(2*par.zoom_fac):ny/2+ny/(2*par.zoom_fac)-1] $
                            , /SH, /AS, DIG=1, CHARSIZE=cs                                  $
                            , /XS, XR=[-.5,.5]*nx*inp.resolution/par.zoom_fac               $
                            , /YS, YR=[-.5,.5]*ny*inp.resolution/par.zoom_fac               $
                            , XTIT='[arcsec]', YTIT='[arcsec]', TIT=title, BAR_TITLE = 'ph'
            end 
            3: begin                 
               for i=0, (size(init.win_index))[1]-1 do begin
                  wset, init.win_index[i]
                  res = size(inp.image[*,*,i])
                  nx = res(1)
                  ny = res(2)
                  arr2disp = inp.image[*,*,i]
                  wl = strtrim(long(inp.lambda*1E9),2)
                  dwl = strtrim(long(inp.width*1E9),2)
                  Nph = strtrim(string(total(arr2disp),FORM='(G8.3)'),2)
                  title = "!4k!X="+wl+"nm !4Dk!X="+dwl+"nm N!Iph!N="+Nph
                  if par.type eq 1 then arr2disp = alog10(1.+arr2disp)
                  if par.type eq 2 then arr2disp = arr2disp^par.power
                  image_show2, arr2disp[nx/2-nx/(2*par.zoom_fac):nx/2+nx/(2*par.zoom_fac)-1, $
                                        ny/2-ny/(2*par.zoom_fac):ny/2+ny/(2*par.zoom_fac)-1] $
                               , /SH, /AS, DIG=1, CHARSIZE=cs                                  $
                               , /XS, XR=[-.5,.5]*nx*inp.resolution/par.zoom_fac               $
                               , /YS, YR=[-.5,.5]*ny*inp.resolution/par.zoom_fac               $
                               , XTIT='[arcsec]', YTIT='[arcsec]', TIT=title, BAR_TITLE = 'ph'
               endfor
            end
            4: begin
               for i=0, (size(init.win_index))[1]-1 do begin
                  wset, init.win_index[i]
                  res = size(inp.image[*,*,i,0])
                  nx = res(1)
                  ny = res(2)
                  arr2disp = inp.image[*,*,i,0]
                  wl = strtrim(long(inp.lambda*1E9),2)
                  dwl = strtrim(long(inp.width*1E9),2)
                  Nph = strtrim(string(total(arr2disp),FORM='(G8.3)'),2)
                  title = "!4k!X="+wl+"nm !4Dk!X="+dwl+"nm N!Iph!N="+Nph
                  if par.type eq 1 then arr2disp = alog10(1.+arr2disp)
                  if par.type eq 2 then arr2disp = arr2disp^par.power
                  image_show2, arr2disp[nx/2-nx/(2*par.zoom_fac):nx/2+nx/(2*par.zoom_fac)-1, $
                                        ny/2-ny/(2*par.zoom_fac):ny/2+ny/(2*par.zoom_fac)-1] $
                               , /SH, /AS, DIG=1, CHARSIZE=cs                                  $
                               , /XS, XR=[-.5,.5]*nx*inp.resolution/par.zoom_fac               $
                               , /YS, YR=[-.5,.5]*ny*inp.resolution/par.zoom_fac               $
                               , XTIT='[arcsec]', YTIT='[arcsec]', TIT=title, BAR_TITLE = 'ph'
               endfor             
            end   
            else: message, "Input size ERROR"
         endcase
;      dummy = ask_question(par, init, mod_n)                 
      end
      
;;;;;;;;;;;;;;;
; mes_t display
      'mes_t': begin
         wset, init.win_index
         arr2disp=fltarr(inp.nxsub*2,inp.nxsub)
         for k=0,inp.nsp-1 do begin
            arr2disp[inp.xspos_CCD[k]/inp.npixpersub,inp.yspos_CCD[k]/inp.npixpersub]=inp.meas[k]
            arr2disp[inp.xspos_CCD[k]/inp.npixpersub+inp.nxsub,(inp.yspos_CCD[k])/inp.npixpersub]=inp.meas[k+inp.nsp]
         endfor
         image_show2, arr2disp, /SH, /AS, dig = 1 
      end
      
;;;;;;;;;;;;;;;
; mim_t display
      'mim_t': begin
         if (size(inp.image))[0] eq 3 then begin
            nl = (size(inp.image))[3]
            arr2disp = inp.image
            wset, init.win_index
            res = size(inp.image(*,*,0))
            nx = res(1)
            ny = res(2)
            arr2disp = reform(transpose(arr2disp,[0,2,1]), nx * nl, ny)
            image_show2, arr2disp, /SH, /AS 
;       dummy = ask_question(par, init, mod_n)
         endif else begin
            wset, init.win_index
            arr2disp = inp.image
            res = strtrim(string(inp.pxsize,FORMAT="(G8.3)"), 2)
            res = res+"arcsec/pix"
            image_show2, arr2disp, /SH, /AS $
                         , XTITLE="[pix]", YTITLE="[pix]" $
                         , TITLE=res, dig = 1, BAR_TIT='ph' $
                         , CHARSIZE=cs
;         dummy = ask_question(par, init, mod_n)
         endelse
      end
      
;;;;;;;;;;;;;;;
; stf_t display
      'stf_t': begin
         wset, init.win_index
         arr2disp = inp.theo
         np = n_elements(arr2disp)
         xc = findgen(np)*inp.scale
         plot, xc, arr2disp, XTITLE='distance [m]' $
               ,YTITLE='structure function [um^2]'     $
               ,TITLE='iteration # '+strtrim(inp.iter,2) $
               , CHARSIZE=cs
         oplot, xc, inp.struc, psym = 4
;         dummy = ask_question(par, init, mod_n)
      end
      
;;;;;;;;;;;;;;;
; src_t display
      'src_t': begin
         res = size(inp.map)
         case res(0) of
            0: return, error
            2: begin
               wset, init.win_index
               ind = where(inp.n_phot ne 0., count)
               if count eq 0 then begin
                  message, "No photons from the source !!", CONT=(not !caos_DEBUG)
                  return, error
               endif
               dummy = n_phot(0., BAND="V", LAMBDA=lambda)
               idx = where(inp.lambda eq lambda[0])
               n_phot = inp.n_phot[idx] & n_phot=n_phot[0]
               if n_phot eq 0. then begin
                  idx = where(inp.n_phot ne 0)
                  n_phot = inp.n_phot[idx] & n_phot=n_phot[0]
                  print, "No photons from the source in V band: ", $
                         "map displayed in band [",                $
                         strtrim(inp.lambda[idx],2), ",",          $
                         strtrim(inp.width [idx],2), "]."
               endif else print, "Map displayed in V band."
               arr2disp = inp.map*n_phot
               res = size(arr2disp)
               nx = res(1)
               ny = res(2)
               xr = [-.5,.5]*nx*inp.scale_xy*!RADEG*3600/par.zoom_fac
               yr = [-.5,.5]*ny*inp.scale_xy*!RADEG*3600/par.zoom_fac
               if par.type eq 1 then arr2disp = alog10(1.+arr2disp)
               if par.type eq 2 then arr2disp = arr2disp^par.power
               image_show2, arr2disp[nx/2-nx/(2*par.zoom_fac):nx/2+nx/(2*par.zoom_fac)-1  $
                                     ,ny/2-ny/(2*par.zoom_fac):ny/2+ny/(2*par.zoom_fac)-1] $
                            , /SH, /AS, DIG=1, XR=xr, YR=yr, CHARSIZE=cs                    $
                            , XTIT="[arcsec]", YTIT="[arcsec]", BAR_TITLE="ph s!E-1!Nm!E-2!N"
;              dummy = ask_question(par, init, mod_n)
            end
            3: begin
               wset, init.win_index
               error = display_3d(inp.map,                    $
                                  inp.scale_xy, inp.scale_xy, $
                                  inp.scale_z,                $
                                  WIN_XSIZE=init.win_xsize,   $
                                  WIN_YSIZE=init.win_ysize,   $
                                  OFFSET_Z=inp.dist_z,        $
                                  CHARSIZE=cs                 )
;              dummy = ask_question(par, init, mod_n)
            end
            else: begin
               if (init.win_index NE -100) then begin
                  res = dialog_message('Unmanaged variable type, quitting display !!')
                  wdelete, init.win_index
                  init.win_index=-100
               endif else begin
                  res = dialog_message('DIS: Unmanaged variable type')
               endelse
            end
            
         endcase
         
      end
      
      
      'mes_t': begin
         if par.title eq 0 then title='measure values at DIS#'+mod_n+' => ' $
         else title = par.title_info+' => '
         arr2disp = inp.meas
         print, title, strtrim(string(arr2disp),2)
;           dummy = ask_question(par, init, mod_n)
      end
      
;;;;;;;;;;;;;;;
; com_t display
      'com_t': begin
         if par.title EQ 0 then title='Command values at DIS#'+mod_n+' => ' $
         else title=par.title_info+' => '
         arr2disp = inp.command
         case inp.flag of
            0: begin
               print, title, strtrim(string(arr2disp),2)
;           dummy = ask_question(par, init, mod_n)
            end
            1: begin
               print, title, strtrim(string(arr2disp),2)
;           dummy = ask_question(par, init, mod_n)
            end
            -1: begin
               wset, init.win_index
               np = sqrt(n_elements(arr2disp))
               image_show2, reform(arr2disp, np, np), /SH, /AS, DIG=1, CHARSIZE=cs
;           dummy = ask_question(par, init, mod_n)
            end
            
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; none of the pre-defined types 
            else: begin
               print, 'Display case not yet managed: returning...'
               return, error
            endelse
            
         endcase
         
      end
      
      else: begin
         
         if (init.win_index NE -100) then begin
            res = dialog_message($
                  'Unmanaged variable type, quitting display !!')
            wdelete, init.win_index
            init.win_index=-100
         endif else begin
            return, error
         endelse
         
      endelse
      
   endcase
   
endif

return, error
end
