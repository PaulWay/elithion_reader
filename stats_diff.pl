#!/usr/bin/perl -w

use warnings;
use strict;

my ($lastdate, $laststats);

sub stats2fields {
    my ($stats) = @_;
    return map { hex($_) } unpack("A2"x(length($stats)/2), $stats);
}

while (<>) {
    chomp;
    my @line = split m{,};
    next unless scalar(@line) == 5;
    my ($date, $stats) = @line[0,3];
    # Fields are date, type, len, stats and checksum
    if (not $laststats) {
        # First line - collect last stats and continue
        print "At $date, line was $stats\n";
        $lastdate = $date;
        $laststats = $stats;
        next;
    }
    if ($stats eq $laststats) {
        # Same as last line - ignore.
        next;
    }
    if (length($stats) != length($laststats)) {
        warn "Warning: Stats for $date changed length as well as content from $lastdate\n";
    }
    # Split last and this stats into fields
    my @lastfields = stats2fields($laststats);
    my @fields = stats2fields($stats);
    
    # We know we've got a difference now:
    print "Change at $date:\n";
    foreach my $bytepos (0..$#fields) {
        my $bytenum = $bytepos + 1;
        my $strpos = $bytepos * 2;
        if ($fields[$bytepos] != $lastfields[$bytepos]) {
            printf "... byte %02d (at %02d in string) changed from %3d (%02X) to %3d (%02X)\n",
             $bytenum, $strpos,
             $lastfields[$bytepos], $lastfields[$bytepos],
             $fields[$bytepos], $fields[$bytepos];
        }
    }
    $laststats = $stats;
    $lastdate = $date;
}
