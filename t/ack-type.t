#!perl

use warnings;
use strict;

use Test::More tests => 1;

my $ack = "$^X ./ack-standalone";

my @expected = qw(
    t/00-load.t
    t/ack-type.t
    t/etc/shebang.pl.xxx
    t/filetypes.t
    t/interesting.t
    t/pod-coverage.t
    t/pod.t
    t/standalone.t
    t/swamp/Makefile.PL
    t/swamp/perl-test.t
    t/swamp/perl-without-extension
    t/swamp/perl.cgi
    t/swamp/perl.pl
    t/swamp/perl.pm
    t/swamp/perl.pod
);

VIA_DASH_DASH_PERL: {
    my @results = `$ack -f --perl t`;

    sets_match( \@results, \@expected, 'File lists match via --perl' );
}

sub sets_match {
    my $actual = shift;
    my $expected = shift;
    my $msg = shift;

    chomp @$actual;

    return is_deeply( $actual, $expected, $msg );
}
