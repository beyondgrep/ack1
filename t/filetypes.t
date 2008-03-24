#!perl -w

use warnings;
use strict;

use Test::More tests => 29;

use lib 't';
use Util;

BEGIN {
    use_ok( 'App::Ack' );
}

prep_environment();

sets_match( [App::Ack::filetypes( 'foo.pod' )], [qw( parrot perl text )], 'foo.pod can be multiple things' );
sets_match( [App::Ack::filetypes( 'Bongo.pm' )], [qw( perl text )], 'Bongo.pm' );
sets_match( [App::Ack::filetypes( 'Makefile.PL' )], [qw( perl text )], 'Makefile.PL' );
sets_match( [App::Ack::filetypes( 'Unknown.wango' )], [], 'Unknown' );

ok(  is_filetype( 'foo.pod', 'perl' ), 'foo.pod can be perl' );
ok(  is_filetype( 'foo.pod', 'parrot' ), 'foo.pod can be parrot' );
ok(  is_filetype( 'foo.pod', 'text' ), 'foo.pod can be parrot' );
ok( !is_filetype( 'foo.pod', 'ruby' ), 'foo.pod cannot be ruby' );
ok(  is_filetype( 'foo.handler.pod', 'perl' ), 'foo.handler.pod can be perl' );
ok(  is_filetype( '/tmp/wango/foo.pod', 'perl' ), '/tmp/wango/foo.pod can be perl' );
ok(  is_filetype( '/tmp/wango/foo.handler.pod', 'perl' ), '/tmp/wango/foo.handler.pod can be perl' );
ok(  is_filetype( '/tmp/blongo/makefile', 'make' ), '/tmp/blongo/makefile is a makefile' );
ok(  is_filetype( 'Makefile', 'make' ), 'Makefile is a makefile' );

is(App::Ack::filetypes('foo.pod~'), 'skipped',
    'correctly skip backup file');

is(App::Ack::filetypes('#some.pod#'), 'skipped',
    'correctly skip files starting and ending with hash mark');

is(App::Ack::filetypes('core.987654321'), 'skipped',
    'correctly skip files named core.NNNN');

MATCH_VIA_CONTENT: {
    my %lookups = (
        't/swamp/Makefile'          => 'make',
        't/swamp/Makefile.PL'       => 'perl',
        't/swamp/buttonhook.xml'    => 'xml',
        't/etc/shebang.php.xxx'     => 'php',
        't/etc/shebang.pl.xxx'      => 'perl',
        't/etc/shebang.py.xxx'      => 'python',
        't/etc/shebang.rb.xxx'      => 'ruby',
        't/etc/shebang.sh.xxx'      => 'shell',
        't/etc/buttonhook.xml.xxx'  => 'xml',
    );
    for my $filename ( sort keys %lookups ) {
        my $type = $lookups{$filename};
        sets_match( [App::Ack::filetypes( $filename )], [ $type, 'text' ], "Checking $filename" );
    }

    is(App::Ack::filetypes('t/etc/shebang.empty.xxx'), 'binary',
        'empty file returns "binary"');
}

FAIL_MATCHING_VIA_CONTENT: {
    is( App::Ack::filetypes('t/etc/shebang.foobar.xxx'), 'text',
        'file could not be identified from shebang line');

    is( App::Ack::filetypes('t/etc/buttonhook.noxml.xxx'), 'text',
        'no <?xml> found, so no filetype');
}
