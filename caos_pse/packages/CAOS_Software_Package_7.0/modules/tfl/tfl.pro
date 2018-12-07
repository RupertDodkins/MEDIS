; $Id: tfl.pro,v 7.0 2016/05/19 marcel.carbillet $
;+
; NAME:
;    tfl
;
; ROUTINE'S PURPOSE:
;    tfl manages the simulation for the Time FiLtering (TFL) module,
;    that is:
;       1-call the module's initialisation routine tfl_init at the first
;         iteration of the simulation project
;       2-call the module's program routine tfl_prog otherwise, managing
;         at the same time the possible time integration/delay.
;
; PURPOSE:
;    "tfl.pro" executes the simulation for the Time FiLtering (TFL) module:
;    it allows to apply a different discrete recursive filter for
;    each element (degree of freedom or DOF) of a time-variable vector of
;    input commands. The discrete filter is obtained by the
;    discretization of a rational analog filter used as prototype.
;    In the current release, the discretization of the prototype
;    filter is obtained applying the bilinear (Tustin) transform
;    [Oppenheim & Schafer, 1989, sec. 7.1.2] to the analog filter
;    tranfer function.
;
;    The parameters associated to an instance of the module TFL can be
;    set with the use of the Grafical User Intergace (GUI) called by
;    the TFL_GUI function. It allows the user to choose if defining
;    the same filter for all the DOF of the input command vector or a
;    different one for each DOF. In both the cases the analog filter
;    prototype can be defined in the GUI entering the data
;    associated to one of following parametric description of 
;    its Laplace Transfer Function (TF):
;
;     a) "Pure Integrator"; a single pole @ 0Hz with a user defined
;                           gain G:
;                                       TF(s) = G/s
;
;                           G >= 0.
;
;     b) "Proportional-Integrator-Derivative (PID)";
;                           the linear combination of a proportional, an
;                           integrator, and a derivative filter with
;                           user defined gains K_p, K_i and K_d
;                           respectively:
;
;                                              1            A      
;                         TF(s) = K_p + K_i * --- + K_d * ----- * s
;                                              s           s+A     
;
;                           K_p, K_i, K_d >= 0;  A > 0 (when K_d ne 0).
;
;                           The user can also define the cut frequency 
;                           A of the low-pass correction of the
;                           derivative portion of the filter for noise
;                           filtering purposes.
;
;    c) "Gain-Zeros-Poles (GZP)"; a more general representation of a
;                           rational filter transfer function in terms 
;                           of user defined gain G, zeros z[i], and
;                           poles p[j]:
;
;                                  (s+z[0])*(s+z[1])*...*(s+z[nz-1])
;                      TF(s) = G * ---------------------------------
;                                  (s+p[0])*(s+p[1])*...*(s+p[np-1])
;
;                           nz, np <= 4, G >= 0, real z[i], and real p[j]
;                                                ^^^^           ^^^^
;
;    The software allows to load the filter parameters from an ASCII
;    file. Only the GZP parametrization is allowed in this case. See
;    the file .../modules/tfl/tfl_data/filter_data.dat for more informations.
;
;    Because of the modular structure of the package, the data input
;    rate (in terms of samples per second) is not defined until the 
;    parameters of the other modules are defined and the project is
;    initialized, hence the filter data, like zero or pole
;    frequencies, are entered using the sampling frequency
;    (w_samp=2*pi/T) as a free parameter.
;    As instance the GZP representation can be rewitten as:
;
;                         (s/w_samp+z[0]/w_samp)*...*(s/w_samp+z[nz-1]/w_samp)
;TF(s)=G*(2*pi/T)^(nz-np)*----------------------------------------------------
;                         (s/w_samp+p[0]/w_samp)*...*(s/w_samp+p[np-1]/w-samp)
;
;    the values for z[i]/w_samp, p[j]/w_samp and G/T^(nz-np) are
;    requested in the GUI.
;    In order to help the user in the filter definition, the Bode
;    plots and the recursive filter implementation are displayed.
;
;    The gain is always entered as positive values, to simulate the
;    effect of a 'negative feedback' select the check-button 'Negative 
;    Feedback' in the GUI.
;
;
; CATEGORY:
;       main module's routine
;
; CALLING SEQUENCE:
;       error = tfl(          $
;                  inp_com_t, $
;                  out_com_t, $
;                  par,       $
;                  INIT=init, $
;                  )
;
; OUTPUT:
;       error: long scalar (error code, see !caos_error var in caos_init.pro).
;
; INPUTS:
;       inp_com_t: structure of type com_t:
;                   {data_type  : "com_t",                 $
;                    data_status: !caos_data.xxx,           $ see caos_init 
;                    command    : fltarr(n_actuators),     $ commands to filter
;                    pass_mat   : mode -> actuator matrix, $ 
;                    tam_ssap   : actuator -> mode matrix  $
;                   }
;
;       par      : vector of parameter structures from tfl_gui:
;      { tfl,                      $ ; structure named TFL
;        module     : module,      $ ; standard module description structure
;        max_n_coeff: max_n_coeff, $ ; max number of allowed coeffs
;        s_const    : s_const,     $ ; constant factor of the s-domain filt. tf
;        n_s_zero   : n_s_zero,    $ ; number of zeros of the s-domain filt. tf
;        n_s_pole   : n_s_pole,    $ ; number of poles of the s-domain filt. tf
;        s_zero     : s_zero,      $ ; zeros of the s-domain filter tf 
;        s_pole     : s_pole,      $ ; poles of the s-domain filter tf
;        type       : type,        $ ; filter type, usefull for the gui
;        method     : method,      $ ; chosen method index from the method list
;        double     : double       $ ; coeffs precision: 0B single, 1B double
;      }
;
; INCLUDED OUTPUTS:
;       out_com_t: structure of type com_t.
;                   {data_type  : "com_t",                 $
;                    data_status: !caos_data.xxx,          $ see caos_init 
;                    command    : fltarr(n_actuators),     $ filtered commands
;                    pass_mat   : mode -> actuator matrix, $ 
;                    tam_ssap   : actuator -> mode matrix  $
;                   }
;
; KEYWORD PARAMETERS:
;       INIT: named variable undefined or containing a scalar
;             when tfl is called for the first time. As output
;             the named variable will contain
;             a structure of the initialization data. For the
;             following calls of tfl, the keyword INIT has to
;             be set to the structure returned by the first call.
;
; COMMON BLOCKS:
;       common caos_block, tot_iter, this_iter
;
;       tot_iter   : int scalar. Total number of iteration during the
;                    simulation run.
;       this_iter  : int scalar. Number of the current iteration. It is
;                    defined only while status eq !caos_status.run.
;                    (this_iter >= 1).
;
;
; SIDE EFFECTS:
;       none.
;
; RESTRICTIONS:
;       none.
;
; CALLED NON-IDL FUNCTIONS:
;       tustin.pro
;       gzp2pid.pro
;       pid2gzp.pro
;       plot_amp.pro
;       plot_phase.pro
;       poly_mult.pro
;       poly_pow.pro
;       poly_sum.pro
;       recursive_sf.pro
;       tustin.pro
;       zero2coeff.pro
;
; ROUTINE MODIFICATION HISTORY:
;       program written: march 1999,
;                        Armando Riccardi (OAA) [riccardi@arcetri.astro.it].
;       modifications  : Nov 1999,
;                        B. Femenia   (OAA) [bfemenia@arcetri.astro.it]
;                       -adapted to new version CAOS (v 2.0).
;                      : january 2003,
;                        Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                       -use of variable "calibration" eliminited for version 4.0
;                        of the whole CAOS Software System.
;                      : february 2004,
;                        Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                       -help upgraded.
;                      : may 2016,
;                        Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                       -adapted to Soft. Pack. CAOS 7.0.
;
; MODULE MODIFICATION HISTORY:
;       module written : Armando Riccardi (OAA) [riccardi@arcetri.astro.it].
;       modifications  : for version 2.0,
;                        B. Femenia   (OAA) [bfemenia@arcetri.astro.it]
;                       -adapted to new version CAOS (v 2.0).
;                      : for version 4.0,
;                        Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                       -no more use of the common variable "calibration" and
;                        the tag "calib" (structure "info") for version 4.0 of
;                        the whole CAOS Software System.
;                      : for version 7.0,
;                        Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                       -adapted.
;-
;
FUNCTION tfl, inp_com_t, $      ; input structure
              out_com_t, $      ; output structure
              par,       $      ; parameters from tfl_gui
              INIT=init         ; initialization structure

COMMON caos_block, tot_iter, this_iter


error = !caos_error.ok          ; Init error code: no error as default


IF (this_iter EQ 0) THEN BEGIN  ; INITIALIZATION 
                                ;===============
   error= tfl_init(inp_com_t, $
                   out_com_t, $
                   par,       $
                   INIT=init)

ENDIF ELSE BEGIN                ; NORMAL RUNNING: TFL does not consider
                                ;===============  integration nor delay
   error= tfl_prog(inp_com_t, $
                   out_com_t, $
                   par,       $
                   INIT=init)
ENDELSE 

return, error                   ; back to calling program.

END
