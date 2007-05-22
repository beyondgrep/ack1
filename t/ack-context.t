#!perl

use warnings;
use strict;

use Test::More tests => 3;

use lib 't';
use Util;

DASH_CAPITAL_A: {
    my @expected = split $/ => <<END_EXPECTED;
13: I tell ya, life ain't easy for a boy named Sue.
14: 
--
43: I tell ya, I've fought tougher men
44: But I really can't remember when,
--
END_EXPECTED

    my @files = qw( t/text );
    my @args = qw( tell -a -A 1 );
    my $cmd = "$^X ./ack-standalone @args @files";
    my @results = `$cmd`;
    chomp( @results, @expected );

    sets_match( \@results, \@expected, 'Looking for religion' );
}

DASH_CAPITAL_B: {
    my @expected = split $/ => <<END_EXPECTED;
12: And some guy'd laugh and I'd bust his head,
13: I tell ya, life ain't easy for a boy named Sue.
--
42: 
43: I tell ya, I've fought tougher men
--
END_EXPECTED

    my @files = qw( t/text );
    my @args = qw( tell -a -B 1 );
    my $cmd = "$^X ./ack-standalone @args @files";
    my @results = `$cmd`;
    chomp( @results, @expected );

    sets_match( \@results, \@expected, 'Looking for religion' );
}

DASH_CAPITAL_C: {
    my @expected = split $/ => <<END_EXPECTED;
12: And some guy'd laugh and I'd bust his head,
13: I tell ya, life ain't easy for a boy named Sue.
14: 
--
42: 
43: I tell ya, I've fought tougher men
44: But I really can't remember when,
--
END_EXPECTED

    my @files = qw( t/text );
    my @args = qw( tell -a -C 1 );
    my $cmd = "$^X ./ack-standalone @args @files";
    my @results = `$cmd`;
    chomp( @results, @expected );

    sets_match( \@results, \@expected, 'Religion counts' );
}

