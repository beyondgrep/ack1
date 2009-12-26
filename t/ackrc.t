#!perl

use warnings;
use strict;

use Test::More;
use File::Temp ();

use lib 't';
use Util;

prep_environment();

# write all arguments into a temporary file, one argument per line
#
# returns the filename (the file needs to be unlinked)
sub write_ackrc {
    my $tmp = new File::Temp( TEMPLATE => 'tmp-ackrc.XXXXX', UNLINK => 0 );
    my $filename = $tmp->filename;

    print $tmp $_, "\n" for @_;
    close $tmp or die $!;

    return $filename;
}

# assumes that the filename is the last argument
#
# writes a temporary ackrc file and deletes it afterwards
sub run_ack_with_ackrc {
    my @args = @_;
    my $filename = pop @args;

    local $ENV{ACKRC} = write_ackrc( @args );

    my @res = run_ack( '--env', $filename );
    unlink $ENV{ACKRC};

    return @res;
}

# tests if the results are the same, no matter if the arguments come from the
# command line or from .ackrc
#
# runs 3 tests
sub test_ack_is_same {
    my @args = @_;

    # run_ack does a quotemeta on all arguments, so is not happy about leading
    # or trailing whitespaces, that's why we need to fudge the arguments
    my @fudged_args = map { my $l = $_; $l =~ s/^\s+//; $l =~ s/\s+$//; $l } @args;
    my @expected = run_ack( @fudged_args );
    my @with_ackrc = run_ack_with_ackrc( @args );

    sets_match( \@with_ackrc, \@expected, "Same results while running 'ack @args'" );
}

my $filename = 't/text/boy-named-sue.txt';
my @tests = (
    [ qw(-i Sue!) ],
    [ '  -i', 'Sue!' ], # leading whitespace on option
    [ '-i  ', 'Sue!' ], # trailing whitespace on option
    [ qw(-f --foo --type-set=foo=.foo) ],
    [ qw(-f --foo --type-set foo=.foo) ],
);

plan tests => 3 * scalar @tests;

test_ack_is_same( @{$_}, $filename ) for @tests;
