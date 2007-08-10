#!perl

use warnings;
use strict;

use Test::More tests => 3;
delete $ENV{ACK_OPTIONS};

use lib 't';
use Util;

SINGLE_TEXT_MATCH: {
    my @expected = (
        'And I said: "My name is Sue! How do you do! Now you gonna die!"',
    );

    my @files = qw( t/text );
    my @args = qw( Sue! -1 -h --text );
    my $cmd = "$^X ./ack-standalone @args @files";
    my @results = `$cmd`;
    chomp @results;

    sets_match( \@results, \@expected, 'Looking for first instance of Sue!' );
}


SINGLE_FILE_MATCH: {
    my $regex = 'Makefile';
    my @files = qw( t/ );
    my @args = ( '-g', -1, $regex );
    my $cmd = "$^X ./ack-standalone @args @files";
    print "Running $cmd\n";
    my @results = `$cmd`;
    chomp @results;

    is( scalar @results, 1, "Should only get one file back from $regex" );
    like( $results[0], qr{t/swamp/Makefile(\.PL)?$}, 'The one file matches one of the two Makefile files' );
}
