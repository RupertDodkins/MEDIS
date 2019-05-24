import numpy as np

def sample_signal(n_samples, corr, mu=0, sigma=10):
    assert 0 < corr < 1, "Auto-correlation must be between 0 and 1"

    # Find out the offset `c` and the std of the white noise `sigma_e`
    # that produce a signal with the desired mean and variance.
    # See https://en.wikipedia.org/wiki/Autoregressive_model
    # under section "Example: An AR(1) process".
    c = mu * (1 - corr)
    # sigma_e = np.sqrt((sigma ** 2) * (1 - corr ** 2))
    sigma_e = 0.02
    print(corr, sigma_e)
    # Sample the auto-regressive process.
    signal = [c + np.random.normal(0, sigma_e)]
    for _ in range(1, n_samples):
        # if _ % 2.== 0:
        signal.append(c + corr * signal[-1] + np.random.normal(0, sigma_e) + 1.5 * corr * signal[-1])
        # dice = np.random.uniform()
        # # if dice < 0.1:
        # signal[-1] += 1.1 * corr * signal[-1] + np.random.normal(0, sigma_e/10)
        # print(len(signal))

    return np.array(signal)

def compute_corr_lag_1(signal):
    return np.corrcoef(signal[:-1], signal[1:])[0][1]

# Examples.
print(compute_corr_lag_1(sample_signal(5000, 0.5)))
print(np.mean(sample_signal(5000, 0.5, mu=2)))
print(np.std(sample_signal(5000, 0.5, sigma=3)))
import matplotlib.pylab as plt
from statsmodels.tsa.stattools import acf, acovf


def gaussian(x, mu, sig):
    return np.exp(-np.power(x - mu, 2.) / (2 * np.power(sig, 2.)))

Fs = 8000
f = 5
sample = 8000
# signal = sample_signal(5000, 0.5)
x = np.arange(sample)
signal = np.sin(2 * np.pi * f * x / Fs)
signal += np.sin(2 * np.pi * f * x / (2*Fs))
# signal = gaussian(np.arange(0,20,0.1), 10, 2) + gaussian(np.arange(0,20,0.1), 15, 20)
plt.plot(signal)
plt.figure()
plt.plot(acf(signal))
plt.figure()
plt.plot(acovf(signal))

# signal = sample_signal(5000, 0.2)
# signal = np.sin(np.arange(500))
# plt.figure()
# plt.plot(signal)
# plt.figure()
# plt.plot(acf(signal))
# plt.figure()
# plt.plot(acovf(signal))

plt.show()