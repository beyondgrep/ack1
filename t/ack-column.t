#!perl

use warnings;
use strict;

use Test::More tests => 4;

use File::Next ();

use lib 't';
use Util;

prep_environment();

my $weasel = File::Next::reslash( 't/text/science-of-myth.txt' );

WITH_COLUMNS: {
    my @expected = split( /\n/, <<'HERE' );
3:4:In the case of Christianity and Judaism there exists the belief
6:1:The Buddhists believe that the functional aspects override the myth
7:8:While other religions use the literal core to build foundations with
8:11:See, half the world sees the myth as fact, and it's seen as a lie by the other half
9:5:And the simple truth is that it's none of that 'cause
10:24:Somehow no matter what the world keeps turning
14:43:In fact, for better understanding we take the facts of science and apply them
15:35:And if both factors keep evolving then we continue getting information
16:17:But closing off the possibilities makes it hard to see the bigger picture
18:10:Consider the case of the woman whose faith helped her make it through
22:18:And if it works, then it gets the job done
23:24:Somehow no matter what the world keeps turning
26:9:    -- "The Science Of Myth", Screeching Weasel
HERE
    @expected = map { "${weasel}:$_" } @expected;

    my @files = ( $weasel );
    my @args = qw( the -w --with-filename --column );
    my @results = run_ack( @args, @files );

    sets_match( \@results, \@expected, 'Checking column numbers' );
}


WITHOUT_COLUMNS: {
    my @expected = split( /\n/, <<'HERE' );
3:In the case of Christianity and Judaism there exists the belief
6:The Buddhists believe that the functional aspects override the myth
7:While other religions use the literal core to build foundations with
8:See, half the world sees the myth as fact, and it's seen as a lie by the other half
9:And the simple truth is that it's none of that 'cause
10:Somehow no matter what the world keeps turning
14:In fact, for better understanding we take the facts of science and apply them
15:And if both factors keep evolving then we continue getting information
16:But closing off the possibilities makes it hard to see the bigger picture
18:Consider the case of the woman whose faith helped her make it through
22:And if it works, then it gets the job done
23:Somehow no matter what the world keeps turning
26:    -- "The Science Of Myth", Screeching Weasel
HERE
    @expected = map { "${weasel}:$_" } @expected;

    my @files = ( $weasel );
    my @args = qw( the -w --with-filename --no-column );
    my @results = run_ack( @args, @files );

    sets_match( \@results, \@expected, 'Checking without column numbers' );
}

