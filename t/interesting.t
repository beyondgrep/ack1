#!perl -w

use warnings;
use strict;

use Test::More tests => 8;
use File::Next 0.22;

BEGIN {
    use_ok( 'App::Ack' );
}

my $is_perl = sub { return App::Ack::is_filetype( $File::Next::name, 'perl' ) }; ## no critic
my $is_parrot = sub { return App::Ack::is_filetype( $File::Next::name, 'parrot' ) }; ## no critic
my $is_binary = sub { return App::Ack::is_filetype( $File::Next::name, 'binary' ) }; ## no critic

PERL_FILES: {
    my $iter =
        File::Next::files( {
            file_filter => $is_perl,
            descend_filter => \&App::Ack::skipdir_filter,
        }, 't/swamp' );

    my @files;
    while ( my $file = $iter->() ) {
        push( @files, $file );
    }

    is_deeply( [sort @files], [sort qw(
        t/swamp/Makefile.PL
        t/swamp/perl.cgi
        t/swamp/perl.pl
        t/swamp/perl.pm
        t/swamp/perl.pod
        t/swamp/perl-test.t
        t/swamp/perl-without-extension
    )], 'PERL_FILES' );
}

PERL_FILES_GLOBBED: {
    # We have to be able to handle starting locations that are files.
    my @starters = grep { !/blib/ } glob( 't/swamp/*' );
    my $iter =
        File::Next::files( {
            file_filter => $is_perl,
            descend_filter => \&App::Ack::skipdir_filter,
        }, @starters );

    my @files;
    while ( my $file = $iter->() ) {
        push( @files, $file );
    }

    is_deeply( [sort @files], [sort qw(
        t/swamp/Makefile.PL
        t/swamp/perl.cgi
        t/swamp/perl.pl
        t/swamp/perl.pm
        t/swamp/perl.pod
        t/swamp/perl-test.t
        t/swamp/perl-without-extension
    )], 'PERL_FILES_GLOBBED' );
}

PARROT_FILES_DESCEND: {
    my $iter =
        File::Next::files( {
            file_filter => $is_parrot,
            descend_filter => \&App::Ack::skipdir_filter,
        }, 't' );

    my @files;
    while ( my $file = $iter->() ) {
        push( @files, $file );
    }

    is_deeply( [sort @files], [sort qw(
        t/swamp/parrot.pir
        t/swamp/perl.pod
    )], 'PARROT_FILES_DESCEND' );
}

PARROT_FILES_NODESCEND: {
    my $iter =
        File::Next::files( {
            file_filter => $is_parrot,
            descend_filter => sub{0},
        }, 't/swamp' );

    my @files;
    while ( my $file = $iter->() ) {
        push( @files, $file );
    }

    is_deeply( [sort @files], [sort qw(
        t/swamp/parrot.pir
        t/swamp/perl.pod
    )], 'PARROT_FILES_NODESCEND' );
}

PARROT_FILES_NODESCEND_EMPTY: {
    my $iter =
        File::Next::files( {
            file_filter => $is_parrot,
            descend_filter => sub{0},
        }, 't/' );

    my @files;
    while ( my $file = $iter->() ) {
        push( @files, $file );
    }

    is_deeply( [@files], [], 'PARROT_FILES_NODESCEND_EMPTY' );
}

PERL_FILES_BY_NAME: {
    my $iter =
        File::Next::files( {
            file_filter => $is_parrot,
            descend_filter => sub{0},
        }, 't/swamp/perl.pod' );

    my @files;
    while ( my $file = $iter->() ) {
        push( @files, $file );
    }

    is_deeply( [sort @files], [sort qw( t/swamp/perl.pod )], 'PERL_FILES_BY_NAME' );
}

BINARY_FILES: {
    my $iter =
        File::Next::files( {
            file_filter => $is_binary,
            descend_filter => \&App::Ack::skipdir_filter,
        }, 't/swamp' );

    my @files;
    while ( my $file = $iter->() ) {
        push( @files, $file );
    }

    is_deeply( [sort @files], [sort qw(
        t/swamp/moose-andy.jpg
    )], 'BINARY_FILES' );
}

