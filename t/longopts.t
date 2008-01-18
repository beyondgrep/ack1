#!perl

use strict;
use warnings;

=head1 DESCRIPTION

This tests whether L<ack(1)>'s command line options work as expected.

=cut

use Test::More tests => 30;
use File::Next 0.34; # For the reslash() function
delete @ENV{qw( ACK_OPTIONS ACKRC )};

my $swamp = 't/swamp';
my $ack   = './ack-standalone';

# Help
for ( qw( --help ) ) {
    like
        qx{ $^X -T $ack $_ },
        qr{ ^Usage: .* Example: }xs,
        qq{$_ output is correct};
    option_in_usage( $_ );
}

# Version
for ( qw( --version ) ) {
    like
        qx{ $^X -T $ack $_ },
        qr{ ^ack .* Copyright .* Perl }xs,
        qq{$_ output is correct};
    option_in_usage( $_ );
}

# Ignore case
for ( qw( -i --ignore-case ) ) {
    like
        qx{ $^X -T $ack $_ "upper case" t/swamp/options.pl },
        qr{UPPER CASE},
        qq{$_ works correctly for ascii};
    option_in_usage( $_ );
}

# Invert match
#   this test was changed from using unlike to using like because
#   old versions of Test::More::unlike (before 0.48_2) cannot
#   work with multiline output (which ack produces in this case).
for ( qw( -v --invert-match ) ) {
    like
        qx{ $^X -T $ack $_ "use warnings" t/swamp/options.pl },
        qr{use strict;\n\n=head1 NAME}, # no 'use warnings' in between here
        qq{$_ works correctly};
    option_in_usage( $_ );
}

# Word regexp
for ( qw( -w --word-regexp ) ) {
    like
        qx{ $^X -T $ack $_ "word" t/swamp/options.pl },
        qr{ word },
        qq{$_ ignores non-words};
    unlike
        qx{ $^X -T $ack $_ "word" t/swamp/options.pl },
        qr{notaword},
        qq{$_ ignores non-words};
    option_in_usage( $_ );
}

# Literal
for ( qw( -Q --literal ) ) {
    like
        qx{ $^X -T $ack $_ "[abc]" t/swamp/options.pl },
        qr{\Q[abc]\E},
        qq{$_ matches a literal string};
    option_in_usage( $_ );
}

my $expected = File::Next::reslash( 't/swamp/options.pl' );

# Files with matches
for ( qw( -l --files-with-matches ) ) {
    like
        qx{ $^X -T $ack $_ "use strict" t/swamp/options.pl },
        qr{\Q$expected},
        qq{$_ prints matching files};
    option_in_usage( $_ );
}

# Files without match
for ( qw( -L --files-without-match ) ) {
    like
        qx{ $^X -T $ack $_ "use snorgledork" t/swamp/options.pl },
        qr{\Q$expected},
        qq{$_ prints matching files};
    option_in_usage( $_ );
}

my $usage;
sub option_in_usage {
    my $opt = shift;

    $usage = qx{ $^X -T $ack --help } unless $usage;

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    return ok( $usage =~ qr/\Q$opt\E\b/s, "Found $opt in usage" );
}
