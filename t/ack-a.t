#!perl

use warnings;
use strict;

use Test::More tests => 1;
use lib 't';
use Util;

delete $ENV{ACK_OPTIONS};

# new files in t/etc must be listed here
my @expected = qw(
    t/etc/buttonhook.html.xxx
    t/etc/buttonhook.noxml.xxx
    t/etc/buttonhook.rfc.xxx
    t/etc/buttonhook.rss.xxx
    t/etc/buttonhook.xml.xxx
    t/etc/shebang.empty.xxx
    t/etc/shebang.foobar.xxx
    t/etc/shebang.php.xxx
    t/etc/shebang.pl.xxx
    t/etc/shebang.py.xxx
    t/etc/shebang.rb.xxx
    t/etc/shebang.sh.xxx
);

my @results = run_ack( qw( -f -a t/etc ) );

sets_match( \@results, \@expected, 'File lists match' );
