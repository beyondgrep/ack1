#!perl

use warnings;
use strict;

use Test::More tests => 4;
use lib 't';
use Util;

delete $ENV{ACK_OPTIONS};

my $ack = 'ack-standalone';

ok( -e $ack, 'exists' );
ok( -r $ack, 'readable' );
if ( $^O eq 'MSWin32' ) {
    pass( 'Skipping -x test for Windows' );
}
else {
    ok( -x $ack, 'executable' );
}

FIND_PACKAGES: {
    my @expected = (
        'package File::Next;',
        'package App::Ack;',
    );
    my @files = ( $ack );
    my @args = qw( ^package -h );
    my @results = run_ack( @args, @files );

    lists_match( \@results, \@expected, 'Looking for packages' );
}
