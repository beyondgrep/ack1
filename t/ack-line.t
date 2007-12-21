#!perl

use warnings;
use strict;

use Test::More tests => 9;
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

LINE_1_TO_5_CONTEXT: {
    my @expected = split( /\n/, <<"EOF" );
Well, my daddy left home when I was three
And he didn't leave very much for my Ma and me
'cept an old guitar and an empty bottle of booze.
Now, I don't blame him 'cause he run and hid
But the meanest thing that he ever did
EOF

    my @files = qw( t/text/boy-named-sue.txt );
    my @args = qw( --lines=3 -C --text );
    my @results = run_ack( @args, @files );

    lists_match( \@results, \@expected, 'Looking for line 3 with two lines of context' );
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

LINE_AND_PASSTHRU: {
    # TODO: check if this is really what --passthru is supposed to do
    #       atm this gives back the whole document
    my @expected = split( /\n/, <<"EOF" );
=head1 Dummy document

=head2 There's important stuff in here!
EOF

    my @files = qw( t/swamp/perl.pod );
    my @args = qw( --lines=2 --passthru );
    my @results = run_ack( @args, @files );

    lists_match( \@results, \@expected, 'Checking --passthru behaviour with --line' );
}


LINE_1_MULTIPLE_FILES: {
    my @target_file = (
        File::Next::reslash( 't/swamp/c-header.h' ),
        File::Next::reslash( 't/swamp/c-source.c' )
    );
    my @expected = split( /\n/, <<"EOF" );
$target_file[0]:1:/*    perl.h
$target_file[1]:1:/*  A Bison parser, made from plural.y
EOF

    my @files = qw( t/swamp/ );
    my @args = qw( --cc --lines=1 );
    my @results = run_ack( @args, @files );

    sets_match( \@results, \@expected, 'Looking for first line in multiple files' );
}


LINE_1_CONTEXT: {
    my @target_file = (
        File::Next::reslash( 't/swamp/c-header.h' ),
        File::Next::reslash( 't/swamp/c-source.c' )
    );
    my @expected = split( /\n/, <<"EOF" );
$target_file[0]:1:/*    perl.h
$target_file[0]-2- *
$target_file[0]-3- *    Copyright (C) 1993, 1994, 1995, 1996, 1997, 1998, 1999,
$target_file[0]-4- *    2000, 2001, 2002, 2003, 2004, 2005, 2006, by Larry Wall and others
--
$target_file[1]:1:/*  A Bison parser, made from plural.y
$target_file[1]-2-    by GNU Bison version 1.28  */
$target_file[1]-3-
$target_file[1]-4-#define YYBISON 1  /* Identify Bison output.  */
EOF

    my @files = qw( t/swamp/ );
    my @args = qw( --cc --lines=1 --after=3 --sort );
    my @results = run_ack( @args, @files );

    lists_match( \@results, \@expected, 'Looking for first line in multiple files' );
}
