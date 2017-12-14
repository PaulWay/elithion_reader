#!/usr/bin/perl -w

use warnings;
use strict;

my $format = 1;
my $marklines = ($ENV{LINES} / 2) || 25;
my $markcount = 0;
my $linepart = '--==--==--==--==--##';

my ($lastdate, $laststats);
my @field_states;

sub stats2fields {
    my ($stats) = @_;
    return map { hex($_) } unpack("A2"x(length($stats)/2), $stats);
}
sub update_field_states {
    while (my ($byte, $stat) = each @_) {
        $field_states[$byte][$stat]++;
    }
}
sub markline {
    return "---------- ---------------: " . 
           $linepart x int(scalar(@field_states) / 10) .
           substr($linepart, 0, (scalar(@field_states) % 10) * 2) .
           "\n";
}

while (<>) {
    chomp;
    my @line = split m{,};
    next unless scalar(@line) == 5;
    my ($date, $stats) = @line[0,3];
    # Fields are date, type, len, stats and checksum
    if (not $laststats) {
        # First line - collect last stats and continue
        print "$date: $stats\n";
        $lastdate = $date;
        $laststats = $stats;
        # Store initial stat states and count of 1
        my @fields = stats2fields($stats);
        @field_states = map { [ ] } 0..$#fields;
        update_field_states(@fields);
        if ($format == 1) {
            print markline();
        }
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
    # Increment state counts
    update_field_states(@fields);
    
    # We know we've got a difference now:
    if ($format == 0) {
        print "Change at $date:\n";
    } elsif ($format == 1) {
        $markcount ++;
        if ($markcount == $marklines) {
            print markline();
            $markcount = 0;
        }
        print "$date: ";
    }
    while (my ($bytepos, $field) = each @fields) {
        my $strpos = $bytepos * 2;
        if ($field != $lastfields[$bytepos]) {
            if ($format == 0) {
                printf "... byte %02d (at %02d in string) changed from %3d (%02X) to %3d (%02X)\n",
                 $bytepos, $strpos,
                 $lastfields[$bytepos], $lastfields[$bytepos],
                 $field, $field;
            } elsif ($format == 1) {
                printf "%02X", $field;
            }
        } else {
            if ($format == 1) {
                print '  ';
            }
        }
    }
    if ($format == 1) {
        print "\n";
    }
    $laststats = $stats;
    $lastdate = $date;
}

foreach my $byte (0..$#field_states) {
    printf "Byte %2d states: %s\n",
     $byte, join(', ', 
        map { sprintf "%03d/%02X (*%d)", $_, $_, $field_states[$byte][$_] }
        grep { defined $field_states[$byte][$_] }
        (0..255)
     );
}
