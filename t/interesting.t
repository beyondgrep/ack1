#!perl -w

$|++;
use warnings;
use strict;

use Test::More tests => 7;
use File::Next 0.20;

BEGIN {
    use_ok( 'App::Ack' );
}

use Carp;

my $is_perl = sub { return App::Ack::is_filetype( $File::Next::name, 'perl' ) };
my $is_parrot = sub { return App::Ack::is_filetype( $File::Next::name, 'parrot' ) };

PERL_FILES: {
    my @files;
    my $iter = interesting_files( $is_perl, 1, 't/swamp' );

    while ( my $file = $iter->() ) {
        push( @files, $file );
    }

    is_deeply( [sort @files], [sort qw(
        t/swamp/Makefile.PL
        t/swamp/perl.pl
        t/swamp/perl.pm
        t/swamp/perl.pod
        t/swamp/perl-test.t
        t/swamp/perl-without-extension
    )], 'PERL_FILES' );
}

PERL_FILES_GLOBBED: {
    # We have to be able to handle starting locations that are files.
    my @files;
    my @starters = grep { !/blib/ } glob( 't/swamp/*' );
    my $iter = interesting_files( $is_perl, 1, @starters );

    while ( my $file = $iter->() ) {
        push( @files, $file );
    }

    is_deeply( [sort @files], [sort qw(
        t/swamp/Makefile.PL
        t/swamp/perl.pl
        t/swamp/perl.pm
        t/swamp/perl.pod
        t/swamp/perl-test.t
        t/swamp/perl-without-extension
    )], 'PERL_FILES_GLOBBED' );
}

PARROT_FILES_DESCEND: {
    my @files;
    my $iter = interesting_files( $is_parrot, 1, 't' );

    while ( my $file = $iter->() ) {
        push( @files, $file );
    }

    is_deeply( [sort @files], [sort qw(
        t/swamp/parrot.pir
        t/swamp/perl.pod
    )], 'PARROT_FILES_DESCEND' );
}

PARROT_FILES_NODESCEND: {
    my @files;
    my $iter = interesting_files( $is_parrot, 0, 't/swamp' );

    while ( my $file = $iter->() ) {
        push( @files, $file );
    }

    is_deeply( [sort @files], [sort qw(
        t/swamp/parrot.pir
        t/swamp/perl.pod
    )], 'PARROT_FILES_NODESCEND' );
}

PARROT_FILES_NODESCEND_EMPTY: {
    my @files;
    my $iter = interesting_files( $is_parrot, 0, 't/' );

    while ( my $file = $iter->() ) {
        push( @files, $file );
    }

    is_deeply( [@files], [], 'PARROT_FILES_NODESCEND_EMPTY' );
}

PERL_FILES_BY_NAME: {
    my @files;
    my $iter = interesting_files( $is_parrot, 0, 't/swamp/perl.pod' );

    while ( my $file = $iter->() ) {
        push( @files, $file );
    }

    is_deeply( [sort @files], [sort qw( t/swamp/perl.pod )], 'PERL_FILES_BY_NAME' );
}

sub interesting_files {
    my $file_filter = shift;
    my $descend = shift;
    my @start = @_;

    my $iter =
        File::Next::files( {
            file_filter => $file_filter,
            descend_filter => $descend ? \&App::Ack::skipdir_filter : sub {0},
        }, @start );

    return $iter;
}
