#!perl

use warnings;
use strict;

use Test::More tests => 4;
delete $ENV{ACK_OPTIONS};

use IPC::Open3;

my $ack = 'ack-standalone';

ok( -e $ack, 'exists' );
ok( -r $ack, 'readable' );
if ( $^O eq 'MSWin32' ) {
    pass( 'Skipping -x test for Windows' );
}
else {
    ok( -x $ack, 'executable' );
}

my $pid = open3( my $wh, my $rh, undef,
                    $^X, $ack, 'package', $ack );

my @actual = <$rh>;
s/\r?\n$// for @actual;
s/^\d+:// for @actual;

my @expected = (
    'package File::Next;',
    'package App::Ack;',
);
is_deeply( \@actual, \@expected, 'Got expected output' );
