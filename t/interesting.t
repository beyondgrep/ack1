#!perl -Tw

use warnings;
use strict;

use Test::More tests => 7;

BEGIN {
    use_ok( 'App::Ack' );
}

sub is_perl {
    my $file = shift;

    for my $type ( App::Ack::filetypes( $file ) ) {
        return 1 if $type eq "perl";
    }
    return;
}

PERL_FILES: {
    my @files;
    my $iter = App::Ack::interesting_files( \&is_perl, 0, 't/swamp' );

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
    )] );
}

PERL_FILES_GLOBBED: {
    # We have to be able to handle starting locations that are files.
    my @files;
    my @starters = grep { !/blib/ } glob( "t/swamp/*" );
    my $iter = App::Ack::interesting_files( \&is_perl, 0, @starters );

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
    )] );
}

sub is_parrot {
    my $file = shift;

    for my $type ( App::Ack::filetypes( $file ) ) {
        return 1 if $type eq "parrot";
    }
    return;
}

PARROT_FILES_DESCEND: {
    my @files;
    my $iter = App::Ack::interesting_files( \&is_parrot, 1, 't' );

    while ( my $file = $iter->() ) {
        push( @files, $file );
    }

    is_deeply( [sort @files], [sort qw(
        t/swamp/parrot.pir
        t/swamp/perl.pod
    )] );
}

PARROT_FILES_NODESCEND: {
    my @files;
    my $iter = App::Ack::interesting_files( \&is_parrot, 0, 't/swamp' );

    while ( my $file = $iter->() ) {
        push( @files, $file );
    }

    is_deeply( [sort @files], [sort qw(
        t/swamp/parrot.pir
        t/swamp/perl.pod
    )] );
}

PARROT_FILES_NODESCEND_EMPTY: {
    my @files;
    my $iter = App::Ack::interesting_files( \&is_parrot, 0, 't/' );

    while ( my $file = $iter->() ) {
        push( @files, $file );
    }

    is_deeply( [@files], [] );
}

PERL_FILES_BY_NAME: {
    my @files;
    my $iter = App::Ack::interesting_files( \&is_parrot, 0, 't/swamp/perl.pod' );

    while ( my $file = $iter->() ) {
        push( @files, $file );
    }

    is_deeply( [sort @files], [sort qw( t/swamp/perl.pod )] );
}

