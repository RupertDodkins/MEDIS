from functools import wraps
import errno
import os
import signal
import time

class TimeoutError(Exception):
    pass

def timeout(seconds=10, error_message=os.strerror(errno.ETIME)):
    def decorator(func):
        def _handle_timeout(signum, frame):
            raise TimeoutError(error_message)

        def wrapper(*args, **kwargs):
            signal.signal(signal.SIGALRM, _handle_timeout)
            signal.alarm(seconds)
            try:
                result = func(*args, **kwargs)
            finally:
                signal.alarm(0)
            return result

        return wraps(func)(wrapper)

    return decorator

@timeout(3)
def f():
    time.sleep(4)
    print 3333
@timeout(seconds = 10)
def g():
    time.sleep(3)
    print 44444

if __name__ == "__main__":
    try:
        b = f()    
    except:
        print "Timer expired"

    try:
        b = g()    
    except:
        print "Timer expired"
    
