.PHONY: build venv

.DEFAULT_GOAL := help

-include .env

PROJECT ?= sonet
INVENTORY ?= ../inventory
PLAYBOOK ?= ../configs/sonet_local/playbook.yml
ANSIBLE_ASK_BECOME_PASS ?= 0
ANSIBLE_VAULT_CLIENT_SCRIPT ?= ./tools/vault-env-client.py
ANSIBLE_VAULT_PASSWORD ?= sonet
ANSIBLE_PYTHON_INTERPRETE ?= python3
LOCAL_DOCKER_REGISTRY_ADDR ?= registry.sonet.local
LOCAL_DOCKER_REGISTRY_PORT ?= 5000
LOCAL_DOCKER_REGISTRY_BIND_IP ?= 127.0.0.1
ANSIBLE_PLAYBOOK ?= ansible-playbook
VENV_DIR ?= venv

REGISTRY_CONTAINER_NAME ?= $(PROJECT)-registry
REGISTRY_DATA_DIR ?= $(shell pwd)/registry

MAKE_VARS = \
	PROJECT=$(PROJECT) \
	INVENTORY=$(INVENTORY) \
	PLAYBOOK=$(PLAYBOOK) \
	ANSIBLE_ASK_BECOME_PASS=$(ANSIBLE_ASK_BECOME_PASS) \
	ANSIBLE_PYTHON_INTERPRETE=$(ANSIBLE_PYTHON_INTERPRETE) \
	LOCAL_DOCKER_REGISTRY_ADDR=$(LOCAL_DOCKER_REGISTRY_ADDR) \
	LOCAL_DOCKER_REGISTRY_BIND_IP=$(LOCAL_DOCKER_REGISTRY_BIND_IP) \
	LOCAL_DOCKER_REGISTRY_PORT=$(LOCAL_DOCKER_REGISTRY_PORT) \
	ANSIBLE_PLAYBOOK=$(ANSIBLE_PLAYBOOK) \
	ANSIBLE_VAULT_PASSWORD=$(ANSIBLE_VAULT_PASSWORD) \
	ANSIBLE_VAULT_CLIENT_SCRIPT=$(ANSIBLE_VAULT_CLIENT_SCRIPT) \
	VENV_DIR=$(VENV_DIR) \
	REGISTRY_CONTAINER_NAME=$(REGISTRY_CONTAINER_NAME) \
	REGISTRY_DATA_DIR=$(REGISTRY_DATA_DIR)

define PRINT_HELP_PYSCRIPT
import re, sys

for line in sys.stdin:
	match = re.match(r'^([a-zA-Z_-]+):.*?## (.*)$$', line)
	if match:
		target, help = match.groups()
		print("%-20s %s" % (target, help))
endef
export PRINT_HELP_PYSCRIPT

help:
	@python -c "$$PRINT_HELP_PYSCRIPT" < $(MAKEFILE_LIST)

venv:  ## make python virtualenv
	python3 -m venv ${VENV_DIR} && \
	./${VENV_DIR}/bin/pip install -U pip pip-tools && \
	./${VENV_DIR}/bin/pip install -r ./sonet/requirements.txt

lint:  ## lint ansible and yaml files
	yamllint .
	$(MAKE) -C sonet $(MAKE_VARS) lint

registry-start: ## start local docker registry
	$(MAKE) -C sonet $(MAKE_VARS) registry-start

registry-stop: ## stop local docker registry
	$(MAKE) -C sonet $(MAKE_VARS) registry-stop

init:  ## create folders and generate configs
	$(MAKE) -C sonet $(MAKE_VARS) init

build:  ## build all docker images
	$(MAKE) -C sonet $(MAKE_VARS) build

push:  ## push docker images to local registry
	$(MAKE) -C sonet $(MAKE_VARS) push
