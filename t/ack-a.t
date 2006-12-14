#!perl

use warnings;
use strict;

use Test::More tests => 1;

my @expected = qw(
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

is_deeply( \@results, \@expected, 'File lists match' );
