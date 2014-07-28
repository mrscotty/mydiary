#!/usr/bin/make -f
#
# 2014-07-02 - building myperl and oxi
#
# Useful targets:
#
#  vag-rebuild-build
#

VAGDIR	= $(HOME)/git/vagrant/suse

.PHONY: doit

doit: vag-rebuild git-clone myperl mysql oxideps oxi qs

include incl/vagrant-tasks.mk

vag-rebuild: vag-rebuild-build

git-clone:
	cd $(VAGDIR) && \
		vagrant ssh build --command \
		"git clone /git/myperl ~/git/myperl; git clone /git/openxpki ~/git/openxpki"

git-pull:
	cd $(VAGDIR) && \
		vagrant ssh build --command \
		"cd ~/git/myperl && git pull; cd ~/git/openxpki && git pull"

myperl: $(VAGDIR)/build.sshcfg
	ssh -F $< build \
		"cd ~/git/myperl && make fetch-perl suse suse-install"

mysql: makefile-local
	cd $(VAGDIR) && \
		vagrant ssh build --command \
		"cd ~/git/openxpki/package/suse/myperl-dbd-mysql && make"
	cd $(VAGDIR) && \
		vagrant ssh build --command \
		"sudo rpm -e myperl-dbd-mysql; sudo rpm -i ~/git/openxpki/package/suse/myperl-dbd-mysql/myperl-dbd-mysql-*.x86_64.rpm"

oracle: makefile-local
	cd $(VAGDIR) && \
		vagrant ssh build --command \
		"cd ~/git/openxpki/package/suse/myperl-dbd-oracle && make"
	cd $(VAGDIR) && \
		vagrant ssh build --command \
		"sudo rpm -e myperl-dbd-oracle; sudo rpm -i ~/git/openxpki/package/suse/myperl-dbd-oracle/myperl-dbd-oracle-*.x86_64.rpm"

oxideps: makefile-local
	cd $(VAGDIR) && \
		vagrant ssh build --command \
		"cd ~/git/openxpki/package/debian/openxpki-core-deps-myperl && make package"
	cd $(VAGDIR) && \
		vagrant ssh build --command \
		"sudo dpkg -r openxpki-core-deps-myperl; sudo dpkg -i ~/git/openxpki/package/debian/openxpki-core-deps-myperl*.deb"

oxi:
	cd $(VAGDIR) && \
		vagrant ssh build --command \
		"cd ~/git/openxpki/package/debian/core && make clean all"
	cd $(VAGDIR) && \
		vagrant ssh build --command \
		"sudo dpkg -r libopenxpki-perl; sudo dpkg -i ~/git/openxpki/package/debian/core/libopenxpki-perl*.deb"

qs: $(VAGDIR)/build.sshcfg
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

fetch: $(VAGDIR)/build.sshcfg
	ssh -F $< build \
		"cp -a ~/git/openxpki/package/debian/core/libopenxpki-perl*.deb \
		~/git/openxpki/package/debian/libdbd-mysql-myperl*.deb \
		~/git/openxpki/package/debian/openxpki-core-deps-myperl*.deb \
		/vagrant/"

ssh:
	cd $(VAGDIR) && \
		vagrant ssh build

.PHONY:
makefile-local: Makefile.local $(VAGDIR)/build.sshcfg
	scp -F $(VAGDIR)/build.sshcfg $< build:git/openxpki/package/debian/


