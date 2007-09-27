#!perl -w

use warnings;
use strict;

use Test::More tests => 3;
use File::Next 0.22;

delete @ENV{qw( ACK_OPTIONS ACKRC )};

use lib 't';
use Util;

BEGIN {
    use_ok( 'App::Ack' );
}

# NOTE!  This block does a chdir.  If you add more tests after it, you
# may be sorry.
my $swamp = 't/swamp';
chdir $swamp or die "Unable to chdir to $swamp: $!\n";

my @actual_swamp_perl = qw(
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
            descend_filter => \&App::Ack::skipdir_filter,
        }, '.' );

    my @files = slurp( $iter );

    sets_match( \@files, \@actual_swamp_perl, 'HANDLE_ZEROES' );
}


DASH_F: {
    my @args = qw( -f --perl );
    my $cmd = "$^X -T ../../ack-standalone @args";
    my @results = `$cmd`;
    chomp @results;

    sets_match( \@results, \@actual_swamp_perl, 'DASH_F' );
}
