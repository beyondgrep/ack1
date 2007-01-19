#!perl -Tw

use warnings;
use strict;

use Test::More tests => 2;
use File::Next 0.22;

use lib 't';
use Util;

BEGIN {
    use_ok( 'App::Ack' );
}

# NOTE!  This block does a chdir.  If you add more tests after it, you
# may be sorry.

HANDLE_ZEROES: {
    chdir 't/swamp' or die "Can't chdir";

    my $iter =
        File::Next::files( {
            file_filter => sub { return is_filetype( $File::Next::name, 'perl' ) }, ## no critic
            descend_filter => \&App::Ack::skipdir_filter,
        }, '.' );

    my @files = slurp( $iter );

    sets_match( \@files, [qw(
        0
        Makefile.PL
        perl.cgi
        perl.pl
        perl.pm
        perl.pod
        perl-test.t
        perl-without-extension
    )], 'PERL_FILES' );
}
