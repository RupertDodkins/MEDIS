Recommended steps in order to use the xxx template:
---------------------------------------------------

0- Read the header comments of routines (starting from routine "xxx.pro")
to have a general idea of how is organized a module.

1- Modify xxx_info.pro first, defining the general features of your module.

2- Modify then xxx_gen_default.pro and xxx_gui.pro, defining the parameters
   of the module.

3- Hence modify xxx.pro, where calling of initialization routine xxx_init and
   normal running routine xxx_prog is. This routine is also the place where
   time integration and time delay are managed.

4- Modify xxx_init.pro, where the quantities computed just once are made, and
   where controls are made.

5- Adapt routine xxx_prog.pro introducing the scientific code. Within this routine
   you will have to deal with the status (valid, not_valid, wait) of the input and
   the subsequent behavior of the present routine.

NB:
- the subdirectory xxx_lib is used to store possible subroutines of xxx.pro,
  xxx_init.pro, and xxx_prog.pro.
- the subdirectory xxx_gui_lib is used to store possible subroutines
  of xxx_gui.pro.
- the subdirectory xxx_data is used to store possible data used by some of the
  routines of the module.
