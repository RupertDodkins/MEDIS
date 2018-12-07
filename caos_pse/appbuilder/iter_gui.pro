function iter_gui, default_iter

iter = default_iter
dummy = [ $
   '0, LABEL, ITERATIONS NUMBER settings, CENTER', $
   '1, BASE,,COLUMN,CENTER, FRAME', $
     '2, INTEGER,'+strtrim(iter,1)+', LABEL_LEFT=# iter:, WIDTH=12, TAG=it,', $
   '1, BASE,,ROW, CENTER', $
   '0, BUTTON, Run Project, QUIT, TAG=run']

a=CW_FORM(dummy, title='ITERATIONS', /COLUMN)

return, a.it

end