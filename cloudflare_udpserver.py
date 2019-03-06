#!/usr/bin/env python

import


fd = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
fd.bind(("0.0.0.0", 65400)) # pin source port to reduce nondeterminism
fd.connect(("192.168.254.30", 4321))
while True:
    t1 = time.time()
    fd.sendmsg("\x00" * 32)
    fd.readmsg()
    t2 = time.time()
    print "rtt=%.3fus" % ((t2-t1) * 1000000)
