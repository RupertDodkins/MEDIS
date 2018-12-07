import sys
# from inspect import currentframe, getframeinfo
from inspect import getframeinfo, stack

def savelog(ap, cp, tp, sp, mp, iop):
    import pprint
    with open(iop.logfile, 'w') as the_file:
        for param in [ap, cp, tp, mp, sp]:
            the_file.write('\n', param)
            pprint.pprint(param.__dict__, the_file)

def progressBar(value, endvalue, bar_length=20):

    percent = float(value) / endvalue
    arrow = '-' * int(round(percent * bar_length)-1) + '>'
    spaces = ' ' * (bar_length - len(arrow))

    sys.stdout.write("\rProgress: [{0}] {1}%".format(arrow + spaces, int(round(percent * 100))))
    sys.stdout.flush()

def debug_program():
    import traceback
    class TracePrints(object):
        def __init__(self):
            self.stdout = sys.stdout

        def write(self, s):
            self.stdout.write("Writing %r\n" % s)
            traceback.print_stack(file=self.stdout)

    sys.stdout = TracePrints()



def dprint(message):
    caller = getframeinfo(stack()[1][0])
    print("%s:%d - %s" % (caller.filename, caller.lineno, message))
