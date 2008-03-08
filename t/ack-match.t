#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use lib 't';
use Util;

my @files = qw( t/text );

my @tests = (
    [ qw/Sue -a/ ],
    [ qw/boy -a -i/ ], # case-insensitive is handled correctly with --match
    [ qw/ll+ -a -Q/ ], # quotemeta        is handled correctly with --match
    [ qw/gon -a -w/ ], # words            is handled correctly with --match
);

# 3 tests for each call to test_match()
plan tests => @tests * 3;

test_match( @$_ ) for @tests;


# call ack normally and compare output to calling with --match regex
#
# due to 2 calls to run_ack, this sub runs altogether 3 tests
sub test_match {
    my $regex = shift;
    my @args = @_;

    my @results_normal = run_ack( @args, $regex, @files );
    my @results_match  = run_ack( @args, @files, '--match', $regex );

    return sets_match( \@results_normal, \@results_match, "Same output for regex '$regex'." );
}
