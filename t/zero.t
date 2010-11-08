#!perl

use warnings;
use strict;

use Test::More tests => 4;
use File::Next 0.22;

use lib 't';
use Util;

prep_environment();

BEGIN {
    use_ok( 'App::Ack' );
}

my $swamp = 't/swamp';

my @actual_swamp_perl = map { "$swamp/$_" } qw(
    0
    Makefile.PL
    options.pl
    perl.cgi
    perl.pl
    perl.pm
    perl.pod
    perl-test.t
    perl-without-extension
);

HANDLE_ZEROES: {
    my $iter =
        File::Next::files( {
            file_filter => sub { return is_filetype( $File::Next::name, 'perl' ) }, ## no critic
            descend_filter => \&App::Ack::ignoredir_filter,
        }, $swamp );

    my @files = slurp( $iter );

    sets_match( \@files, \@actual_swamp_perl, 'HANDLE_ZEROES' );
}


DASH_F: {
    my @args = qw( -f --perl );
    my @results = run_ack( @args, $swamp );

    sets_match( \@results, \@actual_swamp_perl, 'DASH_F' );
}
