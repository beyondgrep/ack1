#!perl

use warnings;
use strict;

use Test::More tests => 5;

use lib 't';
use Util;

prep_environment();

my $ack = 'ack';

ok( -e $ack, 'exists' );
ok( -r $ack, 'readable' );
if ( is_win32() ) {
    pass( 'Skipping -x test for Windows' );
}
else {
    ok( -x $ack, 'executable' );
}

FIND_PACKAGES: {
    my @expected = map { "package $_;" } qw(
        File::Next
        App::Ack
        App::Ack::Plugin::Basic
        App::Ack::Repository
        App::Ack::Repository::Basic
        App::Ack::Resource
        App::Ack::Resource::Basic
    );
    my @files = ( $ack );
    my @args = qw( ^package -h );
    my @results = run_ack( @args, @files );

    sets_match( \@results, \@expected, 'Looking for packages' );
}
