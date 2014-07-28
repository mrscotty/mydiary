# makefile targets for using Vagrant
#
# Some targets support the 'instance' name...

ifndef VAGDIR
	VAGDIR = $(PWD)
endif

$(VAGDIR)/%.sshcfg:
	(cd $(VAGDIR) && vagrant ssh-config $*) > $@.tmp
	mv $@.tmp $@

vag-halt-%:
	cd $(VAGDIR) && \
		vagrant halt -f $*

vag-up-%:
	cd $(VAGDIR) && \
		vagrant up $*

vag-ssh-%: $(VAGDIR)/%.sshcfg
	ssh -F $< $*

vag-rebuild-%: vag-clean-%
	cd $(VAGDIR) && \
		vagrant destroy -f $*
	cd $(VAGDIR) && \
		vagrant up $*

.PHONY: vag-status

vag-status:
	cd $(VAGDIR) && \
		vagrant status

.PHONY: vag-clean-%

vag-clean-%:
	rm -f $(VAGDIR)/$*.sshcfg

