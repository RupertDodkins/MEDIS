;$Id
;+
; eps_r = air_relative_permittivity(h, T, P)
;
; the function returns the electric relative permittivity
; of the air as a function of relative humidity (h, 0 to 1),
; temperature (T [K]) and pressure (P [Pa])
;
; HISTORY
;
; Jul 2006 written by A. Riccardi, INAF-OAA
;-

function air_relative_permittivity, h, T, P

    ; LEGENDA
    ; T     absolute temperature [K]
    ; P     atmospheric pressure [Pa]
    ; rho_w density of the water vapour in the air [kg/m^3]
    ; x_w   molar fraction of the water vapour in the air [-]
    ; M_w   molar mass of the water vapour [kg/mole]
    ; nu    molar volume of the air [m^3/mole]
    ; R     universal gas constant []
    ; Z     compressibility factor of the air []
    ; h     relative humidity
    ; P_sv  sturated water vapour pressure attemperature T
    ; f     correcting factor which takes the difference of behaviour
    ;       of humid air from that of a perfect gas

    A   =  1.552d-6   ;[K*m^2/N]
    B   =  3.456d0    ;[K*m^3/kg]
    C   = -76.57d-6   ;[m^3/kg]
    R   =  8.314510d0 ;[J/mol/K]
    M_w =  0.018015d0 ;[kg/mol]

    tt = T-273.15d0

    P_sv = svp(tt)

    alpha = 1.00062d0
    beta  = 3.14d-8 ;1/Pa
    gamma = 5.6d-7  ;1/C^2
    f = alpha+beta*p+gamma*tt^2

    x_w = h*f*P_sv/P

    a0= 1.58123d-6 ;K/Pa
    a1=-2.9331d-8 ;1/pa
    a2= 1.1043d-10;1/K/Pa
    b0= 5.707d-6  ;K/Pa
    b1=-2.051d-8  ;1/Pa
    c0= 1.9898d-4 ;K/Pa
    c1=-2.376d-6  ;1/Pa
    d = 1.83d-11  ;K^2/Pa^2
    e =-0.765d-8  ;K^2/Pa^2
    Z = 1-(p/T)*(a0+a1*tt+a2*tt^2+(b0+b1*tt)*x_w+(c0+c1*tt)*x_w^2)+(p/T)^2*(d+e*x_w^2)

    nu=Z*R*T/P
    rho_w = x_w*M_w/nu

    return, 1+A*P/T+B*rho_w/T+C*rho_w
 end