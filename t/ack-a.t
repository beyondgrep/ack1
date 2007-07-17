#!perl

use warnings;
use strict;

use Test::More tests => 1;
use File::Next 0.34; # For the reslash() function
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

my @results = sort `$^X ./ack-standalone -f -a t/etc`;
chomp @results;

$_ = File::Next::reslash( $_ ) for ( @expected, @results );

is_deeply( \@results, \@expected, 'File lists match' );
