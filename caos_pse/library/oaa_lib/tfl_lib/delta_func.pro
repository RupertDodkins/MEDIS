; $Id: delta_func.pro,v 1.2 2002/03/14 11:49:10 riccardi Exp $

function delta_func, np, DOUBLE=double

if test_type(np, /INT, /LONG, N_ELEM=n_el) then $
  message, 'np must be integer or long'
if n_el ne 1 then $
  message, 'np must be a scalar'

if keyword_set(double) then y = dblarr(np) else y = fltarr(np)
y[0] = np

return, y
end
