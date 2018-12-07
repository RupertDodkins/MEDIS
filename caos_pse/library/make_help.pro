; $Id: make_help.pro,v 3.0 last update: 2016/06/19 marcel.carbillet $
;
;+
; NAME:
;       MAKE_HELP
;
; PURPOSE:
;       To build the HELP of a Software Package. The procedure makes three .html
;       files in the "help" folder of the Software Package. Edit those files 
;       if you need to add specific information.
;       When you launch "make_help", a Graphical User Interface (GUI) appears 
;       and you can enter:
;       - the path of the Software Package;
;       - the number and the information about the author(s); 
;       - the URL of the website of the CAOS PSE (optional);
;       - the URL of the website of the Software Package (optional).
;       - the LOGO of the Software Package (optional). Must be a valid file 
;         (bmp, jpeg, gif or any supported graphic file) and must be contained 
;         in the help folder of the package. 
;
; CATEGORY:
;       Library utility
;
; CALLING SEQUENCE:
;       type "make_help" at the CAOS PSE prompt
; 
; INPUTS:
;       None. 
;
; OPTIONAL INPUTS:
;       None.
;      
; KEYWORD PARAMETERS:
;       None.
;
; OUTPUTS:
;       None.
;
; OPTIONAL OUTPUTS:
;       None.
;
; COMMON BLOCKS:
;       None.
;
; SIDE EFFECTS:
;       None.
;
; RESTRICTIONS:
;       This procedure works with MACOSX and LINUX only.
;
; PROCEDURE:
;       None.
;
; EXAMPLE:
;       None.       
;
; MODIFICATION HISTORY:
;    program written: April 2007,
;                     Andrea La Camera (DISI) [lacamera@disi.unige.it]
;                     Gabriele Desidera' (DISI) [desidera@disi.unige.it]
;    modifications  : December 2010,
;                     Andrea La Camera (DISI) [lacamera@disi.unige.it]:
;                    -Routine debugged.
;                    -CAOS PSE website changed;
;                   : July 2010,
;                     Andrea La Camera (DISI) [lacamera@disi.unige.it]:
;                    -Routine debugged.
;                   : June 2012 (v.2.2),
;                     Andrea La Camera (DISI) [lacamera@disi.unige.it]:
;                    -CAOS PSE website changed (again!),
;                    -Routine debugged,
;                    -New "look&feel" of the pages based on HTML5 template: 
;                     http://www.html5webtemplates.co.uk/templates.html.
;                     All necessary files are located in the "html_template_style" 
;                     folder, that is included in this version of the CAOS_Library.
;                     This folder will be copied to the HELP folder of the package.
;                   : June 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -path for (new) CAOS library fixed.
;-
;
;---
pro make_help_status,state
   widget_control, state.id.link_caos, set_value=state.val.ok_link_caos
   widget_control, state.id.link_softpack, set_value=state.val.ok_link_softpack
   widget_control, state.id.logo, set_value=state.val.ok_logo
end

;---
pro make_help_event,event

widget_control, event.ID, GET_UVALUE=choice
WIDGET_CONTROL, event.TOP, GET_UVALUE=state

case choice of 
 'filename' : state.val.filename=event.value
              
 'nb_authors':   begin
                 state.val.nb_authors=event.value
              end
 'authors':   begin
              if event.select then begin
                 desc=['0,LABEL,Insert <<name (organization) [mail]>> of author(s), CENTER', $
                       '0,LABEL,e.g. Andrea La Camera (DIBRIS) [andrea.lacamera@unige.it], CENTER',$
                       '0,LABEL,, CENTER']
                 if state.val.authors EQ '' then authors=make_array(state.val.nb_authors,value='') $
                                            else authors=strsplit(state.val.authors,'/',/extract)
                 P=0
                 for k=0,(state.val.nb_authors<(N_ELEMENTS(authors)))-1 do begin
                    P++ 
                    desc=[desc,'0,TEXT,'+authors[k]+' , width=40, tag=name'+strtrim(k,1)]
                 endfor
                 for k=0,(state.val.nb_authors-(N_ELEMENTS(authors)))-1 do begin
                    desc=[desc,'0,TEXT, , width=40, tag=name'+strtrim(P,1)]
                    P++
                 endfor
                 desc=[desc,$
                       '1,BASE,,ROW, FRAME', $
                       '0,BUTTON, ok, quit, tag=ok', $
                       '2,BUTTON, cancel, quit, tag=cancel']
                 dummy=cw_form(desc, /COLUMN, title='MAKE_HELP input GUI')

                 ;state.val.nb_authors=N_ELEMENTS(authors)
                 name=''
                 for k=0,state.val.nb_authors-2 do begin
                    name=name+dummy.(k)+'/'
                 endfor
                 name=name+dummy.(state.val.nb_authors-1)
                 state.val.authors=name
              endif
              end

 'link_caos': begin
		 if event.select then begin
                 desc=['0,LABEL,Insert the URL of the CAOS Home Page, CENTER', $
                       '1,BASE,,ROW, FRAME', $
                       '0,TEXT, '+state.val.link_caos+', width=35, tag=namelink',$
                       '2,BASE,,ROW, FRAME', $
                       '0,BUTTON, ok, quit, tag=ok', $
                       '2,BUTTON, cancel, quit, tag=cancel']
                 dummy=cw_form(desc, /COLUMN, title='MAKE_HELP input GUI')
                 if dummy.ok then begin 
                    state.val.link_caos=dummy.namelink 
		              state.val.ok_link_caos=1B
                 endif 
       endif else state.val.ok_link_caos=0B
       end

 'link_softpack': begin
		 if event.select then begin
          desc=['0,LABEL,Insert the URL of the <<Software Package>> Home Page, CENTER', $
                '1,BASE,,ROW, FRAME', $
                '0,TEXT, '+state.val.link_softpack+', width=35, tag=namelink',$
                '2,BASE,, ROW, FRAME', $
                '0,BUTTON, ok, quit, tag=ok', $
                '2,BUTTON, cancel, quit, tag=cancel']
          dummy=cw_form(desc, /COLUMN, title='MAKE_HELP input GUI')
          if dummy.ok then begin
              state.val.link_softpack=dummy.namelink 
              state.val.ok_link_softpack=1B
          endif 
       endif else state.val.ok_link_softpack=0B
       end
'logo' :  begin
		 if event.select then begin
          desc=['1,BASE,,COLUMN, FRAME', $
                '1,BASE,,ROW', $
                '0,LABEL,Insert the filename of the logo picture, CENTER', $
                '0,LABEL,(must be a valid file contained within the help,CENTER',$
                '2,LABEL, folder of the software package), CENTER', $
                '2,TEXT, '+state.val.logo_file+', width=35, tag=file',$
                '1,BASE,,ROW, FRAME', $
                '0,LABEL,Insert the width of the logo picture (in pixel),CENTER',$
                '2,TEXT, '+strtrim(state.val.logo_width,1)+', width=35, tag=width',$
                '1,BASE,,ROW, FRAME', $
                '0,BUTTON, ok, quit, tag=ok', $
                '2,BUTTON, cancel, quit, tag=cancel']
          dummy=cw_form(desc, /COLUMN, title='MAKE_HELP input GUI')
          if dummy.ok then begin
              state.val.logo_file=dummy.file 
              state.val.logo_width=dummy.width
              state.val.ok_logo=1B
          endif 
       endif else state.val.ok_logo=0B
       end
 'make':      begin
      idlhome='http://www.exelisvis.com/'
      astrolib='http://idlastro.gsfc.nasa.gov/homepage.html'
		path=state.val.filename
		if path EQ '' then return
		path1=path+'modules/'
		cd,path1
		
		spawn,"ls > ../list.txt"
		
		openr,1,'../list.txt'
		num_mod=0
		while not eof(1) do begin
		nome=" "
		readf,1,nome
		num_mod++
		endwhile
		point_lun,1,0
		moduli=""
		moduli2=""
		for k=0,num_mod-1 do begin
		nome=" "  
		readf,1,nome
		moduli=[moduli,nome]
		moduli2=[moduli2,nome+"/"+nome+".pro"]
		endfor
		close,1
		
		mk_html_help,moduli2,"../help/temp_help.html"
		spawn,"rm ../list.txt"
		
		path2=path+'help/'
		cd, path2
		
		;reading TEMP_HELP.HTML
		openr,2,'temp_help.html'
		num_help=0
		while not eof(2) do begin
		nome=" "
		readf,2,nome
		num_help++
		endwhile
		point_lun,2,0
		temphelp=""
		for k=0,num_help-1 do begin
		nome=" "  
		readf,2,nome
		temphelp=[temphelp,nome]
		endfor
		close,2
		
		softpackname=strsplit(path,'/',/extract)
		softpackname=softpackname((size(softpackname))[1]-1)
		packname=strlowcase((strsplit(softpackname,'_',/extract))[0])
		
		;spawn, "mv "+packname+"_help.html "+packname+"_help.html.old"
		;spawn, "mv "+packname+"_modules.html "+packname+"_modules.html.old"
		spawn, "cp -R -f "+!caos_env.root+"/library/html_template_style  ." 
		
		;writing of the HTML file     ----------------------------- HOME
		openw,2,packname+"_help.html"
      printf,2,'<!DOCTYPE HTML>'
      printf,2,'<html>'
      printf,2,''
      printf,2,'<head>'
      printf,2,'  <meta name="description" content="'+packname+' Software Package" />'
      printf,2,'  <meta name="keywords" content="'+packname+' Sofware Package, CAOS PSE" />'
      printf,2,'  <meta http-equiv="content-type" content="text/html; charset=windows-1252" />'
      printf,2,'  <link rel="stylesheet" type="text/css" href="html_template_style/style.css" />'
      printf,2,'<title>'+softpackname+' - Help</title>'
		printf,2,'</head>'
		printf,2,''
      printf,2,'<body>'
      printf,2,'  <div id="main">'
      printf,2,'    <div id="header">'
      printf,2,'      <div id="logo">'
      printf,2,'        <div id="logo_text">'
      printf,2,'          <h1><a href="'+packname+'_help.html">'+softpackname+'<span class="logo_colour"> HELP </span></a></h1>'
      printf,2,'          <h2>A software package of the CAOS Problem Solving Environment.</h2>'
      printf,2,'        </div>'
      printf,2,'      </div>'
      printf,2,'      <div id="menubar">'
      printf,2,'        <ul id="menu">'
      printf,2,'          <li class="selected"><a href="'+packname+'_help.html">Home</a></li>'
      printf,2,'          <li><a href="'+packname+'_routines.html">Routines</a></li>'
      printf,2,'          <li><a href="'+packname+'_contacts.html">Contacts</a></li>'
      printf,2,'        </ul>'
      printf,2,'      </div>'
      printf,2,'    </div>'
      printf,2,'    <div id="content_header"></div>'
      printf,2,'    <div id="site_content">'
      printf,2,'      <div id="sidebar_container">'
      printf,2,'        <div class="sidebar">'
      printf,2,'          <!-- insert your sidebar items here -->'
      printf,2,'          <div class="sidebar_top"></div>'
      printf,2,'          <div class="sidebar_item">'
      printf,2,'            <h3>Latest News</h3>'
      printf,2,'            <h4>New Software Package Release</h4>'
      printf,2,'            <h5>'+systime()+'</h5>'
      printf,2,'            <p> Today the new version of the Software Package '+$
                            strupcase(packname)+' has been released. </p>'
      printf,2,'          </div>'
      printf,2,'          <div class="sidebar_base"></div>'
      printf,2,'        </div>  '   
      printf,2,'        <div class="sidebar">'
      printf,2,'          <div class="sidebar_top"></div>'
      printf,2,'          <div class="sidebar_item">'
      printf,2,'            <h3>Useful Links</h3>'
      printf,2,'            <ul>'
		if state.val.ok_link_softpack then begin
         printf,2,'              <li><a href="'+$
                  state.val.link_softpack+'" target="_blanck">'+$
			         strupcase(packname)+' homepage</a></li>'
	   endif
		if state.val.ok_link_caos then begin
         printf,2,'              <li><a href="'+state.val.link_caos+$
                  '" target="_blanck">'+$
		            'CAOS homepage</a></li>'
		endif
      printf,2,'              <li><a href="'+idlhome+'" target="_blanck">IDL homepage</a></li>'
      printf,2,'              <li><a href="'+astrolib+'" target="_blanck">The IDL Astronomy Library</a></li>'
      printf,2,'            </ul>'
      printf,2,'          </div>'
      printf,2,'          <div class="sidebar_base"></div>'
      printf,2,'        </div>'
      printf,2,'      </div>'
      printf,2,'      <div id="content">'
      printf,2,'        <!-- insert the page content here -->'
      printf,2,'        <h1>Welcome to '+softpackname+' - Help</h1>'
      if state.val.ok_logo then begin
      printf,2,'        <center><p><img SRC="./'+state.val.logo_file+'" width="'+$
               strtrim(state.val.logo_width,1)+'px"></p>'
      endif
      printf,2,'        <hr width=50%></center>'
      printf,2,'        <p>This document contains the headers of the main routine'
		printf,2,'        xxx.pro of each module XXX. You can find more information'
		printf,2,'        about each routine of the '+softpackname+', '
		printf,2,'        as well as of the whole CAOS PSE, either '
		printf,2,'        by editing the header of the routine itself or, alternatively,'
		printf,2,'        by typing at the IDL prompt: <br />'
		printf,2,'        <blockquote><b><code>doc_library, "routine_name"</code></b></blockquote><br />'
		printf,2,'        where routine_name is the string corresponding to the name of the routine'
		printf,2,'        (e.g. "n_phot", "addnoise", "'+STRUPCASE(moduli[1])+'", "'+$
		                   STRUPCASE(moduli[2])+'", etc.). The routines available'
		printf,2,'         in this version of the Software Package are listed'
		printf,2,'         in the following table and described in the next page.</p>'
      printf,2,'        <h2>List of Routines</h2>'
      printf,2,'        <table width="75%" cellpadding="10px"><tr>'
      for k=1,num_mod do begin
      printf,2,'           <td align="center">'+strupcase(moduli[k])+'</td>'
      if (k mod 3) EQ 0 then printf,2,'        </tr><tr>'
      endfor
      printf,2,'        </tr></table>' 
      printf,2,'        <h4>Compiled by:</h4>'
		printf,2,'          <ul>'
      authors=strsplit(state.val.authors,'/',/extract)
		for k=0,state.val.nb_authors-1 do begin
		   printf,2,'          <li>'+authors[k]+'</li>'
		endfor
		printf,2,'          </ul>'
		printf,2,'       <h4>last modified:</h4><p>'+systime()+'</p>'
      printf,2,'      </div>'
      printf,2,'    </div>'
      printf,2,'    <div id="content_footer"></div>'
      printf,2,'    <div id="footer">'
      printf,2,'      <p>Copyright &copy; simplestyle_4 | <a href="http://validator.w3.org/check?uri=referer">HTML5</a> | <a href="http://jigsaw.w3.org/css-validator/check/referer">CSS</a> | <a href="http://www.html5webtemplates.co.uk">design from HTML5webtemplates.co.uk</a></p>'
      printf,2,'    </div>'
      printf,2,'  </div>'
      printf,2,'</body>'
		printf,2,'</html>'
		close,2
		
		;writing of the HTML file     ----------------------------- ROUTINES
		openw,2,packname+"_routines.html"
      printf,2,'<!DOCTYPE HTML>'
      printf,2,'<html>'
      printf,2,''
      printf,2,'<head>'
      printf,2,'  <meta name="description" content="'+packname+' Software Package" />'
      printf,2,'  <meta name="keywords" content="'+packname+' Sofware Package, CAOS PSE" />'
      printf,2,'  <meta http-equiv="content-type" content="text/html; charset=windows-1252" />'
      printf,2,'  <link rel="stylesheet" type="text/css" href="html_template_style/style.css" />'
      printf,2,'<title>'+softpackname+' - Help</title>'
		printf,2,'</head>'
		printf,2,''
      printf,2,'<body>'
      printf,2,'  <div id="main">'
      printf,2,'    <div id="header">'
      printf,2,'      <div id="logo">'
      printf,2,'        <div id="logo_text">'
      printf,2,'          <h1><a href="'+packname+'_help.html">'+softpackname+'<span class="logo_colour"> HELP </span></a></h1>'
      printf,2,'          <h2>A software package of the CAOS Problem Solving Environment.</h2>'
      printf,2,'        </div>'
      printf,2,'      </div>'
      printf,2,'      <div id="menubar">'
      printf,2,'        <ul id="menu">'
      printf,2,'          <li><a href="'+packname+'_help.html">Home</a></li>'
      printf,2,'          <li class="selected"><a href="'+packname+'_routines.html">Routines</a></li>'
      printf,2,'          <li><a href="'+packname+'_contacts.html">Contacts</a></li>'
      printf,2,'        </ul>'
      printf,2,'      </div>'
      printf,2,'    </div>'
      printf,2,'    <div id="content_header"></div>'
      printf,2,'    <div id="site_content">'
      printf,2,'      <div id="sidebar_container">'
      printf,2,'        <div class="sidebar">'
      printf,2,'          <!-- insert your sidebar items here --> '
      printf,2,'          <div class="sidebar_top"></div>'
      printf,2,'          <div class="sidebar_item">'
      printf,2,'            <h3>Latest News</h3>'
      printf,2,'            <h4>New Software Package Release</h4>' 
      printf,2,'            <h5>'+systime()+'</h5>'
      printf,2,'            <p> Today the new version of the Software Package '+$
                            strupcase(packname)+' has been released. </p>'
      printf,2,'          </div>'
      printf,2,'          <div class="sidebar_base"></div>'
      printf,2,'        </div>'   
      printf,2,'        <div class="sidebar">'
      printf,2,'          <div class="sidebar_top"></div>'
      printf,2,'          <div class="sidebar_item">'
      printf,2,'            <h3>Useful Links</h3>'
      printf,2,'            <ul>'
		if state.val.ok_link_softpack then begin
         printf,2,'              <li><a href="'+$
                  state.val.link_softpack+'" target="_blanck">'+$
			         strupcase(packname)+' homepage</a></li>'
	   endif
		if state.val.ok_link_caos then begin
         printf,2,'              <li><a href="'+state.val.link_caos+$
                  '" target="_blanck">'+$
		            'CAOS homepage</a></li>'
		endif
      printf,2,'              <li><a href="'+idlhome+'" target="_blanck">IDL homepage</a></li>'
      printf,2,'              <li><a href="'+astrolib+'" target="_blanck">The IDL Astronomy Library</a></li>'
      printf,2,'            </ul>'
      printf,2,'          </div>'
      printf,2,'          <div class="sidebar_base"></div>'
      printf,2,'        </div>'
      printf,2,'      </div>'
      printf,2,'      <div id="content">'
      printf,2,'        <!-- insert the page content here -->'
      printf,2,'        <a name="TOP"></a>'
      printf,2,'        <a name="ROUTINELIST">'
      printf,2,'        <h2>List of Routines</h2>'
      printf,2,'        <table width="75%"><tr>'
      for k=1,num_mod do begin
         printf,2,'           <td align="center"><a href="#'+$
                  strupcase(moduli[k])+'">'+strupcase(moduli[k])+'</a></td>'
         if (k mod 3) EQ 0 then printf,2,'        </tr><tr>'
      endfor
      printf,2,'        </tr></table>' 
      printf,2,'        <hr width=75%>'
		for k=28+num_mod,num_help-3 do begin
		   nome=temphelp[k]
		   if strcmp(nome, '<a href="#ROUTINELIST">[List of Routines]</a>') then begin
		            nome='<a href="#TOP">[Top]</a>'
		   endif
		   printf,2,nome
		endfor
      printf,2,'    <div id="content_footer"></div>'
      printf,2,'    <div id="footer">'
      printf,2,'      <p>Copyright &copy; simplestyle_4 | <a href="http://validator.w3.org/check?uri=referer">HTML5</a> | <a href="http://jigsaw.w3.org/css-validator/check/referer">CSS</a> | <a href="http://www.html5webtemplates.co.uk">design from HTML5webtemplates.co.uk</a></p>'
      printf,2,'    </div>'
      printf,2,'  </div>'
      printf,2,'</body>'
		printf,2,'</html>'
      close,2

		;writing of the HTML file     ----------------------------- CONTACTS
		openw,2,packname+"_contacts.html"
      printf,2,'<!DOCTYPE HTML>'
      printf,2,'<html>'
      printf,2,''
      printf,2,'<head>'
      printf,2,'  <meta name="description" content="'+packname+' Software Package" />'
      printf,2,'  <meta name="keywords" content="'+packname+' Sofware Package, CAOS PSE" />'
      printf,2,'  <meta http-equiv="content-type" content="text/html; charset=windows-1252" />'
      printf,2,'  <link rel="stylesheet" type="text/css" href="html_template_style/style.css" />'
      printf,2,'<title>'+softpackname+' - Help</title>'
		printf,2,'</head>'
		printf,2,''
      printf,2,'<body>'
      printf,2,'  <div id="main">'
      printf,2,'    <div id="header">'
      printf,2,'      <div id="logo">'
      printf,2,'        <div id="logo_text">'
      printf,2,'          <h1><a href="'+packname+'_help.html">'+softpackname+'<span class="logo_colour"> HELP </span></a></h1>'
      printf,2,'          <h2>A software package of the CAOS Problem Solving Environment.</h2>'
      printf,2,'        </div>'
      printf,2,'      </div>'
      printf,2,'      <div id="menubar">'
      printf,2,'        <ul id="menu">'
      printf,2,'          <li><a href="'+packname+'_help.html">Home</a></li>'
      printf,2,'          <li><a href="'+packname+'_routines.html">Routines</a></li>'
      printf,2,'          <li class="selected"><a href="'+packname+'_contacts.html">Contacts</a></li>'
      printf,2,'        </ul>'
      printf,2,'      </div>'
      printf,2,'    </div>'
      printf,2,'    <div id="content_header"></div>'
      printf,2,'    <div id="site_content">'
      printf,2,'      <div id="sidebar_container">'
      printf,2,'        <div class="sidebar">'
      printf,2,'          <!-- insert your sidebar items here --> '
      printf,2,'          <div class="sidebar_top"></div>'
      printf,2,'          <div class="sidebar_item">'
      printf,2,'            <h3>Latest News</h3>'
      printf,2,'            <h4>New Software Package Release</h4>' 
      printf,2,'            <h5>'+systime()+'</h5>'
      printf,2,'            <p> Today the new version of the Software Package '+$
                            strupcase(packname)+' has been released. </p>'
      printf,2,'          </div>'
      printf,2,'          <div class="sidebar_base"></div>'
      printf,2,'        </div>'   
      printf,2,'        <div class="sidebar">'
      printf,2,'          <div class="sidebar_top"></div>'
      printf,2,'          <div class="sidebar_item">'
      printf,2,'            <h3>Useful Links</h3>'
      printf,2,'            <ul>'
		if state.val.ok_link_softpack then begin
         printf,2,'              <li><a href="'+$
                  state.val.link_softpack+'" target="_blanck">'+$
			         strupcase(packname)+' homepage</a></li>'
	   endif
		if state.val.ok_link_caos then begin
         printf,2,'              <li><a href="'+state.val.link_caos+$
                  '" target="_blanck">'+$
		            'CAOS homepage</a></li>'
		endif
      printf,2,'              <li><a href="'+idlhome+'" target="_blanck">IDL homepage</a></li>'
      printf,2,'              <li><a href="'+astrolib+'" target="_blanck">The IDL Astronomy Library</a></li>'
      printf,2,'            </ul>'
      printf,2,'          </div>'
      printf,2,'          <div class="sidebar_base"></div>'
      printf,2,'        </div>'
      printf,2,'      </div>'
      printf,2,'      <div id="content">'
      printf,2,'        <!-- insert the page content here -->'
      printf,2,'        <h1>'+softpackname+' - Contacts</h1>'
      printf,2,'        <hr width=50%>'
      printf,2,'        <p><b>For any suggestion, comment, bug report, or '
      printf,2,'        feature request please write an email to the '
      printf,2,'        dedicated mailing-list of the Software Package '+$
                        strupcase(packname)+'.</b> <br />'
      printf,2,'        If you are not already a subscriber to the mailing-list, you'
      printf,2,'        can subscribe now. Please refer to the CAOS website for instructions.'
      printf,2,'        <h4>Compiled by:</h4>'
		printf,2,'          <ul>'
      authors=strsplit(state.val.authors,'/',/extract)
		for k=0,state.val.nb_authors-1 do begin
		   printf,2,'          <li>'+authors[k]+'</li>'
		endfor
		printf,2,'          </ul>'
		printf,2,'       <h4>last modified:</h4><p>'+systime()+'</p>'
      printf,2,'      </div>'
      printf,2,'    </div>'
      printf,2,'    <div id="content_footer"></div>'
      printf,2,'    <div id="footer">'
      printf,2,'      <p>Copyright &copy; simplestyle_4 | <a href="http://validator.w3.org/check?uri=referer">HTML5</a> | <a href="http://jigsaw.w3.org/css-validator/check/referer">CSS</a> | <a href="http://www.html5webtemplates.co.uk">design from HTML5webtemplates.co.uk</a></p>'
      printf,2,'    </div>'
      printf,2,'  </div>'
      printf,2,'</body>'
		printf,2,'</html>'
      close,2

		
		;remove TEMP_HELP.HTML
		spawn, 'rm temp_help.html'
		done=Dialog_Message('        DONE!        ', /INFO)
end

'ok': begin
      widget_control, event.top, /destroy
      return
end
endcase

WIDGET_CONTROL, event.TOP, SET_UVALUE=state
make_help_status, state
end

;---
pro make_help

id={filename:0L,authors:0L,nb_authors:0L, link_caos:0L,link_softpack:0L,logo:0L,$
    make_button:0L,ok_button:0L}
val={filename:!caos_env.modules,authors:'',nb_authors:1,$
     ok_link_caos:0B,link_caos:'http://lagrange.oca.eu/caos',$
     ok_link_softpack:0B,link_softpack:'http://',$
     ok_logo:0B,logo_file:'logo.jpg',logo_width:300}

state={id:id,val:val}

base=WIDGET_BASE(TITLE='MAKE_HELP', /COL)
baseA=WIDGET_BASE(base, /COL)
   state.id.filename =      cw_filename(baseA, TITLE="path of the <<Software Package>>:", $
                                        VALUE=state.val.filename, UVALUE="filename", $
                                        /ALL_EVENTS, /GET_PATH)
   baseB=WIDGET_BASE(baseA, /ROW, /frame)
      state.id.nb_authors =    cw_field (baseB, /COL, title='NB of author(s)', value=state.val.nb_authors, $
                                         uvalue='nb_authors', /all_event)
      state.id.authors =      widget_button(baseB, value='Insert author(s) names ', UVALUE='authors')
   baseC=WIDGET_BASE(baseA, /COL, /frame)
      state.id.link_caos =     cw_bgroup(baseC, 'Include link to CAOS Home Page', uvalue='link_caos', /nonexclusive)
      state.id.link_softpack = cw_bgroup(baseC, 'Include link to <<Software Package>> Home Page', $
                                      uvalue='link_softpack', /nonexclusive)
      state.id.logo = cw_bgroup(baseC, 'Include the logo picture of the <<Software Package>>', $
                                      uvalue='logo', /nonexclusive)
baseD=WIDGET_BASE(base, /ROW, /align_center)
   state.id.make_button=widget_button(baseD,value='MAKE HELP', uvalue='make',xsize=120)
   state.id.ok_button = widget_button(baseD,value='EXIT', uvalue='ok')

WIDGET_CONTROL, base, /REALIZE
WIDGET_CONTROL, base, SET_UVALUE=state
XMANAGER, 'make_help', base, event='make_help_event'

end