#!perl

use warnings;
use strict;

use Test::More tests => 4;

use IPC::Open3;

my $ack = 'ack-standalone';

ok( -e $ack, 'exists' );
ok( -r $ack, 'readable' );
ok( -x $ack, 'executable' );

my $pid = open3( my $wh, my $rh, undef,
                    $^X, $ack, 'package', $ack );

my @actual = <$rh>;
chomp @actual;
s/^\d+:// for @actual;

my @expected = (
    'package File::Next;',
    'package App::Ack;',
);
is_deeply( \@expected, \@actual, 'Got expected output' );
