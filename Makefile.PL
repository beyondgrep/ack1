package main;

require 5.006001;

use strict;
use warnings;
use ExtUtils::MakeMaker;

my %parms = (
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

if ( $ExtUtils::MakeMaker::VERSION =~ /^\d\.\d\d$/ and $ExtUtils::MakeMaker::VERSION > 6.30 ) {
    $parms{LICENSE} = 'perl';
}

if ( $ExtUtils::MakeMaker::VERSION ge '6.36' ) {
    $parms{EXTRA_META} = <<EOF;
resources:
    homepage: http://petdance.com/ack/
    bugtracker: http://code.google.com/p/ack/issues/list
    license: http://dev.perl.org/licenses/
    Repository: http://code.google.com/p/ack/source
    MailingList: http://groups.google.com/group/ack-users
EOF
    }

WriteMakefile( %parms );

package MY;

sub MY::top_targets {
    my $str = shift->SUPER::top_targets(@_);

    $str =~ s/^pure_all.+/$& ack-standalone ack-help.txt ack-help-types.txt/m;

    return $str;
}

sub MY::postamble {
    my $file_next_filename = qx(perldoc -l File::Next);
    my $postamble = <<'MAKE_FRAG';
ACK             = ack
APP_ACK_PM      = Ack.pm
STANDALONE      = ack-standalone
ACK_HELP        = ack-help.txt
ACK_HELP_TYPES  = ack-help-types.txt
PERL_T          = $(PERL) -T

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

PROF_ARGS = ack-standalone --noenv --color --group -w foo ~/parrot

timed: all
	$(PERL) $(PROF_ARGS) >> /dev/null 2>&1

dprof: all
	$(PERL) -d:DProf $(PROF_ARGS) >> /dev/null 2>&1
	dprofpp -R

dproflb: all
	$(PERL) -d:DProfLB $(PROF_ARGS) >> /dev/null 2>&1
	dprofpp -R

fastprof: all
	$(PERL) -d:FastProf $(PROF_ARGS) >> /dev/null 2>&1
	fprofpp

profile: all
	$(PERL) -d:Profile $(PROF_ARGS) >> /dev/null 2>&1
	less prof.out

profiler: all
	$(PERL) -MDevel::Profiler $(PROF_ARGS) >> /dev/null 2>&1
	dprofpp -R

smallprof: all
	$(PERL) -d:SmallProf $(PROF_ARGS) >> /dev/null 2>&1
	sort -k 2nr,2 smallprof.out | less

nytprof: all
	$(PERL) -d:NYTProf $(PROF_ARGS) >> /dev/null 2>&1
	nytprofhtml

$(STANDALONE) : $(ACK) $(APP_ACK_PM) squash Makefile
	$(PERL) squash ack File::Next $(APP_ACK_PM) > $(STANDALONE)
	$(CHMOD) 0755 $(STANDALONE)
	$(PERL_T) -c $(STANDALONE)

$(ACK_HELP) : $(STANDALONE)
	$(PERL_T) $(STANDALONE) --help > $(ACK_HELP) || perl -e0

$(ACK_HELP_TYPES) : $(STANDALONE)
	$(PERL_T) $(STANDALONE) --help=types > $(ACK_HELP_TYPES) || perl -e0

MAKE_FRAG

    return $postamble;
}

1;
