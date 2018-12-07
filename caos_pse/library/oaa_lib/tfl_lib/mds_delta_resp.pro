;+
; MDS_DELTA_RESP
;
;   responce of a mass-damper-spring system to a delta . The system is
;   described by the laplace transform:
;
;    (1-s*dT)*w0^2/(s^2+2*gamma*w0*s+w0^2)
;
;   for gamma<1 the returned responce is giben by
;
;    (w0^2/wd)*exp(-gamma*w0*t)*[sin(wd*t)+dT*w0*cos(wd*t+theta)]
;
;   where wd=w0*sqrt(1-gamma^2) and theta=arcsin(gamma).
;
;   For gamma>1 the responce is
;
;    [1/(t1-t2)]*[(dT+t1)/t1*exp(-t/t1)-(dT+t2)/t2*exp(-t/t2)]
;
;   where t1=[gamma+sqrt(gamma^2-1)]/w0 and t2=[gamma-sqrt(gamma^2-1)]/w0
;
;   For gamma==1 the responce is
;
;    exp(-t/t1)*[-dT*t1+t*(T+t1)]/t1^3
;
;   where t1=1/w0
;
; responce = mds_step_resp(t, gamma, w0)
;
;   considering w0=sqrt(k/m) and gamma=c/[2*sqrt(k*m)] if k->0 then w0=0
;   and gamma->infinity. To handle this case set the keyword ZERO_K, and
;   gamma=c/m (w0 is not considered)
;
;   in this case the laplace transform is:
;
;   (s*dT+1)/[s*(s+c/m)]
;
;   and the step responce:
;
;   1-exp(-t/t1)*(dT+t1)/t1
;
;   where t1=m/c
;
;   TO BE WRITTEN case ZERO_K
;
;-
function mds_delta_resp, t, gamma, w0, ZERO_K=zero_k, DELAY=dT

if n_elements(dT) eq 0 then dT=0.0
if keyword_set(zero_k) then begin
	if gamma eq 0 then begin
		return, t-T
	endif else begin
		t1=1/gamma
		return, 1-exp(-t/t1)*(dT+t1)/t1
	endelse
endif else begin
	case 1B of
		gamma gt 1: begin
			t1 = (gamma+sqrt(gamma^2-1))/w0
			t2 = (gamma-sqrt(gamma^2-1))/w0
			return, (t ge 0)*((dT+t1)/t1*exp(-t/t1)-(dT+t2)/t2*exp(-t/t2))/(t1-t2)
		end

		gamma lt 1: begin
			wd = w0*sqrt(1-gamma^2)
			theta = asin(gamma)
			return, (t ge 0)*(w0^2/wd)*exp(-gamma*w0*t)*(sin(wd*t)+dT*w0*cos(wd*t+theta))
		end

		gamma eq 1: begin
			return, (t ge 0)*t*exp(-w0*t)
		end

		else: message, "gamma must be greater then or equal to zero"
	endcase
endelse
end
