#!perl

use warnings;
use strict;

use Test::More tests => 6;
use File::Next 0.34; # For the reslash() function

use lib 't';
use Util qw/run_ack/;

delete @ENV{qw( ACK_OPTIONS ACKRC )};

check_u( '#emacs-workfile.pl#', 't/swamp/' ); # temp file
check_u( 'core.2112', 't/etc/' );             # core file
check_u( 'ignore.pod', 't/swamp/' );          # ignore.pod is in t/swamp/blib/


# does 2 tests:
#   1) with    -u, making sure the file IS in the output
#   2) without -u, making sure the file IS NOT in the output
sub check_u {
    my ( $file, $dir ) = @_;

    my @results_without_u = run_ack( '-f', $dir );
    my @results_with_u    = run_ack( '-f', '-u', $dir );
    my $pattern = quotemeta $file;

    # no checking with sets_match or lists_match as we don't know
    # exactly what files will be returned (eg. .svn directories)
    #
    # to make sure, we always check that the file is NOT there when
    # searching without -u
    ok(  scalar( grep { /$pattern/ } @results_with_u ), "$file found with -u in $dir" );
    ok( !scalar( grep { /$pattern/ } @results_without_u ), "$file not found without -u in $dir" );
}
