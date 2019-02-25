"""
These modules were adapted from PROPER to enable a few features in MEDIS.

The original PROPER code can be found at

Code
https://sourceforge.net/projects/proper-library/ 07-2018

Publication
Krist, J.E., 2007, October. PROPER: an optical propagation library for IDL. In Optical Modeling and Performance
Predictions III (Vol. 6675, p. 66750P). International Society for Optics and Photonics.
"""

from .prop_dm import prop_dm
from .prop_run import prop_run
from .prop_psd_errormap import prop_psd_errormap