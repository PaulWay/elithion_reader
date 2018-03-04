#!/usr/bin/perl -w

use warnings;
use strict;

# Export a CSV into InfluxDB

use InfluxDB;
use Time::Local;
use Time::HiRes qw{ time };
# The plan is to just upload everything into Influx, which means we can then pick
# and choose what to graph.  If this turns out to be infeasible, there's a config
# file in YAML we can read to pick just those columns.
# use YAML;

# For some reason the dates were one hour early on the pi until we fixed it.  This
# timestamp is when we fixed it.  Any timestamp read from a file that's earlier
# than this gets 3600 added to it.  At the moment this is 1 Jan 2019 - hopefully
# I'll have fixed this before then!
my $fudge_date_from = 1548939600;

my $ifxh = new InfluxDB(
    'host' => 'localhost', 'username' => 'elithion', 'password' => 'elithion',
    'database' => '3faze',
);

sub file_mod_time {
    my ($filename) = @_;
    return (stat($filename))[9];
}

sub date_to_tstamp {
    my ($date) = @_;
    # Dates in format '2017-12-13T16:04:29.004730'
    if ($date =~ m{(?P<yr>\d{4})-(?P<mon>\d{2})-(?P<day>\d{2})T(?P<hour>\d{2}):(?P<min>\d{2}):(?P<sec>\d{2}.\d+)}) {
        return timelocal(@+{qw{ sec min hr day mon yr }}) + 
            ($tstamp < $fudge_date_from) ? 3600 : 0;
    } else {
        warn "Warning: Couldn't parse $date into a timestamp\n";
        # Fudge - return now
        return time();
    }
}

sub read_file {
    my ($filename) = @_;
    (my $datatype = $filename) =~ s{^(\w+)\W.*?$}{\1};
    (my $stampname = $filename) =~ s{\.csv$}{.stamp};
    my $last_timestamp;
    # If we have a timestamp file, read it and get the last timestamp.
    if (-f $stampname) {
        # If the timestamp file is later than the csv file, the csv file
        # hasn't changed since being read.  Make should detect this but
        # we'll exit here anyway.
        if (file_mod_time($stampname) > file_mod_time($filename)) {
            return;
        }
        open my $ifh, '<', $stampname;
        $last_timestamp = <$ifh>; chomp $last_timestamp;
        close $ifh;
    }
    open my $ifh, '<', $filename;
    my @header;
    my @points;
    my %data = ( # The structure to eventually send to InfluxDB - do it in one go
        'name' => $datatype,
        'columns' => \@header,
        'points' => \@points,
    );
    while (<$ifh>) {
        chomp;
        my @line = split m{,};
        # Get the header and continue if we don't already have one
        if (not @header) {
            # The header has to have a date as the first field otherwise we can't
            # process it.
            if ($header[0] ne 'date') {
                warn "Warning: File '$filename' does not have date as first field in header - can't process.\n";
                close $ifh;
                return;
            }
            # Otherwise get the header and process the next line.
            @header = @line;
            $header[0] = 'time'; # For InfluxDB;
            next;
        }
        if (scalar @header != scalar @line) {
            warn "Warning: line '$_' different length to header\n";
            next;
        }
        # Convert first column into timestamp
        $line[0] = date_to_tstamp($line[0]);
        # If we got a timestamp from the file, and the timestamp is before
        # the stamp file's timestamp, then don't add this point.
        if ($last_timestamp and $line[0] <= $last_timestamp) {
            next;
        }
        # All good?  OK, push line data into points array.
        push @points, \@line;
    }
    close $ifh;
    # Now send the data to InfluxDB
    # And now write a timestamp file as the last data point we got from this file.
    open my $
}

foreach my ($file) (@ARGV) {
    read_file($file);
}
