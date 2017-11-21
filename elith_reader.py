#!/usr/bin/env python

import argparse
from datetime import datetime
from os import path
import re
import serial
import time

device_name = '/dev/ttyUSB0'
output_dir = '/home/pi/'
output_prefix = 'voltages.'
output_suffix = '.csv'

read_delay = 5 # seconds
max_tries = 10

hb = r'[0-9A-F]{2}'
line_re = re.compile(
    r'\|(?P<type>[qrstvx])' +
    r'(?P<len>' + hb + r')' +
    r'(?P<data>(?:' + hb + r')+)' +
    r'(?P<csum>' + hb + r')\|' + 
    r'(?P<rest>.*)$'
)

parser = argparse.ArgumentParser()
parser.add_argument(
    '--device', '-d', type=str, nargs='?', default=device_name, action='store',
    help='the device to read from'
)
parser.add_argument(
    '--outdir', '-o', type=str, nargs='?', default=output_dir, action='store',
    help='the base directory to write output to'
)
args = parser.parse_args()
if args.device:
    device_name = args.device
if args.outdir:
    output_dir = args.outdir

def read_to_file(dev, outfile):
    while True:
        dev.write('v')
        buf = ''
        match = None
        tries = 0
        while not (match or tries == max_tries):
            buf += dev.read(255)
            match = line_re.search(buf)
            tries += 1
        
        if (tries == maxtries):
            print "Got no matching data, retrying command"
        else:
            outfile.write(','.join(
                datetime.now().isoformat(),
                match.group('type'),
                match.group('len'),
                match.group('data'),
                match.group('csum'),
            ), "\n")
            buf = match.group('rest')
        
        time.sleep(read_delay)


while True:
    if not path.exists(device_name):
        print 'serial port device', device_name, 'not found, waiting...'
        time.sleep(1)
        continue
    
    dev = serial.Serial(device_name, 57600, timeout=5, xonxoff=False, rtscts=False)
    print "opened serial port", device_name
    
    outfile = open(
        output_dir + output_prefix + 
        datetime.now().strftime('%Y%m%d-%H%M%S') + output_suffix,
        'w'
    )

    try:
        read_to_file(dev, outfile)
    except serial.serialutil.SerialException:
        print "Got exception, aborting read"
        dev = None
    
    outfile.close()
