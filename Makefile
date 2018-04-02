include .env
export

up: machine/create domain/delete domain/create config/push compose
	@echo "\n$(PROTOCOL)://$(NAME).$(DOMAIN)"

down: config/pull machine/delete domain/delete

# DOCKER_TLS_VERIFY=$(shell docker-machine env $(ENVIRONMENT) | grep 'DOCKER_TLS_VERIFY=".*"' | cut -d\" -f2) \

compose:
	DOCKER_HOST=$(shell docker-machine env $(NAME) | grep 'DOCKER_HOST=".*"' | cut -d\" -f2) \
	DOCKER_CERT_PATH=$(shell docker-machine env $(NAME) | grep 'DOCKER_CERT_PATH=".*"' | cut -d\" -f2) \
	docker-compose up

machine/create:
	docker-machine create $(NAME) \
	  --driver digitalocean \
	  --digitalocean-access-token $(DIGITALOCEAN_TOKEN) \
	  --digitalocean-size 2gb \
	  --digitalocean-region fra1

machine/delete:
	docker-machine rm -f $(NAME)

domain/delete:
	doctl compute domain records list $(DOMAIN) --format ID,Name | \
	  grep '\s$(NAME)$$' | \
	  awk '{print $$1;}' | \
	  xargs doctl compute domain records delete $(DOMAIN) -f

domain/create:
	doctl compute domain records create $(DOMAIN) \
	  --record-type A \
	  --record-name $(NAME) \
	  --record-data $(shell doctl compute droplet list $(NAME) \
	                              --no-header --format PublicIPv4)

domain/list:
	doctl compute domain records list $(DOMAIN) | grep '\s$(NAME)\s'

config/pull:
	mkdir -p data
	docker-machine scp -r $(NAME):/var/lib/drone/* data/

config/push:
	mkdir -p data
	docker-machine scp -r data/ $(NAME):/var/lib/drone/
