#!perl

use warnings;
use strict;

use Test::More tests => 1;

my $file = 't/etc/buttonhook.noxml.xxx';

# new files in t/etc must be listed here
my @expected = split( /\n/, <<'END_OF_LINES' );
      </children>
    </children>
  </children>
</children>
END_OF_LINES

my @results = `$^X ./ack-standalone -v -a size $file`;
chomp @results;

is_deeply( \@results, \@expected, "XML matches $file" );
