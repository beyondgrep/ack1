#!perl

use warnings;
use strict;

use Test::More tests => 1;

my @expected = split( /\n/, <<'END_OF_LINES' );
t/text/boy-named-sue.txt
t/text/freedom-of-choice.txt
t/text/shut-up-be-happy.txt
END_OF_LINES

my @files = qw( t/text );
my @args = qw( religion -i -a -v -l );
my $cmd = "$^X ./ack-standalone @args @files";
diag( $cmd );
my @results = `$cmd`;
chomp @results;

is_deeply( \@results, \@expected, 'No religion please' );
