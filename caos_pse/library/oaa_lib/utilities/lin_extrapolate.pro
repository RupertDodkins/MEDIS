; $Id: lin_extrapolate.pro,v 1.2 2002/03/14 11:49:13 riccardi Exp $

function lin_extrapolate, x, y
	n = n_elements(y)
	if (n_elements(x) le n) or (n lt 2) then stop

	return, (y(n-1)-y(n-2))/(x(n-1)-x(n-2))*(x(n)-x(n-1))+y(n-1)
end



