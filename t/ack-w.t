#!perl

use warnings;
use strict;

use Test::More tests => 3;
delete @ENV{qw( ACK_OPTIONS ACKRC )};

use lib 't';
use Util;

TRAILING_PUNC: {
    my @expected = (
        'And I said: "My name is Sue! How do you do! Now you gonna die!"',
        'Bill or George! Anything but Sue! I still hate that name!',
    );

    my @files = qw( t/text );
    my @args = qw( Sue! -w -h --text );
    my @results = run_ack( @args, @files );

    sets_match( \@results, \@expected, 'Looking for Sue!' );
}

TRAILING_METACHAR_BACKSLASH_W: {
    local $TODO = q{I can't figure why the -w works from the command line, but not inside this test}
        unless $^O eq 'MSWin32';
    my @expected = (
        'At an old saloon on a street of mud,',
        'Kicking and a-gouging in the mud and the blood and the beer.',
    );

    my @files = qw( t/text );
    my @args = ( 'mu\\w', qw( -w -h --text ) );
    my @results = run_ack( @args, @files );

    sets_match( \@results, \@expected, 'Looking for mu\\w' );
}


TRAILING_METACHAR_DOT: {
    local $TODO = q{I can't figure why the -w works from the command line, but not inside this test};
    my @expected = (
        'At an old saloon on a street of mud,',
        'Kicking and a-gouging in the mud and the blood and the beer.',
    );

    my @files = qw( t/text );
    my @args = ( 'mu.', qw( -w -h --text ) );
    my @results = run_ack( @args, @files );

    sets_match( \@results, \@expected, 'Looking for mu.' );
}


