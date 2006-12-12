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

is(App::Ack::filetypes('foo.pod~'), '-ignore',
    'correctly ignore backup file');

is(App::Ack::filetypes('#some.pod#'), '-ignore',
    'correctly ignore files starting and ending with hash mark');

is(App::Ack::filetypes('core.987654321'), '-ignore',
    'correctly ignore files named core.NNNN');

is(App::Ack::filetypes('t/etc/shebang.pl.xxx'), 'perl',
    'file identified as Perl from shebang line');

is(App::Ack::filetypes('t/etc/shebang.php.xxx'), 'php',
    'file identified as PHP from shebang line');

is(App::Ack::filetypes('t/etc/shebang.py.xxx'), 'python',
    'file identified as Python from shebang line');

is(App::Ack::filetypes('t/etc/shebang.rb.xxx'), 'ruby',
    'file identified as Ruby from shebang line');

is(App::Ack::filetypes('t/etc/shebang.sh.xxx'), 'shell',
    'file identified as shell from shebang line');

ok(! defined App::Ack::filetypes('etc/shebang.foobar.xxx'),
    'file could not be identified from shebang line');

is(App::Ack::filetypes('t/etc/shebang.empty.xxx'), 'binary', 
    'empty file returns "binary"');
