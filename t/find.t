#!perl -Tw

use warnings;
use strict;

use Test::More tests => 2;

BEGIN {
    use_ok( 'App::Ack' );
}

PERL_FILES: {
    my @files;
    my $iter = App::Ack::interesting_files( sub { -f shift }, 1, 't/swamp' );

    while ( my $file = $iter->() ) {
        push( @files, $file ) if App::Ack::is_filetype( $file, "perl" );
    }

    is_deeply( [sort @files], [sort qw(
        t/swamp/Makefile.PL
        t/swamp/perl.pl
        t/swamp/perl.pm
        t/swamp/perl.pod
        t/swamp/perl-test.t
        t/swamp/perl-without-extension
    )] );
}
