import multiprocessing as mp
import tables as pt
import numpy as np

num_arrays = 100
num_processes = 4#mp.cpu_count()
num_simulations = 5


def Simulation(ii):
    result = []
    result.append(('createGroup', ('/', 't%s' % ii)))
    # for i in range(num_arrays):
    result.append(('createArray', ('/t%s' % ii, 'p%s' % ii, np.zeros((5,5)))))
    print result
    return result


def handle_output(result):
    hdf = pt.openFile('simulation.h5', mode='a')
    for args in result:
        method, args = args
        getattr(hdf, method)(*args)
    hdf.close()


# clear the file

def run(time):
    hdf = pt.openFile('simulation.h5', mode='w')
    hdf.close()
    pool = mp.Pool(num_processes)
    # for i in range(num_simulations):
    pool.apply_async(Simulation, (time,), callback=handle_output)
    pool.close()
    pool.join()
    print 'Done'

if __name__ == '__main__':
    time = 0
    run(time)