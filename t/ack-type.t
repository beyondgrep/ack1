#!perl

use warnings;
use strict;

use Test::More tests => 16;

my $ruby = [qw(
    t/etc/shebang.rb.xxx
)];

my $perl = [qw(
    t/00-load.t
    t/ack-a.t
    t/ack-type.t
    t/etc/shebang.pl.xxx
    t/filetypes.t
    t/interesting.t
    t/pod-coverage.t
    t/pod.t
    t/standalone.t
    t/swamp/Makefile.PL
    t/swamp/perl-test.t
    t/swamp/perl-without-extension
    t/swamp/perl.cgi
    t/swamp/perl.pl
    t/swamp/perl.pm
    t/swamp/perl.pod
)];

my $perl_ruby = [ @{$perl}, @{$ruby} ];

check_with( '--perl', $perl );
check_with( '--perl --noruby', $perl );
check_with( '--ruby', $ruby );
check_with( '--ruby --noperl', $ruby );
check_with( '--perl --ruby', $perl_ruby );
check_with( '--ruby --perl', $perl_ruby );

check_with( '--type=perl', $perl );
check_with( '--type=perl --type=noruby', $perl );
check_with( '--type=ruby', $ruby );
check_with( '--type=ruby --type=noperl', $ruby );
check_with( '--type=perl --type=ruby', $perl_ruby );
check_with( '--type=ruby --type=perl', $perl_ruby );

check_with( '--perl --type=noruby', $perl );
check_with( '--ruby --type=noperl', $ruby );
check_with( '--perl --type=ruby', $perl_ruby );
check_with( '--ruby --type=perl', $perl_ruby );

sub check_with {
    my $options = shift;
    my $expected = shift;

    my @expected = sort @$expected;

    my @results = sort `$^X ./ack-standalone -f $options t`;

    chomp @results;

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    return is_deeply( \@results, \@expected, "File lists match via $options" );
}
