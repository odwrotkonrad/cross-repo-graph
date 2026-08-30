##[>] 🤖🤖
SHELL := zsh
.SHELLFLAGS := -c
COMMANDS := che-install generic-setup
.PHONY: $(COMMANDS)
-include shared/generic/make/generic.mk

##[>] Setup [genai-include]
#[what] install the latest released che into ~/.local/bin, only when the one on PATH is older
che-install:
	@curl -fsSL https://konradodwrot.gitlab.io/go-modules/che-install.sh | sh -s -- --skip-if-present-is-newer

#[what] render the generic consumer payload (generic.mk, lefthook.yml, shared/generic/) at the pinned CENTRALIZED_ASSETS_GENERIC_REF
generic-setup:
	@$${BIN_CHE:-che} render-templates --profiles=generic/setup
shared/generic/make/generic.mk: generic-setup
##[<] Setup
##[<] 🤖🤖
