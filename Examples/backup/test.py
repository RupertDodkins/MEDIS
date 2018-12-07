from multiprocessing import Process, Queue

def add_helper(queue, arg1, arg2): # the func called in child processes
    ret = arg1 + arg2
    queue.put(ret)

def multi_add(): # spawns child processes
    q = Queue()
    processes = []
    rets = []
    for _ in range(0, 100):
        p = Process(target=add_helper, args=(q, 1, 2))
        processes.append(p)
        p.start()
    for p in processes:
        ret = q.get() # will block
        rets.append(ret)
    for p in processes:
        p.join()
    return rets

if __name__ == '__main__':
    print multi_add()