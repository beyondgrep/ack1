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
    PM                  => {
        'Ack.pm'        => '$(INST_LIBDIR)/App/Ack.pm',
        'Repository.pm' => '$(INST_LIBDIR)/App/Ack/Repository.pm',
        'Resource.pm'   => '$(INST_LIBDIR)/App/Ack/Resource.pm',
        'Plugin.pm'     => '$(INST_LIBDIR)/App/Ack/Plugin.pm',
        'Basic.pm'      => '$(INST_LIBDIR)/App/Ack/Plugin/Basic.pm',
        #'Tar.pm'        => '$(INST_LIBDIR)/App/Ack/Plugin/Tar.pm',
    },
    EXE_FILES           => [ 'ack' ],
    PREREQ_PM => {
        'Test::Harness'     => 2.50, # Something reasonably newish
        'Term::ANSIColor'   => 0,
        'Getopt::Long'      => 0,
        'Test::More'        => 0,
        'File::Next'        => 0.40, # Handle files called "0"
        'File::Basename'    => 0,
        'Pod::Usage'        => 0,
    },
    MAN3PODS            => {}, # no need for man pages for any of the .pm files
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'ack-1* nytprof*' },
);

if ( $ExtUtils::MakeMaker::VERSION =~ /^\d\.\d\d$/ and $ExtUtils::MakeMaker::VERSION > 6.30 ) {
    $parms{LICENSE} = 'artistic_2';
}

if ( $ExtUtils::MakeMaker::VERSION ge '6.46' ) {
    $parms{META_MERGE} = {
        resources => {
            homepage    => 'http://betterthangrep.com/',
            bugtracker  => 'http://github.com/petdance/ack',
            license     => 'http://www.opensource.org/licenses/artistic-license-2.0.php',
            repository  => 'git://github.com/petdance/ack.git',
        }
    };
}

WriteMakefile( %parms );

package MY;

sub MY::top_targets {
    my $str = shift->SUPER::top_targets(@_);

    $str =~ s/^pure_all.+/$& ack ack-help.txt ack-help-types.txt ack-help-dirs.txt/m;

    return $str;
}

sub MY::postamble {
    my $file_next_filename = qx(perldoc -l File::Next);
    my $postamble = <<'MAKE_FRAG';
ACK             = ack
BASE            = ack-base
ACK_PM          = Ack.pm
BASIC_PM        = Basic.pm
REPOSITORY_PM   = Repository.pm
RESOURCE_PM     = Resource.pm
ALL_PM          = $(ACK_PM) $(REPOSITORY_PM) $(RESOURCE_PM) $(BASIC_PM)
ACK_HELP        = ack-help.txt
ACK_HELP_TYPES  = ack-help-types.txt
ACK_HELP_DIRS   = ack-help-dirs.txt
PERL_T          = $(PERL) -T

.PHONY: tags critic

tags:
	ctags -f tags --recurse --totals \
		--exclude=blib \
		--exclude=.git \
		--exclude='*~' \
		--exclude=$(ACK) \
		--languages=Perl --langmap=Perl:+.t \

critic:
	perlcritic -1 -q -profile perlcriticrc $(BASE) $(ALL_PM) t/*.t

tidy:
	perltidy -b -pro=perltidyrc $(BASE) $(ALL_PM)

PROF_ARGS = -Mblib ./$(ACK) --noenv --color --group -w foo ~/parrot

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

$(ACK) : $(BASE) $(ALL_PM) squash Makefile
	$(PERL) squash ack-base File::Next $(ALL_PM) > $(ACK)
	$(CHMOD) 0755 $(ACK)
	$(PERL_T) -c $(ACK)

$(ACK_HELP) : $(ACK)
	$(PERL_T) $(ACK) --noenv --help > $(ACK_HELP) || perl -e0

$(ACK_HELP_TYPES) : $(ACK)
	$(PERL_T) $(ACK) --noenv --help=types > $(ACK_HELP_TYPES) || perl -e0

$(ACK_HELP_DIRS) : $(ACK)
	$(PERL_T) $(ACK) --noenv --help=dirs > $(ACK_HELP_DIRS) || perl -e0

MAKE_FRAG

    return $postamble;
}

1;
