#!perl

use strict;
use warnings;

=head1 DESCRIPTION

This tests whether L<ack(1)>'s command line options work as expected.

=cut

use Test::More qw( no_plan );

my $swamp = 't/swamp';
my $ack   = './ack';

=head1 TESTS

=over

=cut

=item --help

=cut

like
    qx{ $^X $ack $_ },
    qr{ ^Usage: .* Example: }xs,
    qq{$_ output is correct}
        for qw( -h --help );

=item --version

=cut

like
    qx{ $^X $ack $_ },
    qr{ ^ack .* Copyright .* Perl }xs,
    qq{$_ output is correct}
        for qw( --version );

=item --ignore-case

=cut

like
    qx{ $^X $ack $_ "upper case" t/swamp/options.pl },
    qr{UPPER CASE},
    qq{$_ works correctly for ascii}
        for qw( -i --ignore-case );

=item --invert-match

=cut

unlike
    qx{ $^X $ack $_ "use warnings" t/swamp/options.pl },
    qr{use warnings},
    qq{$_ works correctly}
        for qw( -v --invert-match );

=item --word-regexp

=cut

like
    qx{ $^X $ack $_ "word" t/swamp/options.pl },
    qr{ word },
    qq{$_ ignores non-words}
        for qw( -w --word-regexp );

unlike
    qx{ $^X $ack $_ "word" t/swamp/options.pl },
    qr{notaword},
    qq{$_ ignores non-words}
        for qw( -w --word-regexp );

=item --literal

=cut

like
    qx{ $^X $ack $_ '[abc]' t/swamp/options.pl },
    qr{\Q[abc]\E},
    qq{$_ matches a literal string}
        for qw( -Q --literal );

=item --files-with-matches

=cut

like
    qx{ $^X $ack $_ 'use strict' t/swamp/options.pl },
    qr{t/swamp/options\.pl},
    qq{$_ prints matching files}
        for qw( -l --files-with-matches );

=item --files-without-match

=cut

unlike
    qx{ $^X $ack $_ 'use puppies' t/swamp/options.pl },
    qr{t/swamp/options\.pl},
    qq{$_ prints matching files}
        for qw( -L --files-without-match );

=back

=cut
