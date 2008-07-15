#!perl

use warnings;
use strict;

use Test::More tests => 4;
use App::Ack ();
use File::Next ();

use lib 't';
use Util;

prep_environment();

ACK_F_TEXT: {
    my @expected = qw(
        t/etc/buttonhook.html.xxx
        t/etc/buttonhook.noxml.xxx
        t/etc/buttonhook.rfc.xxx
        t/etc/buttonhook.rss.xxx
        t/etc/buttonhook.xml.xxx
        t/etc/shebang.foobar.xxx
        t/etc/shebang.php.xxx
        t/etc/shebang.pl.xxx
        t/etc/shebang.py.xxx
        t/etc/shebang.rb.xxx
        t/etc/shebang.sh.xxx
        t/swamp/0
        t/swamp/pipe-stress-freaks.F
        t/swamp/crystallography-weenies.f
        t/swamp/c-header.h
        t/swamp/c-source.c
        t/swamp/file.foo
        t/swamp/file.bar
        t/swamp/groceries/fruit
        t/swamp/groceries/junk
        t/swamp/groceries/meat
        t/swamp/groceries/another_subdir/fruit
        t/swamp/groceries/another_subdir/junk
        t/swamp/groceries/another_subdir/meat
        t/swamp/groceries/subdir/fruit
        t/swamp/groceries/subdir/junk
        t/swamp/groceries/subdir/meat
        t/swamp/html.htm
        t/swamp/html.html
        t/swamp/incomplete-last-line.txt
        t/swamp/javascript.js
        t/swamp/Makefile
        t/swamp/Makefile.PL
        t/swamp/notaMakefile
        t/swamp/notaRakefile
        t/swamp/options.pl
        t/swamp/parrot.pir
        t/swamp/perl-test.t
        t/swamp/perl-without-extension
        t/swamp/perl.cgi
        t/swamp/perl.pl
        t/swamp/perl.pm
        t/swamp/perl.pod
        t/swamp/Rakefile
        t/swamp/sample.rake
        t/text/4th-of-july.txt
        t/text/boy-named-sue.txt
        t/text/freedom-of-choice.txt
        t/text/me-and-bobbie-mcgee.txt
        t/text/science-of-myth.txt
        t/text/shut-up-be-happy.txt
    );

    my @files = qw( t/text t/swamp t/etc );
    my @args = qw( -f --text );
    my @results = run_ack( @args, @files );

    sets_match( \@results, \@expected, 'Looking for text files' );
}


ACK_F_XML: {
    my @expected = qw(
        t/etc/buttonhook.rss.xxx
        t/etc/buttonhook.xml.xxx
    );

    my @files = qw( t/etc );
    my @args = qw( -f --xml );
    my @results = run_ack( @args, @files );

    sets_match( \@results, \@expected, 'Looking for XML files' );
}
