#!perl

use warnings;
use strict;

use Test::More tests => 1;
use App::Ack ();
use File::Next ();
delete $ENV{ACK_OPTIONS};

use lib 't';
use Util;


ACK_F: {
    my @expected = qw(
        t/etc/shebang.empty.xxx
        t/swamp/moose-andy.jpg
    );

    my @files = qw( t );
    my @args = qw( -f --binary );
    my @results = run_ack( @args, @files );

    sets_match( \@results, \@expected, 'Looking for binary' );
}
