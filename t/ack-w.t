#!perl

use warnings;
use strict;

use Test::More tests => 1;
delete $ENV{ACK_OPTIONS};

use lib 't';
use Util;

DASH_W: {
    my @expected = (
        'And I said: "My name is Sue! How do you do! Now you gonna die!"',
        'Bill or George! Anything but Sue! I still hate that name!',
    );

    my @files = qw( t/text );
    my @args = qw( Sue! -w -h --text );
    my $cmd = "$^X ./ack-standalone @args @files";
    my @results = `$cmd`;
    chomp @results;

    sets_match( \@results, \@expected, 'Looking for Sue!' );
}

