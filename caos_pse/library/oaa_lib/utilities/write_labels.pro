; $Id: write_labels.pro,v 1.3 2002/12/04 14:49:38 riccardi Exp $

;+
;    WRITE_LABELS
;
;    WRITE_LABELS, Label_file
;
;    Label_file: name of the file where store coordinates and labels in.
;
; History
;
;   Sometime, created by A. Riccardi, Osservatorio astrofisico di Arcetri (Italy)
;   21 Oct, 2002 - free_lun is used instead of close
;
;-
pro write_labels, label_file
	openw, unit, label_file, /get_lun

	print, 'Type @ to exit'
	repeat begin
		cursor, x, y, /down
		strout=strarr(1)
		read, strout

		if (strout(0) eq '@') then begin
			free_lun, unit
			return
		endif

		printf, unit, x, y, strout
		xyouts, x, y, strout
	endrep until (0 eq 1)
end

