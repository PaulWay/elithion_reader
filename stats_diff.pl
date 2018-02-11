#!/usr/bin/perl -w

use warnings;
use strict;

my $format = 1;
my $marklines = ($ENV{LINES} / 2) || 25;
my $markcount = 0;
my $linepart = '--==--==--==--==--##';

my ($lastdate, $laststats);
my @field_states;
# Equal/up/down counts:
# in that order because <=> gives -1, 0 or 1 => array indices!
my @eud_counts;

# Here for convenience I'm numbering bytes from one; with a map to
# convert them back to zero-based offsets.
my @ignore_columns_extended =
    (5,  6, # seconds since on
     7,  8, # amps?
     9, 10, # amps?
    16, 17, # some more-or-less incrementing value
    21, 49, # matched 80/82
    24, 51, # matched 86/88
    68, 69, # amps
    72, 73, 74, 75 # amp-hours until charged
    );
my $ignore_columns = 0; # Set to 1 to ignore above columns.
my %ignore_bytes; if ($ignore_columns) {
    %ignore_bytes = map { $_ - 1 => 'ignore' } (@ignore_columns_extended);
}

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
        # Initialise equal-up-down counts
        @eud_counts = map { [ 0, 0, 0 ] } 0..$#fields;
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
        my $lastfield = $lastfields[$bytepos];
        $eud_counts[$bytepos][$field <=> $lastfield] ++;
        if ($field != $lastfield
          and not exists $ignore_bytes{$bytepos}
          ) {
            if ($format == 0) {
                $diff_lines .= sprintf
                 "... byte %02d (at %02d in string) changed from %3d (%02X) to %3d (%02X)\n",
                 $bytepos, $strpos,
                 $lastfield, $lastfield,
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
            print "Change at $date:\n$diff_lines";
        } elsif ($format == 1) {
            $markcount ++;
            if ($markcount == $marklines) {
                print markline();
                $markcount = 0;
            }
            print "$date: $diff_lines\n";
        }
    }

    # Finally store the last changed stats
    $laststats = $stats;
    $lastdate = $date;
}

foreach my $byte (0..$#field_states) {
    printf "Byte %2d states: %s\n",
     $byte+1, join(', ',
        map { sprintf "%03d/%02X (*%d)", $_, $_, $field_states[$byte][$_] }
        grep { defined $field_states[$byte][$_] }
        (0..255)
     );
    printf "... movements: %5d equal, %5d up, %5d down\n",
     @{ $eud_counts[$byte] };
}
