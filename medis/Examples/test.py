import numpy as np
from scipy.constants import codata
import matplotlib.pyplot as plt
np.set_printoptions(threshold=np.inf)

wienConstant = 2.897e-3

def planck(T, l):

    D = codata.physical_constants

    h = D['Planck constant'][0]
    k = D['Boltzmann constant'][0]
    c = D['speed of light in vacuum'][0]

    # calculate the Planck Law for a specific temperature and an array of wavelengths
    p = c*h/(k*l*T)
    result = np.zeros(np.shape(l))+1e-99
    # prevent underflow - compute only when p is "not too big"
    calcMe = np.where(p<700)
    result[calcMe] = (h*c*c)/(np.power(l[calcMe], 5.0) * (np.exp(p[calcMe])-1))
    return result

Tbody=np.array([300,7000])#np.arange(300, 12000, 2000)

Lpeak = wienConstant / Tbody

plot1 = plt.figure()
ax = plot1.add_subplot(111)

# compute Planck function for a range of wavelengths and temperatures:
for ti,T in enumerate(Tbody):
    # wavelengths used: from 0.1 * peak to 100* peak
    print Lpeak
    # Lvec = np.logspace(-1, 0.5, 500) * Lpeak[ti]  # wavelengths: 1 nm - 1 mm
    Lvec = np.arange(800, 1500, 5)*1e-9  # wavelengths: 1 nm - 1 mm
    r = planck(T, Lvec)
    print Lvec
    ax.plot(Lvec*1e9, r, label='T=%d'%T)

# create axes and labels
plotAs = 'linear' # set to 'log' for log plot
ax.set_xlabel('lambda (nm)')
ax.set_ylabel('radiance (W/sr/m^3)')
ax.set_title('Black body spectrum')
ax.legend()
# ax.set_xscale('log')
ax.set_yscale('log')
# ax.set_ylim (1e-8, 2.5e14)

plt.show()