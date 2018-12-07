; $Id: linfitxy.pro,v 1.2 2002/03/14 11:49:13 riccardi Exp $

function linfitxy, x, y, chisqr = chisqr, prob = prob, $
			sdevx = sdevx, sdevy = sdevy, sig_ab = sig_ab, $
			eps=eps, max_iter=max_iter

  on_error, 2

  nsdevx = n_elements(sdevx)
  nx = n_elements(x)

  if nsdevx eq 0 then begin
	coeff = linfit(x, y, chisqr = chisqr, prob = prob, sdev = sdevy, $
			sig_ab = sig_ab)
	return, coeff
  endif else if nsdevx eq nx then begin
	coeff = linfit(x, y)
	if n_elements(sdevy) eq 0 then sdevy=0
	if n_elements(eps) eq 0 then eps=1e-3
	if n_elements(max_iter) eq 0 then max_iter=30
  	for i=1,max_iter do begin
	  sdev = sqrt(sdevy^2+(coeff(1)*sdevx)^2)
	  new_coeff=linfit(x, y, chisqr = chisqr, prob = prob, sdev = sdev, $
	  				sig_ab = sig_ab)
	  if total(abs((new_coeff-coeff)/coeff) lt eps) eq 2 then $
		return, new_coeff
	  coeff = new_coeff
	endfor
  endif else $
	message, 'x and sdevx must be vectors of equal length.'

  print, "Warning: Iteration method hasn't converged!"
  return, new_coeff
end
