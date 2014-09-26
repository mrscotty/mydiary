# makefile targets for using Vagrant
#
# Some targets support the 'instance' name...

ifndef VAGDIR
	VAGDIR = $(PWD)
endif

ifndef VAGINST
	VAGINST = default
endif

SSHCFG = $(VAGDIR)/$(VAGINST).sshcfg
SSHOPT = -F $(SSHCFG)
DEVUSER = vagrant
DEVROOT = vagrant
SUDO = sudo
DEVHOST = $(VAGINST)

$(VAGDIR)/%.sshcfg: $(VAGDIR)/machines/%/$(VAGPROV)/id
	(cd $(VAGDIR) && vagrant ssh-config $*) > $@.tmp
	mv $@.tmp $@

vag-halt-%:
	cd $(VAGDIR) && \
		vagrant halt -f $*

$(VAGDIR)/machines/%/$(VAGPROV)/id:
	echo "'vagrant up $*' creates $@"
	cd $(VAGDIR) && \
		vagrant up $*

vag-up-%: $(VAGDIR)/machines/%/$(VAGPROV)/id

vag-ssh-%: $(VAGDIR)/%.sshcfg
	ssh -F $< $*

.PHONY: vag-destroy-%

vag-destroy-%: vag-clean-%
	cd $(VAGDIR) && \
		vagrant destroy -f $*

vag-rebuild-%: vag-destroy-%
	cd $(VAGDIR) && \
		vagrant up $*

.PHONY: vag-status

vag-status:
	cd $(VAGDIR) && \
		vagrant status

.PHONY: vag-clean-%

vag-clean-%:
	rm -f $(VAGDIR)/$*.sshcfg

