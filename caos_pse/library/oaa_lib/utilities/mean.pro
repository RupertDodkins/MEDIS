; $Id: mean.pro,v 1.4 2006/12/01 13:45:01 labot Exp $

function mean, vector, STDEV=stdev

	return, (moment(vector, SDEV=stdev, /double))[0]
end
