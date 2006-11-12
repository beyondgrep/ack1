#!perl -Tw

use warnings;
use strict;

use Test::More tests => 18;
use Data::Dumper;

BEGIN {
    use_ok( 'App::Ack' );
}

my @foo_pod_types = App::Ack::filetypes( 'foo.pod' ); # 5.6.1 doesn't like to sort(filetypes())
is_deeply( [sort @foo_pod_types], [qw( parrot perl )], 'foo.pod can be multiple things' );
is_deeply( [App::Ack::filetypes( 'Bongo.pm' )], [qw( perl )], 'Bongo.pm' );
is_deeply( [App::Ack::filetypes( 'Makefile.PL' )], [qw( perl )], 'Makefile.PL' );
is_deeply( [App::Ack::filetypes( 'Unknown.wango' )], [], 'Unknown' );

ok(  App::Ack::is_filetype( 'foo.pod', 'perl' ), 'foo.pod can be perl' );
ok(  App::Ack::is_filetype( 'foo.pod', 'parrot' ), 'foo.pod can be parrot' );
ok( !App::Ack::is_filetype( 'foo.pod', 'ruby' ), 'foo.pod cannot be ruby' );

is(App::Ack::filetypes(q{foo.pod~}), q{-ignore},
    'correctly ignore backup file');

is(App::Ack::filetypes(q{#some.pod#}), q{-ignore},
    'correctly ignore files starting and ending with hash mark');

is(App::Ack::filetypes(q{core.987654321}), q{-ignore},
    'correctly ignore files named core.NNNN');

is(App::Ack::filetypes(q{etc/shebang.pl.xxx}), q{perl},
    'file identified as Perl from shebang line');

is(App::Ack::filetypes(q{etc/shebang.php.xxx}), q{php},
    'file identified as PHP from shebang line');

is(App::Ack::filetypes(q{etc/shebang.py.xxx}), q{python},
    'file identified as Python from shebang line');

is(App::Ack::filetypes(q{etc/shebang.rb.xxx}), q{ruby},
    'file identified as Ruby from shebang line');

is(App::Ack::filetypes(q{etc/shebang.sh.xxx}), q{shell},
    'file identified as shell from shebang line');

ok(! defined App::Ack::filetypes(q{etc/shebang.foobar.xxx}),
    'file could not be identified from shebang line');

is(App::Ack::filetypes(q{etc/shebang.empty.xxx}), q{binary}, 
    'empty file returns "binary"');
