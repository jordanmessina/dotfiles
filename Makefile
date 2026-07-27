.PHONY: bootstrap stow test test-docker

bootstrap:
	./bootstrap.sh

stow:
	./bootstrap.sh --stow-only

test:
	./scripts/test.sh

test-docker:
	./scripts/test-docker.sh
