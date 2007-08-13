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
        'Test::Harness'     => 2.50, # Something reasonably newish
        'Term::ANSIColor'   => 0,
        'Getopt::Long'      => 0,
        'Test::More'        => 0,
        'File::Next'        => 0.40, # Handle files called "0"
        'File::Basename'    => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'ack-1*' },
);

package MY;

sub MY::top_targets {
    my $str = shift->SUPER::top_targets(@_);

    $str =~ s/^pure_all.+/$& ack-standalone ack-help.txt ack-help-types.txt/m;

    return $str;
}

sub MY::postamble {
    my $file_next_filename = qx(perldoc -l File::Next);
    my $postamble = <<'MAKE_FRAG';
.PHONY: tags critic

tags:
	ctags -f tags --recurse --totals \
		--exclude=blib \
		--exclude=.svn \
		--exclude='*~' \
		--exclude=ack-standalone \
		--languages=Perl --langmap=Perl:+.t \

critic:
	perlcritic -1 -q -profile perlcriticrc ack Ack.pm t/*.t

prof: all
	perl -d:DProf -Mblib ack -w foo ~/parrot >> /dev/null 2>&1
	dprofpp

ACK             = ack
APP_ACK_PM      = Ack.pm
STANDALONE      = ack-standalone
ACK_HELP        = ack-help.txt
ACK_HELP_TYPES  = ack-help-types.txt

$(STANDALONE) : $(ACK) $(APP_ACK_PM) squash Makefile
	$(PERL) squash ack File::Next $(APP_ACK_PM) > $(STANDALONE)
	$(CHMOD) +x $(STANDALONE)
	$(PERL) -c $(STANDALONE)

$(ACK_HELP) : $(STANDALONE)
	$(PERL) $(STANDALONE) --help > $(ACK_HELP) || perl -e0

$(ACK_HELP_TYPES) : $(STANDALONE)
	$(PERL) $(STANDALONE) --help=types > $(ACK_HELP_TYPES) || perl -e0

MAKE_FRAG

    return $postamble;
}

1;
