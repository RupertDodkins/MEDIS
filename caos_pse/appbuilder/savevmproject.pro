;T+
; \subsubsection{External Entry Point: SaveVmProject}
;
; The following routine is used to save the Virtualized version of a project
; onto disk.
;
; \noindent {\bf Note:} The {\tt SaveVmProject} function generates a
; file {\tt name_of_the_project.sav}. All parameter files are saved
; togheter with the ".sav" file routine.
;
;T-
; modified 20 june 2016: debugged for other OS than linux (use of !caos_env.exp_delim instead of ':')


pro savevmproject, project
!PATH=EXPAND_PATH('+'+!caos_env.work+'Projects'+!caos_env.delim+project+!caos_env.delim)+!caos_env.exp_delim+!PATH
resolve_routine,strlowcase(project)
resolve_all,/continue_on_error,/quiet;,skip_routines=['trnlog', 'setlog']
save,/routines,fi=!caos_env.work+'Projects'+!caos_env.delim+project+!caos_env.delim+strlowcase(project)+'.sav'
end