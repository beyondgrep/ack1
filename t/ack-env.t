#!perl

use warnings;
use strict;

use Test::More tests => 10;

use lib 't';
use Util;

prep_environment();

SINGLE_TEXT_MATCH_ENV: {
    my @expected = (
        'And I said: "My name is Sue! How do you do! Now you gonna die!"',
    );

    my @files = qw( t/text );
    local $ENV{ACK_OPTIONS} = '-1';         # set the parameter via the options
    my @args = qw( Sue! -h --text --env --nocolor );  # and specifying --env does not change the result
    my @results = run_ack( @args, @files );

    sets_match( \@results, \@expected, 'Looking for first instance of Sue! with --env' );
}

SINGLE_TEXT_MATCH_NOENV: {
    my @expected = split( /\n/, <<'EOF' );
And I said: "My name is Sue! How do you do! Now you gonna die!"
Bill or George! Anything but Sue! I still hate that name!
EOF

    my @files = qw( t/text );
    local $ENV{ACK_OPTIONS} = '-1';          # set the parameter via the options
    my @args = qw( Sue! -h --text --noenv ); # but disable environment processing
    my @results = run_ack( @args, @files );

    sets_match( \@results, \@expected, 'Looking for Sue! with --noenv' );
}

SEARCH_FOR_DASH_DASH_NOENV: {
    my @expected = ' magic string --noenv';
    my @files = qw( t/text );
    local $ENV{ACK_OPTIONS} = '-h --cc';          # set the parameter via the options
    my @args = qw( --nocolor -- --noenv t/swamp ); # but disable environment processing
    my @results = run_ack( @args, @files );

    sets_match( \@results, \@expected, 'Looking for Sue! with --noenv' );
}

SINGLE_TEXT_MATCH_NOENV_ENV: {
    my @expected = (
        'And I said: "My name is Sue! How do you do! Now you gonna die!"',
    );

    my @files = qw( t/text );
    local $ENV{ACK_OPTIONS} = '-1';         # set the parameter via the options
    my @args = qw( Sue! -h --text --noenv --env --nocolor );  # and specifying --noenv --env does not change the result
    my @results = run_ack( @args, @files );

    sets_match( \@results, \@expected, 'Looking for first instance of Sue! with --noenv --env' );
}

SINGLE_TEXT_MATCH_ENV_NOENV: {
    my @expected = split( /\n/, <<'EOF' );
And I said: "My name is Sue! How do you do! Now you gonna die!"
Bill or George! Anything but Sue! I still hate that name!
EOF

    my @files = qw( t/text );
    local $ENV{ACK_OPTIONS} = '-1';          # set the parameter via the options
    my @args = qw( Sue! -h --text --env --noenv ); # but disable environment processing
    my @results = run_ack( @args, @files );

    sets_match( \@results, \@expected, 'Looking for Sue! with --env --noenv' );
}
