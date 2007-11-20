#!perl

use warnings;
use strict;

use Test::More tests => 6;
use File::Next 0.34; # For the reslash() function

use lib 't';
use Util qw/run_ack/;

delete @ENV{qw( ACK_OPTIONS ACKRC )};

check_grep( '#emacs-workfile.pl#', 't/swamp/' ); # temp file
check_grep( 'core.2112', 't/etc/' );             # core file
check_grep( 'ignore.pod', 't/swamp/' );          # ignore.pod is in t/swamp/blib/


# does 2 tests:
#   1) with    --grep, making sure the file IS in the output
#   2) without --grep, making sure the file IS NOT in the output
sub check_grep {
    my ( $file, $dir ) = @_;

    my @results_without_grep = run_ack( '-f', $dir );
    my @results_with_grep    = run_ack( '-f', '--grep', $dir );
    my $pattern = quotemeta $file;

    # no checking with sets_match or lists_match as we don't know
    # exactly what files will be returned (eg. .svn directories)
    #
    # to make sure, we always check that the file is NOT there when
    # searching without --grep
    ok(  grep( /$pattern/, @results_with_grep ),
        "$file found with --grep in $dir");
    ok( !grep( /$pattern/, @results_without_grep ),
        "$file not found without --grep in $dir");
}
