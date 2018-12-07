;+
; MDS_STEP_RESP
;
;  resp = mds_step_resp(t, gamma, w0, ZERO_K=zero_k, DELAY=dT)
;
;   unit step responce of a mass-damper-spring system described by the
;   laplace transform:
;
;    (1-s*dT)*w0^2/(s^2+2*gamma*w0*s+w0^2)
;
;   for gamma<1 the returned responce is giben by
;
;    1-(w0/wd)*exp(-gamma*w0*t)*[cos(wd*t-theta)+dT*w0*sin(wd*t)]
;
;   where wd=w0*sqrt(1-gamma^2) and theta=arcsin(gamma).
;
;   For gamma>1 the responce is
;
;    1-[1/(t1-t2)]*[(dT+t1)*exp(-t/t1)-(dT+t2)*exp(-t/t2)]
;
;   where t1=[gamma+sqrt(gamma^2-1)]/w0 and t2=[gamma-sqrt(gamma^2-1)]/w0
;
;   For gamma==1 the responce is
;
;    1-exp(-t/t1)*[t1^2+t*(T+t1)]/t1^2
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
;   [t-dT-t1+exp(-t/t1)*(dT+t1)]/t1
;
;   where t1=m/c
;
;   TO BE WRITTEN case ZERO_K
;
;-
function mds_step_resp, t, gamma, w0, ZERO_K=zero_k, DELAY=dT

if n_elements(dT) eq 0 then dT=0.0
if keyword_set(zero_k) then begin
	if gamma eq 0 then begin
		return, 0.5*t*(t-2*dT)
	endif else begin
		t1=1/gamma
		return, (t-dT-t1+exp(-t/t1)*(dT+t1))/t1
	endelse
endif else begin
	case 1B of
		gamma gt 1: begin
			t1 = (gamma+sqrt(gamma^2-1))/w0
			t2 = (gamma-sqrt(gamma^2-1))/w0
			return, (t ge 0)*(1-(t1*exp(-t/t1)-t2*exp(-t/t2))/(t1-t2))
		end

		gamma lt 1: begin
			wd = w0*sqrt(1-gamma^2)
			theta = asin(gamma)
			return, (t ge 0)*(1-w0/wd*exp(-gamma*w0*t)*(cos(wd*t-theta)+dT*w0*sin(wd*t)))
		end

		gamma eq 1: begin
			return, (t ge 0)*t*exp(-w0*t)
		end

		else: message, "gamma must be greater then or equal to zero"
	endcase
endelse
end
