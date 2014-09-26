#!/usr/bin/make -f
#
# Build myperl and openxpki (incl. dependencies) for SuSE SLES 11
#
# USEFUL TARGETS:
#
#	# prereqs only needed first time
#	prereqs 
#
#	# this builds and installs myperl
#	git-rsync-myperl myperl
#
#	# build mysql and oracle, but don't install
#	myperl-dbd-mysql
#	oracle
#
#	# now, before building oxi, install *one* of the following:
#	inst-myperl-dbd-mysql
#	inst-myperl-dbd-oracle
#	
#	# build openxpki deps
#	oxideps
#
#	# build openxpki
#	oxi
#
# NOTES:
#
# SSHOPT is set in incl/vagrant-tasks.mk and specifies the config file to 
# use when connecting to a running vagrant instance. If this is set, the
# DEVHOST should match the instance name defined in Vagrantfile.
#	inst-oracle
#

PERL_VERSION := 5.20.0
MYPERL_RELEASE := 3
MYPERL_SRCDIR := $(HOME)/git/myperl
OXI_SRCDIR := $(HOME)/git/openxpki
OXI_VERSION := $(shell cd $(OXI_SRCDIR) && tools/vergen --format version)
KEYNANNY_SRCDIR := $(HOME)/git/KeyNanny

# If VAGDIR is set, the include file for vagrant will set DEVROOT to
# the same as DEVUSER and SUDO=sudo
DEVROOT=root


# Include file must define DEVHOST, DEVUSER and ETCDIR.
# Include file may define VAGDIR

-include Makefile.doit-oxi-suse.cust
-include Makefile.doit-oxi-suse.local

ifdef VAGDIR
	include incl/vagrant-tasks.mk
endif

RPMS := \
	myperl-$(PERL_VERSION)-$(MYPERL_RELEASE).x86_64.rpm \
	myperl-dbd-oracle-$(OXI_VERSION)-1.x86_64.rpm \
	myperl-openxpki-core-deps-$(OXI_VERSION)-1.x86_64.rpm \
	myperl-openxpki-core-$(OXI_VERSION)-1.x86_64.rpm

.PHONY: doit

doit: clean git-rsync myperl oracle inst-oracle oxideps oxi

prereqs: $(SSHCFG)
	(echo "%packager <$GIT_AUTHOR_NAME>" ; \
		echo '%_topdir %(echo "$$HOME")/rpmbuild' ) \
		| ssh $(SSHOPT) -l $(DEVUSER) $(DEVHOST) tee .rpmmacros 2>/dev/null
	
prereqs-deprecated:
	scp $(ETCDIR)/.rpmmacros $(DEVUSER)@$(DEVHOST):.
	cd $(ETCDIR) && $(MAKE) xml
	rsync -av -e "ssh -l $(DEVUSER)" $(ETCDIR)/ $(DEVHOST):build-etc
	ssh -l root $(DEVHOST) ~$(DEVUSER)/build-etc/provision.sh

git-rsync: git-rsync-myperl git-rsync-openxpki git-rsync-keynanny

git-rsync-myperl: $(SSHCFG)
	rsync -av -e "ssh $(SSHOPT) -l $(DEVUSER)" $(MYPERL_SRCDIR) $(DEVHOST):git/

git-rsync-openxpki: $(SSHCFG)
	rsync -av -e "ssh $(SSHOPT) -l $(DEVUSER)" $(OXI_SRCDIR) $(DEVHOST):git/

git-rsync-keynanny: $(SSHCFG)
	rsync -av -e "ssh $(SSHOPT) -l $(DEVUSER)" $(KEYNANNY_SRCDIR) $(DEVHOST):git/

git-pull:
	cd $(OXI_SRCDIR) && git pull --ff-only

myperl: $(SSHCFG)
	ssh $(SSHOPT) -l $(DEVUSER) $(DEVHOST) \
		"cd ~/git/myperl && make fetch-perl suse"
	ssh $(SSHOPT) -l $(DEVROOT) $(DEVHOST) \
		"$(SUDO) rpm -Uvh --oldpackage --replacepkgs ~$(DEVUSER)/git/myperl/myperl-$(PERL_VERSION)-$(MYPERL_RELEASE).x86_64.rpm"

myperl-build-tools: $(SSHCFG)
	ssh $(SSHOPT) -l $(DEVUSER) $(DEVHOST) \
		"/opt/myperl/bin/perl -I~/perl5/lib/perl5/ /usr/bin/cpanm Config::Std"

keynanny: $(SSHCFG)
	ssh $(SSHOPT) -l $(DEVUSER) $(DEVHOST) \
		"cd ~/git/KeyNanny && PATH=/opt/myperl/bin:$(PATH) make package"
#	ssh -l root $(DEVHOST) \
#		"rpm -e KeyNanny; rpm -i ~$(DEVUSER)/git/KeyNanny/KeyNanny-*.x86_64.rpm"

myperl-dbd-mysql: $(SSHCFG)
	ssh $(SSHOPT) -l $(DEVUSER) $(DEVHOST) \
		"cd ~/git/openxpki/package/suse/$@ && make"

# installs for above myperl-%
#inst-myperl-%: makefile-local
inst-myperl-%: $(SSHCFG)
	ssh $(SSHOPT) -l $(DEVROOT) $(DEVHOST) \
		"$(SUDO) rpm -Uvh --oldpackage --replacepkgs ~$(DEVUSER)/git/openxpki/package/suse/$(patsubst inst-%,%,$@)/$(patsubst inst-%,%,$@)-$(OXI_VERSION)-1.x86_64.rpm"

#oracle: makefile-local
oracle: $(SSHCFG)
	ssh $(SSHOPT) -l $(DEVUSER) $(DEVHOST) \
		"cd ~/git/openxpki/package/suse/myperl-dbd-oracle && PERL5LIB=~/perl5/lib/perl5/ make"

inst-oracle: $(SSHCFG)
	ssh $(SSHOPT) -l $(DEVROOT) $(DEVHOST) \
		"$(SUDO) rpm -Uvh --oldpackage --replacepkgs ~$(DEVUSER)/rpmbuild/RPMS/x86_64/myperl-dbd-oracle-$(OXI_VERSION)-1.x86_64.rpm"

oxideps: $(SSHCFG)
	ssh $(SSHOPT) -l $(DEVUSER) $(DEVHOST) \
		'cd ~/git/openxpki/package/suse/myperl-openxpki-core-deps && PERL5LIB=~/perl5/lib/perl5/ make'
	ssh $(SSHOPT) -l $(DEVROOT) $(DEVHOST) \
		"$(SUDO) rpm -Uvh --oldpackage --replacepkgs ~$(DEVUSER)/rpmbuild/RPMS/x86_64/myperl-openxpki-core-deps-$(OXI_VERSION)-1.x86_64.rpm"

oxi: $(SSHCFG)
	ssh $(SSHOPT) -l $(DEVUSER) $(DEVHOST) \
		"cd ~/git/openxpki/package/suse/myperl-openxpki-core && make"
	ssh $(SSHOPT) -l $(DEVROOT) $(DEVHOST) \
		"$(SUDO) rpm -Uvh --oldpackage --replacepkgs ~$(DEVUSER)/rpmbuild/RPMS/x86_64/myperl-openxpki-core-$(OXI_VERSION)-1.x86_64.rpm"

%.rpm: $(SSHCFG)
	scp $(SSHOPT) $(DEVUSER)@$(DEVHOST):rpmbuild/RPMS/x86_64/$@ .

fetch: $(RPMS)

clean: $(SSHCFG)
	ssh $(SSHOPT) -l $(DEVUSER) $(DEVHOST) \
		"rm -rf rpmbuild/BUILD/*perl* .cpanm/work/*"

############################################################
# Stuff behind here might not be tested
############################################################

qs: $(SSHCFG)
	scp -F $< ~/git/openxpki/core/config/sampledbuser.sql build:.
	ssh -F $< build \
		"sudo /opt/myperl/bin/openxpkiadm loadcfg"
	ssh -F $< build \
		"sudo cp sampledbuser.sql /usr/share/doc/libopenxpki-perl/examples/"
	ssh -F $< build \
		"sudo mysql < /usr/share/doc/libopenxpki-perl/examples/sampledbuser.sql"
	ssh -F $< build \
		"sudo /opt/myperl/bin/openxpkiadm initdb"
	ssh -F $< build \
		"sudo PATH=/opt/myperl/bin:$$PATH /usr/share/doc/libopenxpki-perl/examples/sampleconfig.sh"
	ssh -F $< build \
		"sudo /opt/myperl/bin/perl /opt/myperl/bin/openxpkictl start; ps -ef | grep openxpki | grep -v grep"

qs2: $(VAGDIR)/build.sshcfg

test: $(VAGDIR)/build.sshcfg
	ssh -F $< build \
		"cd ~/git/myperl && /opt/myperl/bin/prove"
	ssh -F $< build \
		"sudo chmod o+rw /var/openxpki/openxpki.socket && cd ~/git/openxpki/qatest && /opt/myperl/bin/prove -Ilib backend/nice/*.t"

status: $(VAGDIR)/build.sshcfg
	@echo "----------"
	ssh -F $< build \
		"cd ~/git/myperl && git log -n 1"
	@echo "----------"
	ssh -F $< build \
		"cd ~/git/openxpki && git log -n 1"
	@echo "----------"


