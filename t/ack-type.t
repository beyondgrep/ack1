#!perl

use warnings;
use strict;

use Test::More tests => 74;

use lib 't';
use Util qw( sets_match );

delete @ENV{qw( ACK_OPTIONS ACKRC )};

my $cc = [qw(
    t/swamp/c-source.c
)];

my $hh = [qw(
    t/swamp/c-header.h
)];

my $ruby = [qw(
    t/etc/shebang.rb.xxx
)];

my $fortran = [qw(
    t/swamp/pipe-stress-freaks.F
    t/swamp/crystallography-weenies.f
)];

my $foo = [qw(
    t/swamp/file.foo
)];

my $bar = [qw(
    t/swamp/file.bar
)];

my $xml = [qw(
    t/etc/buttonhook.rss.xxx
    t/etc/buttonhook.xml.xxx
)];

my $perl = [qw(
    ack
    ack-standalone
    Ack.pm
    Makefile.PL
    squash
    t/00-load.t
    t/ack-1.t
    t/ack-a.t
    t/ack-binary.t
    t/ack-c.t
    t/ack-color.t
    t/ack-env.t
    t/ack-g.t
    t/ack-group.t
    t/ack-h.t
    t/ack-ignore-dir.t
    t/ack-line.t
    t/ack-match.t
    t/ack-o.t
    t/ack-print0.t
    t/ack-passthru.t
    t/ack-text.t
    t/ack-type.t
    t/ack-u.t
    t/ack-v.t
    t/ack-w.t
    t/code.t
    t/command-line-files.t
    t/context.t
    t/etc/shebang.pl.xxx
    t/filetypes.t
    t/file-permission.t
    t/interesting.t
    t/longopts.t
    t/module.t
    t/multiline.t
    t/pod-coverage.t
    t/pod.t
    t/standalone.t
    t/swamp/0
    t/swamp/Makefile.PL
    t/swamp/options.pl
    t/swamp/perl-test.t
    t/swamp/perl-without-extension
    t/swamp/perl.cgi
    t/swamp/perl.pl
    t/swamp/perl.pm
    t/swamp/perl.pod
    t/zero.t
    t/Util.pm
)];

my $skipped = [
    't/etc/core.2112',
    't/swamp/#emacs-workfile.pl#',
    't/swamp/options.pl.bak',
];

my $perl_ruby = [ @{$perl}, @{$ruby} ];
my $cc_hh = [ @{$cc}, @{$hh} ];
my $foo_bar = [ @{$foo}, @{$bar} ];
my $foo_xml = [ @{$foo}, @{$xml} ];
my $foo_bar_xml = [ @{$foo}, @{$bar}, @{$xml} ];

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

check_with( '--cc', $cc_hh );
check_with( '--hh', $hh );
check_with( '--cc --nohh', $cc );

check_with( '--fortran', $fortran );

check_with( '--skipped', $skipped );

# check --type-set
check_with( '--type-set foo-type=.foo --foo-type', $foo );
check_with( '--type-set foo-type=.foo --type=foo-type', $foo );
check_with( '--type-set foo-type=.foo,.bar --foo-type', $foo_bar );
check_with( '--type-set foo-type=.foo --type-set bar-type=.bar --foo-type --bar-type', $foo_bar );

# check --type-add
check_with( '--type-add xml=.foo --xml', $foo_xml );
check_with( '--type-add xml=.foo,.bar --xml', $foo_bar_xml );

# check that --type-set redefines
check_with( '--type-set cc=.foo --cc', $foo );

# check that builtin types cannot be changed
SKIP: {
    my @builtins = qw( make skipped text binary );
    my $ntests = @builtins + 1;

    skip q{Can't check stderr under Windows}, $ntests * 4 if is_win32;
    for my $builtin ( @builtins ) {
        check_stderr( "--type-set $builtin=.foo",
            "ack-standalone: --type-set: Builtin type '$builtin' cannot be changed." );
        check_stderr( "--type-add $builtin=.foo",
            "ack-standalone: --type-add: Builtin type '$builtin' cannot be changed." );
    }

    # check that there is a warning for creating new types with --append_type
    check_stderr( "--type-add foo=.foo --foo",
            "ack-standalone: --type-add: Type 'foo' does not exist, creating with '.foo' ..." );
}


sub check_with {
    my $options = shift;
    my $expected = shift;

    my @expected = sort @{$expected};

    my @results = run_ack( '-f', $options );
    @results = grep { !/~$/ } @results; # Don't see my vim backup files

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    return sets_match( \@results, \@expected, "File lists match via $options" );
}

sub check_stderr {
    my $options = shift;
    my $expected = shift;

    my ($stdout, $stderr) = run_ack_with_stderr( '-f', $options );

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    is( $stderr->[0], $expected, "Located stderr message: $expected" );
    is( @{$stderr}, 1, "Only one line of stderr for message: $expected" );
}
