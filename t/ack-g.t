#!perl

use warnings;
use strict;

use Test::More tests => 4;
delete $ENV{ACK_OPTIONS};

use lib 't';
use Util;

NO_METACHARCTERS: {
    my @expected = qw(
        t/swamp/Makefile
    );
    my $pattern = 'Makefile';

    my @files = qw( t/ );
    my @args = ( '-g', $pattern );
    my $cmd = "$^X ./ack-standalone @args @files";
    my @results = `$cmd`;
    chomp @results;

    sets_match( \@results, \@expected, "Looking for $pattern" );
}


DOT_STAR: {
    my @expected = qw(
        t/swamp/perl.cgi
        t/swamp/perl.pl
        t/swamp/perl.pm
        t/swamp/perl.pod
    );
    my $pattern = 'perl.*';

    my @files = qw( t/ );
    my @args = ( '-g', $pattern );
    my $cmd = "$^X ./ack-standalone @args @files";
    my @results = `$cmd`;
    chomp @results;

    sets_match( \@results, \@expected, "Looking for $pattern" );
}


QUESTION_MARK: {
    my @expected = qw(
        t/swamp/perl.pl
        t/swamp/perl.pm
    );
    my $pattern = 'perl.p?';

    my @files = qw( t/ );
    my @args = ( '-g', $pattern );
    my $cmd = "$^X ./ack-standalone @args @files";
    my @results = `$cmd`;
    chomp @results;

    sets_match( \@results, \@expected, "Looking for $pattern" );
}


STAR_DOT_STAR: {
    my @expected = qw(
        t/pod.t
        t/pod-coverage.t
        t/swamp/parrot.pir
        t/swamp/perl-test.t
        t/swamp/perl.cgi
        t/swamp/perl.pl
        t/swamp/perl.pm
        t/swamp/perl.pod
    );
    my $pattern = 'p*.*';

    my @files = qw( t/ );
    my @args = ( '-g', $pattern );
    my $cmd = "$^X ./ack-standalone @args @files";
    my @results = `$cmd`;
    chomp @results;

    sets_match( \@results, \@expected, "Looking for $pattern" );
}
