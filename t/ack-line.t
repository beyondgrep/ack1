#!perl

use warnings;
use strict;

use Test::More tests => 6;
delete @ENV{qw( ACK_OPTIONS ACKRC )};

use lib 't';
use Util;

LINE_1: {
    my @expected = (
        'Well, my daddy left home when I was three',
    );

    my @files = qw( t/text/boy-named-sue.txt );
    my @args = qw( --lines=1 --text );
    my @results = run_ack( @args, @files );

    sets_match( \@results, \@expected, 'Looking for line 1' );
}

LINE_1_AND_5: {
    my @expected = (
        'Well, my daddy left home when I was three',
        'But the meanest thing that he ever did',
    );

    my @files = qw( t/text/boy-named-sue.txt );
    my @args = qw( --lines=1 --lines=5 --text );
    my @results = run_ack( @args, @files );

    sets_match( \@results, \@expected, 'Looking for lines 1 and 5' );
}

LINE_1_COMMA_5: {
    my @expected = (
        'Well, my daddy left home when I was three',
        'But the meanest thing that he ever did',
    );

    my @files = qw( t/text/boy-named-sue.txt );
    my @args = ( '--lines=1,5', '--text' );
    my @results = run_ack( @args, @files );

    sets_match( \@results, \@expected, 'Looking for lines 1, 5' );
}

LINE_1_TO_5: {
    my @expected = split( /\n/, <<"EOF" );
Well, my daddy left home when I was three
And he didn't leave very much for my Ma and me
'cept an old guitar and an empty bottle of booze.
Now, I don't blame him 'cause he run and hid
But the meanest thing that he ever did
EOF

    my @files = qw( t/text/boy-named-sue.txt );
    my @args = qw( --lines=1-5 --text );
    my @results = run_ack( @args, @files );

    sets_match( \@results, \@expected, 'Looking for lines 1 to 5' );
}

LINE_1_AND_5_AND_NON_EXISTENT: {
    my @expected = (
        'Well, my daddy left home when I was three',
        'But the meanest thing that he ever did',
    );

    my @files = qw( t/text/boy-named-sue.txt );
    my @args = ( '--lines=1,5,1000', '--text' );
    my @results = run_ack( @args, @files );

    sets_match( \@results, \@expected, 'Looking for non existent line' );
}

LINE_1_MULTIPLE_FILES: {
    my $target_file1 = File::Next::reslash( 't/swamp/c-header.h' );
    my $target_file2 = File::Next::reslash( 't/swamp/c-source.c' );
    my @expected = split( /\n/, <<"EOF" );
$target_file1:1:/*    perl.h
$target_file2:1:/*  A Bison parser, made from plural.y
EOF

    my @files = qw( t/swamp/ );
    my @args = qw( --cc --lines=1 );
    my @results = run_ack( @args, @files );

    sets_match( \@results, \@expected, 'Looking for first line in multiple files' );
}
