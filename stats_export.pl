#!/usr/bin/perl -w

use warnings;
use strict;

my $type = 'extended';

my %field_defs = (
    'extended' => [
        [ 'a',      's>' ],     # 01-02
        [ 'b',      's>' ],     # 03-04
        [ 'seconds_on', 'S>' ], # 05-06
        [ 'charge_a', 's>' ],   # 07-08
        [ 'charge_b', 's>' ],   # 09-10
        [ 'c',      's>' ],     # 11-12
        [ 'flag1',  'c' ],      # 13
        [ 'd',      'c' ],      # 14
        [ 'count1', 's>' ],     # 15-16
        [ 'flag2',  'c' ],      # 17
        [ 'e',      'c' ],      # 18
        [ 'ignore', 'x40' ],    # 19-58
        [ 'f',      'c' ],      # 59
        [ 'g',      'c' ],      # 60
        [ 'h',      'c' ],      # 61
        [ 'i',      'c' ],      # 62
        [ 'j',      'c' ],      # 63
        [ 'charge_c', 's>' ],   # 64-65
        [ 'charge_d', 's>' ],   # 66-67
        [ 'amps',   's>' ],     # 68-69
        [ 'k',      's>' ],     # 70-71
        [ 'amprs_down', 'L>' ], # 72-75
        [ 'l',      'c' ],      # 76
        [ 'flag3',  's>' ],     # 77-78
        [ 'flag4',  'c' ],      # 79
        [ 'flag5',  'c' ],      # 80
    ],
);

my $unpackformat = join(' ', map { $_->[1] } @{ $field_defs{$type} } );

print "Unpack format for $type = $unpackformat\n";

print join(',', 'date', grep { $_ ne 'ignore' } map { $_->[0] } @{ $field_defs{$type} } ), "\n";
while (<>) {
    chomp;
    my @fields = split m{,};
    my $bin = pack("H*", $fields[3]);
    print join(',', $fields[0], unpack($unpackformat, $bin)), "\n";
}
