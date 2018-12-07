;T+
; \subsubsection{Procedure: {\tt do\_package}}
;
; This procedure gaters info related to modules in a single package.
; It must be called repeatedly for each package directory.
;
;T-
;
; MODIFICATION HISTORY
;
; 26 July     2004 - modified in order to work also under windows XP
;                  (lyu.abe [lyu.abe@unice.fr],
;                  brice le roux [leroux@arcetri.astro.it],
;                  marcel carbillet [marcel@arcetri.astro.it]).
; 9  August   2006 - "power spectrum" type (pws_t) added for Soft.Pack.PAOLAC
;                  (marcel carbillet [marcel.carbillet@unice.fr]).
; 18 December 2007 - "LINC/NIRVANA data" type (lnd_t) added for Soft.Pack.AIRY-LN
;                  (gabriele desidera' [desidera@disi.unige.it]).
; 20 February 2009 - TypeList & IOcolors variable re-ordered for compatibility
;                  of I/O colors with older projects
;                  (marcel carbillet [marcel.carbillet@unice.fr]).
;
FUNCTION do_package, path, COUNT=count

case !VERSION.OS_FAMILY of
   "unix": begin
files = FINDFILE(path, COUNT=count)
files = files[WHERE(files NE 'CVS')]       ; Get rid of CVS directory
      files = files[WHERE(files NE 'CVS')] ; Get rid of CVS directory
   end
   "Windows": begin
	  cd,path,CURRENT=old_path
	  files = FINDFILE('*', COUNT=count)
     files = files[WHERE((files NE ('.\')) AND (files NE ('..\')))] ; Get rid of CVS directory      
 	  count = N_ELEMENTS(files)
      for temp_i=0,count-1 do begin
      	files(temp_i) = STRMID(files(temp_i),0,strlen(files(temp_i))-1)
      endfor
      cd,old_path
   end
   "vms": begin
files = FINDFILE(path, COUNT=count)
files = files[WHERE(files NE 'CVS')]      ; Get rid of CVS directory
      files = files[WHERE(files NE 'CVS')]      ; Get rid of CVS directory
   end
   "MacOS": begin
files = FINDFILE(path, COUNT=count)
files = files[WHERE(files NE 'CVS')]      ; Get rid of CVS directory
      files = files[WHERE(files NE 'CVS')]      ; Get rid of CVS directory
   end
   else: message, "the operative system of the family "+!VERSION.OS_FAMILY $
                   +" is not supported."
endcase


count=N_ELEMENTS(files)


IF count GT 0 THEN BEGIN
    mods = strarr(count)                  ; modules name list
    RETURN, files[SORT(files)]
ENDIF ELSE RETURN, ''

END

;T+
; \subsubsection{Procedure: {\tt find\_mod\_info}}         \label{fndmodinf}
;
; In order to allow the definition of new modules without the need to modify
; the {\tt AB} code, the module list is automatically generated from the
; info provided by the modules currently generated. The following function
; scans the module directory for all defined modules and creates a list of all
; modules found. The list is actually a structure which contains both the
; module info and the Module menu array
;
;T-

PRO find_mod_info, ModMenu, ModInfo, COUNT=count

COMMON Worksheet_Common

;                                    Get a list of packages
path = !CAOS_ENV.root+'packages'

case !VERSION.OS_FAMILY of
   "unix": begin
	  pkg_path = FINDFILE(path, COUNT=pkg_count)
      pkg_path = pkg_path[WHERE(pkg_path NE 'CVS')]     ; Get rid of CVS directory
   end
   "Windows": begin
	  cd,path,CURRENT=old_path
      pkg_path = FINDFILE('*', COUNT=pkg_count)
      pkg_path = pkg_path[WHERE((pkg_path NE ('.\')) AND (pkg_path NE ('..\')))]      ; Get rid of CVS directory
      pkg_count = N_ELEMENTS(pkg_path)
      for temp_i=0,pkg_count-1 do begin
      	pkg_path(temp_i) = STRMID(pkg_path(temp_i),0,strlen(pkg_path(temp_i))-1)
      endfor
      cd,old_path
   end
   "vms": begin
	pkg_path = FINDFILE(path, COUNT=pkg_count)
      pkg_path = pkg_path[WHERE(pkg_path NE 'CVS')]     ; Get rid of CVS directory
   end
   "MacOS": begin
	pkg_path = FINDFILE(path, COUNT=pkg_count)
      pkg_path = pkg_path[WHERE(pkg_path NE 'CVS')]     ; Get rid of CVS directory
   end
   else: message, "the operative system of the family "+!VERSION.OS_FAMILY $
                   +" is not supported."
endcase

pkg_count = N_ELEMENTS(pkg_path)

count = 0L
mprefix='0\'

IF pkg_count GT 0 THEN BEGIN
    FOR j=0,pkg_count-1 DO BEGIN
        ModMenu = [ModMenu, '1\'+pkg_path[j]]
        mods=do_package(path+!CAOS_ENV.delim+pkg_path[j]+    $
                        !CAOS_ENV.delim+'modules',COUNT=mod_count)
        FOR i=0, mod_count-1 DO BEGIN

           NewMod= {MOD_INFO}

	   ProcName=STRLOWCASE(mods[i]+'_info')

       case !VERSION.OS_FAMILY of
		   "unix": begin
			   RESOLVE_ROUTINE, ProcName, /IS_FUNCTION
		   end
		   "Windows": begin
			   cd,path+!CAOS_ENV.delim+pkg_path[j]+!CAOS_ENV.delim+'modules'+!CAOS_ENV.delim+mods[i],CURRENT=old_path
			   RESOLVE_ROUTINE, ProcName, /IS_FUNCTION
			   cd,old_path
		   end
		   "vms": begin
			   RESOLVE_ROUTINE, ProcName, /IS_FUNCTION
		   end
		   "MacOS": begin
			   RESOLVE_ROUTINE, ProcName, /IS_FUNCTION
		   end
		   else: message, "the operative system of the family "+!VERSION.OS_FAMILY $
		                   +" is not supported."
	   endcase



	   RetVal=CALL_FUNCTION(ProcName)

	   inp = STR_SEP(RetVal.inp_type, ',')
   	   IF inp[0] EQ '' THEN Ninp=0 ELSE Ninp=N_ELEMENTS(inp)

	   out = STR_SEP(RetVal.out_type, ',')
   	   IF out[0] EQ '' THEN Nout=0 ELSE Nout=N_ELEMENTS(out)

   	   NewMod.pkg      = pkg_path[j]
	   NewMod.type     = STRLOWCASE(RetVal.mod_name)
	   NewMod.Ninp     = Ninp
	   NewMod.Nout     = Nout
	   NewMod.inp_type = inp
	   NewMod.out_type = out
	   NewMod.Descr    = RetVal.descr
	   NewMod.ver      = RetVal.ver
           NewMod.init     = RetVal.init
           NewMod.time     = RetVal.time
           NewMod.rdpar    = 1		; NOTA: da aggiungere nella
					         ;       descrizione dei moduli
	   ModInfo = [ ModInfo,NewMod ]
	   ModMenu = [ ModMenu, mprefix+STRUPCASE(mods[i])+" - "+NewMod.Descr ]

      ENDFOR
      count =count+mod_count
      ModMenu= [ModMenu, '2\']
    ENDFOR
ENDIF

RETURN
END


;T+
; \subsubsection{Function: {\tt GetModule}}
;
;   The function returns the information structure of a given
;   module type.
;
;T-

FUNCTION GetModule, Spec

COMMON ModuleList, ListPtr, TypeList, Generic_dtype, IOcolors

Spec = STRLOWCASE(Spec)
aux=WHERE((*listPtr).Descr.type EQ Spec, cnt)
IF cnt GT 0 THEN ElmPtr = PTR_NEW((*ListPtr).Descr[aux[0]]) ELSE BEGIN
	PRINT, "The requested module (",Spec,") is not available!"
	PRINT, ""
	PRINT, "You ought to upgrade your Software Packages to the"
	PRINT, "latest version"
	END

	RETURN, ElmPtr
END


;T+
; \subsubsection{Procedure: {\tt mod\_list\_crea}}
; \label{modlistcreasect}
;
; The following procedure defines the data structure required for the
; management of the ``module list''.
;
; The routine builds a list of module by calling {\tt find\_mod\_info()} and
; then adds the two special modules (the {\tt combiner} and the {\tt FdbStop})
; at the end of the list.
;
; The module data are stored into an array of structures allocated
; in the heap.
;
; Each array element is described in the structure {\tt MOD\_INFO} defined
; below.
;
; \noindent
; {\bf Warning:} A table of input/output data types and corresponding handle
; color is coded statically in the following piece of code, so the code must
; be modified whenever a new data type is required by any newly defined module.
;
;T-

PRO MOD_LIST_CREA, path

COMMON ModuleList, ListPtr, TypeList, Generic_dtype, IOcolors

TypeList = [ '',      $ ; Null type
              'atm_t', $ ; Atmosphere type
              'gen_t', $ ; Generic type
              'img_t', $ ; image type
              'mim_t', $ ; multiple image type
              'src_t', $ ; Source type
              'wfp_t', $ ; propagated Wavefront type
              'mes_t', $ ; Centroiding meas. type
              'com_t', $ ; Commands type
              'stf_t', $ ; Structure Fct type
              'pws_t', $ ; power spectrum type
              'lnd_t'  $ ; LINC/NIRVANA data type
           ]

Generic_dtype = 2		; Set this to index of 'gen_t' into TypeList

IOcolors = [ [255,255,255], $ ; Null type
             [150,  0,  0], $ ; Atmosphere type
             [120,120,120], $ ; Generic type
             [  0,  0,255], $ ; image type
             [  0,  0,150], $ ; multiple image type
             [255,  0,255], $ ; Source type
             [255,255,  0], $ ; propagated Wavefront type
             [  0,150,  0], $ ; Centroiding meas. type
             [  0,255,255], $ ; commands type
             [255, 130, 0], $ ; Structure Fct type
             [  0, 80, 80], $ ; power spectrum type
             [200,  0,  0]  $ ; LINC/NIRVANA data type
           ]

					; Get list of info files

ModInfo = REPLICATE({MOD_INFO, type:'',                  $
                                Ninp:0,                   $
                                Nout:0,                   $
                                inp_type:['',''],         $
                                out_type:['',''],         $
                                init:0B,                  $
                                rdpar:0B,                 $
                                time:0B,                  $
                                ver:fix(0),               $
                                pkg:'',                   $
                                Descr:''                  }, 1 )

ModMenu=['1\Modules\ModMenuEvent']


find_mod_info,ModMenu,ModInfo,COUNT=cnt

			; Put Feedback-stop special module at the end of
                        ; the list
ModInfo[cnt].type     = 's*s'
ModInfo[cnt].Ninp     = 1
ModInfo[cnt].Nout     = 1
ModInfo[cnt].inp_type = ['gen_t']
ModInfo[cnt].out_type = ['gen_t']
ModInfo[cnt].Descr    = 'Feedback stop'
ModInfo[cnt].ver      = 0
ModInfo[cnt].init     = 0B
ModInfo[cnt].time     = 0B
ModInfo[cnt].pkg      = ''
ModInfo[cnt].rdpar    = 0B
ModMenu = [ModMenu, '2\S*S - feedback stop']

ModuleData = { Menu:ModMenu, Descr:ModInfo }

ListPtr = PTR_NEW(ModuleData,/NO_COPY)

END

