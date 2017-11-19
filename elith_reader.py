#!/usr/bin/env python

import re
import datetime
import serial
import time

device_name = '/dev/ttyUSB0'
read_delay = 5 # seconds

dev = serial.Serial(device_name, 57600, timeout=5, xonxoff=False, rtscts=False)

hb = r'[0-9A-F]{2}'
line_re = re.compile(
    r'\|(?P<type>[qrstvx])' +
    r'(?P<len>' + hb + r')' +
    r'(?P<data>(?:' + hb + r')+)' +
    r'(?P<csum>' + hb + r')\|'
)

max_tries = 10
while True:
    dev.write('v')
    buf = ''
    match = None
    tries = 0
    while not (found or tries == max_tries):
        buf += dev.read(255)
        match = line_re.search(buf)
        tries += 1

    if tries == max_tries:
        print "Gave up after {n} tries, got {b}".format(n=max_tries, b=buf)
        break
    
    print ','.join(
        datetime.datetime.now().isoformat(),
        match.group('type'),
        match.group('len'),
        match.group('data'),
        match.group('csum'),
    )
    
    time.sleep(read_delay)
