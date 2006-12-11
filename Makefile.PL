package main;
use 5.6.1;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'ack',
    AUTHOR              => 'Andy Lester <andy@petdance.com>',
    ABSTRACT            => 'A grep-like program specifically for large source trees',
    VERSION_FROM        => 'Ack.pm',
    PM                  => { 'Ack.pm' => '$(INST_LIBDIR)/App/Ack.pm' },
    EXE_FILES           => [ 'ack' ],
    PREREQ_PM => {
        'Term::ANSIColor'   => 0,
        'Getopt::Long'      => 0,
        'Test::More'        => 0,
        'File::Next'        => 0.32,   # For the better handling of package variables
        'File::Basename'    => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'ack-*' },
);

package MY;
sub MY::postamble {
    my $file_next_filename = qx(perldoc -l File::Next);
    my $postamble = <<"MAKE_FRAG";
.PHONY: tags critic

tags :
	ctags -f tags --recurse --totals \
		--exclude=blib --exclude=t/lib \
		--exclude=.svn --exclude='*~' \
		--languages=Perl --langmap=Perl:+.t \

critic :
	perlcritic -1 -q -profile perlcriticrc .

ACK             = ack
APP_ACK_PM      = Ack.pm
FILE_NEXT_PM    = $file_next_filename
STANDALONE      = ack-standalone

\$(STANDALONE) : \$(ACK) \$(APP_ACK_PM) \$(FILE_NEXT_PM)
	grep -v 'use App::Ack' \$(ACK) | grep -v 'use File::Next' > \$(STANDALONE)
	cat \$(FILE_NEXT_PM) \$(APP_ACK_PM) >> \$(STANDALONE)
	chmod +x \$(STANDALONE)

MAKE_FRAG

    return $postamble;
}


sub MY::top_targets {
    my $str = shift->SUPER::top_targets(@_);

    $str =~ s/^pure_all.+/$& ack-standalone/m;

    return $str;
}


1;
