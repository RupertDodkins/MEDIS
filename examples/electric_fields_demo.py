import numpy as np
from proper_mod import prop_run
from medis.params import iop, sp, cp, ap, tp
from medis.Utils.plot_tools import grid

iop.update("Electric_fields/")
sp.save_locs = np.array([['add_atmos',], ['quick_ao',], ['prop_mid_optics',], ['coronagraph']])

phase_ind = [True, True, False, False]

wsamples = np.linspace(ap.band[0], ap.band[1], ap.nwsamp) / 1e9

titles = np.vstack((wsamples,wsamples)).reshape((-1,),order='F')  # interleave two arrays because grid indexes down the
                                                                  # columns then the rows as oopsed to vice versa
print(titles)

if __name__ == '__main__':
    for t in range(10):
        r0 = 0.2
        atmos_map = iop.atmosdir + '/telz%f_%1.3f.fits' % (t * cp.frame_time, r0)
        kwargs = {'iter': t, 'atmos_map': atmos_map, 'params': [ap, tp, iop, sp]}
        _, selec_E_fields = prop_run('medis.Telescope.optics_propagate', 1, ap.grid_size, PASSVALUE=kwargs,
                                     PHASE_OFFSET=1)
        print('The E field matrix has shape {}'.format(selec_E_fields.shape))
        show = False
        for surf in range(len(sp.save_locs)):
            if surf == len(sp.save_locs)-1: show = True

            if phase_ind[surf]:
                grid(np.angle(selec_E_fields[surf], deg=False).reshape(6, ap.grid_size,ap.grid_size),
                     nrows=2, show=show, titles=titles)
            else:
                grid(np.absolute(selec_E_fields[surf]).reshape(6, ap.grid_size,ap.grid_size),
                     nrows=2, show=show, titles=titles)
