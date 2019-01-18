from distutils.core import setup

setup(
    name='MEDIS',
    version='0.1',
    packages=['medis','medis/Analysis','medis/Atmosphere','medis/Detector','medis/speckle_nulling','medis/Telescope','medis/Utils'],
    license='Creative Commons Attribution-Noncommercial-Share Alike license',
    long_description=open('README.md').read(),
    url="https://github.com/RupertDodkins/MEDIS",
)
