#!/usr/bin/env python

import argparse
from datetime import datetime
from os import path
import re
import serial
import time

device_name = '/dev/ttyUSB0'
output_dir = '/home/pi/'
output_prefixes = {
    'q': 'q_stats',
    's': 'stats',
    't': 'temperatures',
    'v': 'voltages',
    'x': 'extended',
}
csv_suffix = '.csv'
raw_suffix = '.raw'

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
    '--device', '-d', type=str, default=device_name, action='store',
    help='the device to read from'
)
parser.add_argument(
    '--outdir', '-o', type=str, default=output_dir, action='store',
    help='the base directory to write output to'
)
parser.add_argument(
    '--read-delay', '-r', type=int, action='store', dest='readdelay', default=read_delay,
    help='the time between finishing one read and starting the next'
)
parser.add_argument(
    '--stats', '-s', type=str, action='store',
    default=''.join(sorted(output_prefixes.keys())),
    help='the type(s) of data to collect as a string of letters'
)
args = parser.parse_args()
device_name = args.device
output_dir = args.outdir
stats_to_read = args.stats
for stat in stats_to_read:
    if stat not in output_prefixes:
        print("Error: I need one of",
            ','.join(sorted(output_prefixes.keys())),
            "as a stat letter")
        exit
read_delay = args.readdelay

output_handles = {} # type -> handle, date

def output_type_data(type_, len_, data, csum):
    """
    Output one type of data to a file.  A new file is written each
    day.
    """
    # If date has rolled over, close old handle.
    now = datetime.now()
    if type_ in output_handles and output_handles[type_]['date'] < now.date():
        output_handles[type_]['handle'].close()
        del output_handles[type_]

    # If we (now) have no handle, open it
    outfile = None
    if type_ not in output_handles:
        outfile = open(
            output_dir + output_prefixes[type_] + '.' +
            now.strftime('%Y%m%d-%H%M%S') + csv_suffix,
            'a', False  # for no buffering
        )
        output_handles[type_] = {
            'handle': outfile,
            'date': now.date(),
        }
    else:
        outfile = output_handles[type_]['handle']

    outfile.write(','.join([
        now.isoformat(),
        type_, len_, data, csum,
    ]) + "\n")


def read_data(dev):
    """
    Continually read data until the serial port dies on us.
    """
    while True:
        for stat in stats_to_read:
            dev.write(stat + "\n")
            print "asked to read:", stat
            buf = ''
            match = None
            tries = 0
            while not (match or tries == max_tries):
                buf += dev.read(255)
                match = line_re.search(buf)
                tries += 1

            if (tries == max_tries):
                print "Got no matching data, retrying command"
            else:
                while match:
                    output_type_data(*match.group('type', 'len', 'data', 'csum'))
                    buf = match.group('rest')
                    print "got data for", match.group('type'), "at", datetime.now().isoformat(), "\r"
                    match = line_re.search(buf)
        
        time.sleep(read_delay)


while True:
    if not path.exists(device_name):
        print 'serial port device', device_name, 'not found, waiting...'
        time.sleep(1)
        continue
    
    dev = serial.Serial(device_name, 57600, timeout=1, xonxoff=False, rtscts=False)
    print "opened serial port", device_name
    
    try:
        read_data(dev)
    except serial.serialutil.SerialException:
        print "Got exception, aborting read"
        dev = None
