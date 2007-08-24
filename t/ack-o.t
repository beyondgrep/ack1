#!perl

use warnings;
use strict;

use Test::More tests => 3;
use File::Next ();
delete $ENV{ACK_OPTIONS};

use lib 't';
use Util;

NO_O: {
    my @files = qw( t/text/boy-named-sue.txt );
    my @args = ( '"the\\s+\\S+"', '--text' );
    my @expected = split( /\n/, <<EOF );
        But the meanest thing that he ever did
        But I made me a vow to the moon and stars
        That I'd search the honky-tonks and bars
        Sat the dirty, mangy dog that named me Sue.
        Well, I hit him hard right between the eyes
        And we crashed through the wall and into the street
        Kicking and a-gouging in the mud and the blood and the beer.
        And it's the name that helped to make you strong."
        And I know you hate me, and you got the right
        For the gravel in ya gut and the spit in ya eye
        Cause I'm the son-of-a-bitch that named you Sue."
EOF
    s/^\s+// for @expected;

    my @results = run_ack( @args, @files );

    lists_match( \@results, \@expected, 'Find all the things' );
}


WITH_O: {
    my @files = qw( t/text/boy-named-sue.txt );
    my @args = ( '"the\\s+\\S+"', '--text', '-o' );
    my @expected = split( /\n/, <<EOF );
        the meanest
        the moon
        the honky-tonks
        the dirty,
        the eyes
        the wall
        the street
        the mud
        the blood
        the beer.
        the name
        the right
        the gravel
        the spit
        the son-of-a-bitch
EOF
    s/^\s+// for @expected;

    my @results = run_ack( @args, @files );

    lists_match( \@results, \@expected, 'Find all the things' );
}


WITH_OUTPUT: {
    my @files = qw( t/text/ );
    my @args = ( q{--output='x$1x'}, '-a', '"question(\\S+)"' );
    my @expected = qw(
        xedx
        xs.x
        x.x
    );

    my @results = run_ack( @args, @files );

    sets_match( \@results, \@expected, 'Find all the things' );
}
