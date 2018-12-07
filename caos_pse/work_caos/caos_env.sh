# parent lib directory path definition
export CAOS_ROOT="/Data/PythonProjects/MEDIS/caos_pse"

# parent working directory path definition
export CAOS_WORK="/Data/PythonProjects/MEDIS/caos_pse/work_caos"

# startup file path definition
export IDL_STARTUP="/Data/PythonProjects/MEDIS/caos_pse/work_caos/caos_startup.pro"

# IDL/X11 problem...
export IDL_GR_X_RENDERER=1

# X11 'dsm not idl' solution added by R. Dodkins
export DYLD_LIBRARY_PATH=/opt/X11/lib/flat_namespace:$DYLD_LIBRARY_PATH

#echo $IDL_PATH
#IDL_PATH=$IDL_PATH:/Data/PythonProjects/MKIDCoronSim/caos_pse/library
#IDL_PATH=$IDL_PATH:/Data/PythonProjects/MKIDCoronSim/caos_pse/appbuilder
#IDL_PATH=$IDL_PATH:/Data/PythonProjects/MKIDCoronSim/caos_pse/packages
#echo $IDL_PATH