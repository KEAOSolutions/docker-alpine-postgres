CURRENT_DIRECTORY := $(shell pwd)
include environment

build:
	sed -i.bak 's|^FROM.*|FROM $(DOCKER_GLIBC)|' Dockerfile && \
	docker build -t $(DOCKER_USER)/postgres --rm=true . && \
	mv Dockerfile.bak Dockerfile

debug:
	docker exec -it postgres-master sh

master:
	docker run --name postgres-master -e POSTGRES_PASSWORD=$(POSTGRES_ENC_PASSWORD) -e POSTGRES_TYPE=MASTER -e POSTGRES_REPLICATION=ON -e POSTGRES_REPLICATION_PASSWORD=$(POSTGRES_ENC_REPLICATION_PASSWORD) -d -p 5432:5432 -v /tmp/postgres-master:/var/lib/postgresql/data $(DOCKER_USER)/postgres

slave:
	docker run --name postgres-slave -e POSTGRES_MASTER=$(POSTGRES_MASTER) -e POSTGRES_TYPE=SLAVE -e POSTGRES_MASTER_TCP_PORT=5432 -e POSTGRES_REPLICATION_PASSWORD=$(POSTGRES_REPLCATION_PASSWORD) -d -p 15432:5432 -v /tmp/postgres-slave:/var/lib/postgresql/data keaosolutions/postgres
