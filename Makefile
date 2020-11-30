.PHONY: build

.DEFAULT_GOAL := build

-include .env

PROJECT ?= sonet
INVENTORY ?= ../inventory
PLAYBOOK ?= ../playbook.yml

MAKE_VARS = \
	PROJECT=$(PROJECT) \
	INVENTORY=$(INVENTORY) \
	PLAYBOOK=$(PLAYBOOK)

init:
	$(MAKE) -C sonet $(MAKE_VARS) init

build:
	$(MAKE) -C sonet $(MAKE_VARS) build

push:
	$(MAKE) -C sonet $(MAKE_VARS) push
