include .env
export

up: create_machine delete_domain_record create_domain_record compose

down: delete_machine delete_domain_record

compose:
	DOCKER_HOST=$(shell docker-machine env $(NAME) | grep 'DOCKER_HOST=".*"' | cut -d\" -f2) \
	DOCKER_CERT_PATH=$(shell docker-machine env $(NAME) | grep 'DOCKER_CERT_PATH=".*"' | cut -d\" -f2) \
	DOCKER_TLS_VERIFY=$(shell docker-machine env $(ENVIRONMENT) | grep 'DOCKER_TLS_VERIFY=".*"' | cut -d\" -f2) \
	docker-compose up

create_machine:
	docker-machine create $(NAME) \
		--driver digitalocean \
		--digitalocean-access-token $(DIGITALOCEAN_TOKEN) \
		--digitalocean-size 1gb \
		--digitalocean-region fra1

delete_machine:
	docker-machine rm -f $(NAME)

delete_domain_record:
	doctl compute domain records list $(DOMAIN) --format ID,Name | \
		grep '\s$(NAME)$$' | \
		awk '{print $$1;}' | \
		xargs doctl compute domain records delete $(DOMAIN) -f

create_domain_record:
	doctl compute domain records create $(DOMAIN) \
		--record-type A \
		--record-name $(NAME) \
		--record-data ${shell doctl compute droplet list $(NAME) --no-header --format PublicIPv4}
	sleep 10

list_domain_records:
	doctl compute domain records list $(DOMAIN) | grep '\s$(NAME)\s'
