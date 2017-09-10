#!/usr/bin/perl -w

use warnings;
use strict;

# A program to read data from an attached eLithion Lithiumate Lite BMS
# and log its data.

# Written by Paul Wayper.  Licensed under the GNU GPL version 3.0.

# We wrap the serial port in an interface class that allows us to get
# data from it at regular intervals.  This allows a 'fake device' class
# to simulate talking to the device for testing.  The interface object
# provides methods for getting various statistics in decoded formats,
# which are then easy to write to an output file.

use Device::SerialPort;
use Getopt::Long;

# Configuration variables - set from the command line

my $in_device = '/dev/ttyUSB0';
my $out_dir = '/home/pi/elithion_logging';
my $charge_log_interval = 5;
my $run_log_interval = 1;
my $voltage_file = 'voltages.csv'
my $help;
my $fake_device = '';

GetOptions(
    'device|d=s'        => \$in_device,
    'fake-device|fd=s'  => \$fake_device,
    'help|h'            => \$help,
    'charge-interval|ic=i' => \$charge_log_interval,
    'run-interval|ir=i' => \$run_log_interval,
    'output-dir|o=s'    => \$output_dir,
    'voltage-file|vf=s' => \$voltage_file,
);

sub usage {
    print "Usage: $0 [-d device] [-o output_dir] [-vf voltage_file] ...
Options:
    -device | -d        device file to read and write
    -fake-device | fd   a fake device file to read and 'write'
    -charge-interval|ic seconds between reads/writes when charging
    -run-interval | ir  seconds betwween reads/writes when running
    -help | -h          this help
    -output-dir | -o    the directory to output files into
    -voltage-file | -vf the name of the voltages CSV file to write
";
    exit 0;
}

######################################################################
# Input device class
######################################################################

######################################################################
# Fake input device class
######################################################################

######################################################################
# Output encapsulation class
######################################################################

######################################################################
# Main code
######################################################################
if ($help) {
    usage();
}
