CACHE_DIR ?= $(PWD)/.cache
ARGBASH_VERSION := 2.8.1
ARGBASH_HOME ?= $(CACHE_DIR)/argbash
ARGBASH ?= $(ARGBASH_HOME)/bin/argbash
DOCKER_DROPBEAR_STATIC ?= $(PWD)/docker-dropbear-static

.PHONY: render clean_cache clean

$(ARGBASH):
	mkdir -p $(ARGBASH_HOME)
	curl -LO https://github.com/matejak/argbash/archive/$(ARGBASH_VERSION).tar.gz
	tar -C $(ARGBASH_HOME) -xvf $(ARGBASH_VERSION).tar.gz --strip 1
	rm $(ARGBASH_VERSION).tar.gz

render: bin/kubectl-sshd bin/static-dropbear

bin:
	mkdir bin/

bin/kubectl-sshd: bin $(ARGBASH)
	$(ARGBASH) kubectl-sshd.m4 -o bin/kubectl-sshd

submodules:
	git submodule update

bin/static-dropbear: bin submodules
	$(eval IMAGE_ID=$(shell docker build -q -f $(DOCKER_DROPBEAR_STATIC)/Dockerfile .))
	$(eval CONTAINER_ID=$(shell docker create $(IMAGE_ID)))
	docker cp $(CONTAINER_ID):/bin/dropbearmulti bin/static-dropbear
	docker rm $(CONTAINER_ID)

clean:
	rm -rf bin/

clean_cache:
	rm -rf $(CACHE_DIR)
