PODMAN := podman
MAKEFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
MAKEFILE_DIR := $(dir $(MAKEFILE_PATH))

CONTAINER_IMAGE := docker.io/postgres:16.1-alpine 
CONTAINER_NAME := postgres-my-db
CONTAINER_NETWORK := postgres-my-db

POSTGRES_DATA_DIR := $(PWD)/data
POSTGRES_INIT_DIR := $(MAKEFILE_DIR)/init
PGDATA := /var/lib/postgresql/data/pgdata
LOCAL_PORT := 5432

include ./credentials.mk

.PHONY: dbclean dbclient dbstart prepare

.PHONY: default
default: help

.PHONY: help
help:
	@echo "TBD"

.PHONY: dbclean
dbclean:
	@echo "****************************************************"
	@echo "* WARNING!                                         *"
	@echo "*                                                  *"
	@echo "* THIS WILL DELETE ALL YOUR DATA!                  *"
	@echo "*                                                  *"
	@echo "* Press ^C to cancel, or 'Y' to proceed.           *"
	@echo "****************************************************"
	@$(PODMAN) unshare rm -rI $(POSTGRES_DATA_DIR) || echo "Can't remove $(POSTGRES_DATA_DIR)"
	@$(PODMAN) network rm $(CONTAINER_NETWORK) || echo "Can't remove network"

.PHONY: prepare
prepare:
	mkdir -p $(POSTGRES_DATA_DIR)
	$(PODMAN) network create $(CONTAINER_NETWORK) --driver bridge || echo "Can't create network, assuming it already exists."

.PHONY: dbstart
dbstart: prepare
	$(PODMAN) run -it \
		--name $(CONTAINER_NAME) \
		--rm \
		--network $(CONTAINER_NETWORK) \
		-e POSTGRES_USER=$(POSTGRES_USER) \
		-e POSTGRES_PASSWORD=$(POSTGRES_PASSWORD) \
		-e PGDATA=$(PGDATA) \
		-e APP_DB_USER=$(APP_DB_USER) \
		-e APP_DB_PASS=$(APP_DB_PASS) \
		-e APP_DB_NAME=$(APP_DB_NAME) \
		-v $(POSTGRES_DATA_DIR):$(PGDATA):Z \
		-v $(POSTGRES_INIT_DIR):/docker-entrypoint-initdb.d:Z \
		-p $(LOCAL_PORT):5432 \
		$(CONTAINER_IMAGE)

.PHONY: dbsh
dbsh:
	$(PODMAN) run -it --rm \
		--network $(CONTAINER_NETWORK) \
		$(CONTAINER_IMAGE) /bin/bash

.PHONY: dbclient
dbclient:
	$(PODMAN) run -it --rm \
		--network $(CONTAINER_NETWORK) \
		-e PGPASSWORD=$(APP_DB_PASS) \
		$(CONTAINER_IMAGE) psql -h $(CONTAINER_NAME) -U $(APP_DB_USER) -d $(APP_DB_NAME)

.PHONY: prepare	
dbclient_root:
	$(PODMAN) run -it --rm \
		--network $(CONTAINER_NETWORK) \
		-e PGPASSWORD=$(POSTGRES_PASSWORD) \
		$(CONTAINER_IMAGE) psql -h $(CONTAINER_NAME) -U $(POSTGRES_USER)
	
