#!perl

use warnings;
use strict;

use Test::More tests => 1;

my @expected = split( /\n/, <<'END_OF_LINES' );
t/text/boy-named-sue.txt
t/text/freedom-of-choice.txt
t/text/shut-up-be-happy.txt
END_OF_LINES

my $file = 't/text';
my @args = qw( religion -i -a -v -l );
my @results = `$^X ./ack-standalone  @args $file`;
chomp @results;

is_deeply( \@results, \@expected, 'No religion please' );
