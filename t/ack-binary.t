#!perl

use warnings;
use strict;

use Test::More tests => 4;
use App::Ack ();
use File::Next ();

use lib 't';
use Util;

prep_environment();

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


ACK_BINARY: {
    my @expected = (
        'Binary file t/swamp/moose-andy.jpg matches',
    );

    my @files = qw( t/swamp );
    my @args = qw( -a sRGB );
    my @results = run_ack( @args, @files );

    lists_match( \@results, \@expected, 'Looking for binary' );
}
