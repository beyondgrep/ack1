#!perl

use warnings;
use strict;

use Test::More tests => 8;
delete @ENV{qw( ACK_OPTIONS ACKRC )};

use lib 't';
use Util;

NO_STARTDIR: {
    my @expected = ('ack-standalone: t/foo/non-existent: No such file or directory');
    my $regex = 'Makefile';

    my @files = qw( t/foo/non-existent );
    my @args = ( '-g', $regex );
    my @results = run_ack( @args, @files, '2>&1' ); # redirect STDERR

    sets_match( \@results, \@expected, "Looking for $regex in non-existent file" );
}


NO_METACHARCTERS: {
    my @expected = qw(
        t/swamp/Makefile
        t/swamp/Makefile.PL
    );
    my $regex = 'Makefile';

    my @files = qw( t/ );
    my @args = ( '-g', $regex );
    my @results = run_ack( @args, @files );

    sets_match( \@results, \@expected, "Looking for $regex" );
}


METACHARACTERS: {
    my @expected = qw(
        t/swamp/html.htm
        t/swamp/html.html
    );
    my $regex = 'swam.......htm';

    my @files = qw( t/ );
    my @args = ( '-g', $regex );
    my @results = run_ack( @args, @files );

    sets_match( \@results, \@expected, "Looking for $regex" );
}


FRONT_ANCHOR: {
    my @expected = qw(
        t/standalone.t
    );
    my $regex = '^t.st';

    my @files = qw( t );
    my @args = ( '-g', $regex );
    my @results = run_ack( @args, @files );

    sets_match( \@results, \@expected, "Looking for $regex" );
}


BACK_ANCHOR: {
    my @expected = qw(
        t/swamp/moose-andy.jpg
    );
    my $regex = 'pg$';

    my @files = qw( t );
    my @args = ( '-a', '-g', $regex );
    my @results = run_ack( @args, @files );

    sets_match( \@results, \@expected, "Looking for $regex" );
}


CASE_INSENSITIVE: {
    my @expected = qw(
        t/swamp/pipe-stress-freaks.F
    );
    my $regex = 'PIPE';

    my @files = qw( . );
    my @args = ( '-i', '-g', $regex );
    my @results = run_ack( @args, @files );

    sets_match( \@results, \@expected, "Looking for $regex, case-insensitive" );
}

FILE_ON_COMMAND_LINE_IS_ALWAYS_SEARCHED: {
    my @expected = ( 't/swamp/#emacs-workfile.pl#' );
    my $regex = 'emacs';

    my @files = ( 't/swamp/#emacs-workfile.pl#' );
    my @args = ( '-g', $regex );
    my @results = run_ack( @args, @files );

    sets_match( \@results, \@expected, "File on command line is always searched" );
}

FILE_ON_COMMAND_LINE_IS_ALWAYS_SEARCHED_EVEN_WITH_WRONG_TYPE: {
    my @expected = qw(
        t/swamp/parrot.pir
    );
    my $regex = 'parrot';

    my @files = qw( t/swamp/parrot.pir );
    my @args = ( '--html', '-g', $regex );
    my @results = run_ack( @args, @files );

    sets_match( \@results, \@expected, "File on command line is always searched, even with wrong type." );
}
