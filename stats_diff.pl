#!/usr/bin/perl -w

use warnings;
use strict;

my $format = 1;
my $marklines = ($ENV{LINES} / 2) || 25;
my $markcount = 0;
my $linepart = '--==--==--==--==--##';

my ($lastdate, $laststats);
my @field_states;

# Here for convenience I'm numbering bytes from one; with a map to
# convert them back to zero-based offsets.
#my %ignore_bytes = map { $_ - 1 => 'ignore' }
#    (5, 6, # seconds since on
#    16, 17, # some more-or-less incrementing value
#    21, 49, # matched 80/82
#    24, 51, # matched 86/88
#    72, 73, 74, 75 # amp-hours until charged
#    );

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

    my $diff_lines = '';
    while (my ($bytepos, $field) = each @fields) {
        my $strpos = $bytepos * 2;
        if ($field != $lastfields[$bytepos]
          # and not exists $ignore_bytes{$bytepos}
          ) {
            if ($format == 0) {
                $diff_lines .= sprintf
                 "... byte %02d (at %02d in string) changed from %3d (%02X) to %3d (%02X)\n",
                 $bytepos, $strpos,
                 $lastfields[$bytepos], $lastfields[$bytepos],
                 $field, $field;
            } elsif ($format == 1) {
                $diff_lines .= sprintf "%02X", $field;
            }
        } else { # a byte that's the same or we're ignoring
            if ($format == 1) {
                $diff_lines .= '  ';
            }
        }
    }

    # We know we've got a difference now:
    if ($diff_lines !~ m{^\s+$}) {
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
        print $diff_lines;
        if ($format == 1) {
            print "\n";
        }
    }

    # Finally store the last changed stats
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
