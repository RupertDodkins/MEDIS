; $Id: set_ps.pro,v 1.3 2003/06/10 18:29:27 riccardi Exp $

pro set_ps, filename, PORTRAIT=port
set_plot, 'ps'
if n_elements(filename) eq 0 then filename = dialog_pickfile(/WRITE)
if filename ne '' then $
    	device, LANDSCAPE=(not keyword_set(port)) $
    	      , /COLOR, BIT=8, FILE=filename
end

