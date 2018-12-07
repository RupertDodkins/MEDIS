;vettori: ADC, DAC, CAPSENS-OUT, CONTI, ONDA QUADRA
;vanno ordinati in strutture del tipo:
; one[0-1,0-x], in cui nella prima colonna ci sono gli start e nella seconda gli end
;NAMES: in ordine di ingresso

Pro time_graph, one, two, three, four, five, $
               NAMES=names, NDOTS = ndots

   if n_elements(ndots) eq 0 then ndots = 150

   if n_elements(start) ne n_elements(endc) then message, 'Error! Start and End vector must be of the same dimensions!'
   if n_elements(start2) ne n_elements(endc2) then message, 'Error! Start and End vector must be of the same dimensions!'
   if n_elements(start3) ne n_elements(endc3) then message, 'Error! Start and End vector must be of the same dimensions!'
   if n_elements(start4) ne n_elements(endc4) then message, 'Error! Start and End vector must be of the same dimensions!'
   if n_elements(start5) ne n_elements(endc5) then message, 'Error! Start and End vector must be of the same dimensions!'


;***********************************************************************
;START COLLECTING AND EVENTUAL PADDING of DATA
;***********************************************************************
   start = transpose(one[0,*])
   endc  = transpose(one[1,*])

   ncol = 1
   npar=n_params()
   nel = intarr(5)
   pp = n_elements(one)
   nel[0] =n_elements(one)/2
   nel[1] =n_elements(two)/2
   nel[2] =n_elements(three)/2
   nel[3] =n_elements(four)/2
   nel[4] =n_elements(five)/2
   idz = where(nel eq 0)
   nel = nel[0:idz[0]-1]

   if n_elements(two) ne 0 then begin
      start2 = transpose(two[0,*])
      endc2  = transpose(two[1,*])
      nel[1] = n_elements(start2)
      if n_elements(start) gt n_elements(start2) then begin
         pad = fltarr(n_elements(start)-n_elements(start2))
         start = [[start],[start2,pad]]
         endc = [[endc],[endc2,pad]]
      endif else begin
            if n_elements(start) eq n_elements(start2) then begin
               start = [[start],[start2]]
               endc = [[endc],[endc2]]
            endif else begin
               pad = fltarr(n_elements(start2)-n_elements(start),1)
               start = [[start,pad],[start2]]
               endc = [[endc,pad],[endc2]]
            endelse
      endelse
      ncol += 1
   endif
   if n_elements(three) ne 0 then begin
      start3 = transpose(three[0,*])
      endc3  = transpose(three[1,*])
       nel[2] = n_elements(start3)
       if n_elements(start2) gt n_elements(start3) then begin
         pad = fltarr(n_elements(start2)-n_elements(start3))
         start = [[start],[start3,pad]]
         endc = [[endc],[endc3,pad]]
      endif else begin
            if n_elements(start) eq n_elements(start2) then begin
               start = [[start],[start3]]
               endc = [[endc],[endc3]]
            endif else begin
               pad = fltarr(n_elements(start3)-n_elements(start2),2)
               start = [[start,pad],[start3]]
               endc = [[endc,pad],[endc3]]
            endelse
      endelse
      ncol += 1
   endif
   if n_elements(four) ne 0 then begin
      start4 = transpose(four[0,*])
      endc4  = transpose(four[1,*])
      nel[3] = n_elements(start4)
        if n_elements(start3) gt n_elements(start4) then begin
         pad = fltarr(n_elements(start3)-n_elements(start4))
         start = [[start],[start4,pad]]
         endc = [[endc],[endc4,pad]]
      endif else begin
             if n_elements(start) eq n_elements(start4) then begin
               start = [[start],[start4]]
               endc = [[endc],[endc4]]
            endif else begin
               pad = fltarr(n_elements(start4)-n_elements(start3),2)
               start = [[start,pad],[start4]]
               endc = [[endc,pad],[endc4]]
            endelse
      endelse
      ncol += 1
   endif
   if n_elements(five) ne 0 then begin
      start5 = transpose(five[0,*])
      endc5  = transpose(five[1,*])
      nel[4] = n_elements(start5)
         if n_elements(start4) gt n_elements(start5) then begin
         pad = fltarr(n_elements(start4)-n_elements(start5))
         start = [[start],[start5,pad]]
         endc = [[endc],[endc5,pad]]
      endif else begin
             if n_elements(start) eq n_elements(start5) then begin
               start = [[start],[start5]]
               endc = [[endc],[endc5]]
            endif else begin
               pad = fltarr(n_elements(start5)-n_elements(start4),2)
               start = [[start,pad],[start5]]
               endc = [[endc,pad],[endc5]]
            endelse
      endelse
      ncol += 1
   endif



;***********************************************************************
;END COLLECTING AND PADDING of DATA
;***********************************************************************


   y = indgen(max(nel))

   tickvalues = ([start, endc, floor(endc[nel-1,*])])
   idx = sort(tickvalues)
   tickvalues = tickvalues[idx]
   uidx = uniq(tickvalues)
   uidx_el = float(n_elements(uidx))
   tickvalues = tickvalues[uidx]
   ;xstr = string(tickvalues, FORMAT='(F4.1)')

   if keyword_set(PS) then begin
   
   endif

   device, DECOMPOSED=0
   loadct, 39
   plot, tickvalues,indgen(uidx_el)/(uidx_el-1)*total(nel), XTICKS=uidx_el*2+1, XTICKV=tickvalues, XTICKLEN=1, XGRIDSTYLE=1, /NODATA , XTITLE='!17[!4l!17m]', TITLE='!17Time scheduling', XS=17, COL=0, BACKGROUND='FFFFFF'xl, XTICKFORMAT = '(F4.1)';,XTICKNAME=xstr

   ;if npar eq 1 then col = comp_colors(nel[0]) else col = comp_colors(ncol)
   if npar eq 1 then col = reverse(indgen(nel[0])+1)*(240/nel[0]) else col = (indgen(ncol)+1)/ncol*(240/ncol)
   range = max(tickvalues) - min(tickvalues)
   pixscx=  range / (!d.x_size - (!x.margin[0] +!x.margin[1]) *!d.x_ch_size)
   pixscy=  range / (!d.y_size - (!y.margin[0] +!y.margin[1]) *!d.y_ch_size)

   duration = fltarr(nel)
   durationstr = strarr(nel)
   ymax=0
   for k=0, npar-1 do begin

      y = indgen(nel[k])+ymax
      for i = 0, nel[k]-1 do begin
         line = start[i,k]+findgen(ndots)/(ndots-1)*(endc[i,k]-start[i,k])
         duration[i] = (max(line)-min(line));/2.
         durationstr[i] =  string(duration[i],format='(f5.2)')
         plots,line, replicate(y[nel[k]-1-i],ndots), psym=2, thick=1, col=replicate(col[k], ndots)
      endfor

      if keyword_set(names) then begin

         names = strtrim(string(names),2)
         durationstr[where(names ne '')] = names
         centerx = !d.x_ch_size*pixscx /2. * (strlen(durationstr))
         centery = !d.y_ch_size*pixscy /2. + fltarr(nel[k])
         for i = 0, nel[k]-1 do begin
            xyouts,  start[i,k]+duration[i]/2.-centerx[i], y[nel[k]-1-i]+0.3-centery[i],durationstr[i,k], COL=0
         endfor


      endif else begin
   
         centerx = !d.x_ch_size*pixscx /2. * (strlen(durationstr)) 
         centery = !d.y_ch_size*pixscy /2. + fltarr(nel[k])
         for i = 0, nel[k]-1 do begin
            xyouts,  start[i,k]+duration[i]/2.-centerx[i], y[nel[k]-1-i]+0.3-centery[i], durationstr[i],COL=0
         endfor

      endelse
      ymax=max(y)+1
   endfor

   if keyword_set(PS) then begin
      device, /close
      set_plot, old_sys
   endif

End
