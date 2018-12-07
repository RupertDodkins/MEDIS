;T+
; \subsubsection{External Entry Point: RUN}
;
; The following procedure is used to run a project directly from the Worksheet.
; The command "RUN" can be used also in the CAOS Prompt typing 'RUN, "name_project"' 
;
;T-
; modified 20 june 2016: debugged for other OS than linux (use of !caos_env.exp_delim instead of ':')


pro run, project
npar=n_params()
if npar gt 0 then begin
;!PATH=EXPAND_PATH('+'+!caos_env.work+'Projects'+!caos_env.delim+project+!caos_env.delim)+':'+!PATH
!PATH=EXPAND_PATH('+'+!caos_env.work+'Projects'+!caos_env.delim+project+!caos_env.delim) $
                     +!caos_env.exp_delim+!PATH
resolve_routine,strlowcase(project)
ret=execute(strlowcase(project)+',"RP"')
endif else begin
; do nothing
endelse
end

