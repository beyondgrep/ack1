#!perl -Tw

use warnings;
use strict;

use Test::More tests => 25;
use Data::Dumper;

BEGIN {
    use_ok( 'App::Ack' );
}

my @foo_pod_types = App::Ack::filetypes( 'foo.pod' ); # 5.6.1 doesn't like to sort(filetypes())
sets_match( [@foo_pod_types], [qw( parrot perl )], 'foo.pod can be multiple things' );
sets_match( [App::Ack::filetypes( 'Bongo.pm' )], [qw( perl )], 'Bongo.pm' );
sets_match( [App::Ack::filetypes( 'Makefile.PL' )], [qw( perl )], 'Makefile.PL' );
sets_match( [App::Ack::filetypes( 'Unknown.wango' )], [], 'Unknown' );

ok(  is_filetype( 'foo.pod', 'perl' ), 'foo.pod can be perl' );
ok(  is_filetype( 'foo.pod', 'parrot' ), 'foo.pod can be parrot' );
ok( !is_filetype( 'foo.pod', 'ruby' ), 'foo.pod cannot be ruby' );

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

ok(! defined App::Ack::filetypes('t/etc/shebang.foobar.xxx'),
    'file could not be identified from shebang line');

is(App::Ack::filetypes('t/etc/shebang.empty.xxx'), 'binary', 
    'empty file returns "binary"');

## Tests documenting current behavior in 1.50
is(App::Ack::filetypes('t/etc/buttonhook.xml.xxx'), 'xml',
    'file identified as xml from <?xml line');

ok(! defined App::Ack::filetypes('t/etc/buttonhook.noxml.xxx'),
    'no <?xml> found, so no filetype');


is(App::Ack::filetypes('t/etc/buttonhook.xml.xxx'),'xml',
   'filetype by <?xml>');

sets_match([App::Ack::filetypes('t/swamp/buttonhook.xml')], ['xml'],
    'file identified as xml ');

ok(! defined App::Ack::filetypes('t/etc/x.html.xxx'),
   '<!DOCTYPE not yet supported so no filetype');

## .htm[l]? is identified as qw(php html)
## Are there really servers with .html extension instead of .php ?
## <!DOCTYPE html ...>\n\n<?php...> would require more than one line lookahead.
sets_match([App::Ack::filetypes('t/swamp/html.html')], [qw/php html/], 'file identified as html');
sets_match([App::Ack::filetypes('t/swamp/html.htm')], [qw/php html/],  'file identified as htm[l]');


sub is_filetype {
    my $filename = shift;
    my $wanted_type = shift;

    for my $maybe_type ( App::Ack::filetypes( $filename ) ) {
        return 1 if $maybe_type eq $wanted_type;
    }

    return;
}


sub sets_match {
    my @expected = @{+shift};
    my @actual = @{+shift};
    my $msg = shift;

    local $Test::Builder::Level = $Test::Builder::Level + 1; ## no critic
    return is_deeply( [sort @expected], [sort @actual], $msg );
}
