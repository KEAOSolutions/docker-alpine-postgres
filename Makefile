CURRENT_DIRECTORY := $(shell pwd)
include environment

build:
	sed -i.bak 's|^FROM.*|FROM $(DOCKER_GLIBC)|' Dockerfile && \
	docker build -t $(DOCKER_USER)/postgres --rm=true . && \
	mv Dockerfile.bak Dockerfile

debug:
	docker exec -it postgres-master sh

master:
	docker run --name postgres-master -e POSTGRES_PASSWORD=$(POSTGRES_PASSWORD) -e POSTGRES_TYPE=MASTER -e POSTGRES_REPLICATION=$(POSTGRES_REPLICATION) -e POSTGRES_REPLICATION_PASSWORD=$(POSTGRES_REPLICATION_PASSWORD) -d -p $(POSTGRES_MASTER_TCP_PORT):5432 -v /tmp/postgres-master:/var/lib/postgresql/data $(DOCKER_USER)/postgres

slave:
	docker run --name postgres-slave -e POSTGRES_MASTER=$(POSTGRES_MASTER) -e POSTGRES_TYPE=SLAVE -e POSTGRES_MASTER_TCP_PORT=$(POSTGRES_MASTER_TCP_PORT) -e POSTGRES_REPLICATION_PASSWORD=$(POSTGRES_REPLICATION_PASSWORD) -d -p $(POSTGRES_SLAVE_TCP_POST):5432 -v /tmp/postgres-slave:/var/lib/postgresql/data $(DOCKER_USER)/postgres
