#!perl

use warnings;
use strict;

use Test::More tests => 1;
delete $ENV{ACK_OPTIONS};

use lib 't';
use Util;

TRAILING_PUNC: {
    my @expected = (
        'And I said: "My name is Sue! How do you do! Now you gonna die!"',
    );

    my @files = qw( t/text );
    my @args = qw( Sue! -1 -h --text );
    my $cmd = "$^X ./ack-standalone @args @files";
    my @results = `$cmd`;
    chomp @results;

    sets_match( \@results, \@expected, 'Looking for first instance of Sue!' );
}
