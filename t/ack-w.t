#!perl

use warnings;
use strict;

use Test::More tests => 1;
delete $ENV{ACK_OPTIONS};

use lib 't';
use Util;

DASH_W: {
    my @expected = (
        '34:And I said: "My name is Sue! How do you do! Now you gonna die!"',
        '70:Bill or George! Anything but Sue! I still hate that name!',
    );

    my @files = qw( t/text );
    my @args = qw( Sue! -w --text );
    my $cmd = "$^X ./ack-standalone @args @files";
    my @results = `$cmd`;
    chomp @results;

    sets_match( \@results, \@expected, 'Looking for Sue!' );
}

