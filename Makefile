local-dev-server:
	vault server -dev -dev-root-token-id root

docker-dev-server-up:
	docker run -d --name vault-dev -p 8200:8200 ondrejsika/training-vault-dev

docker-dev-server-shell:
	docker exec -ti vault-dev bash

docker-dev-server-logs:
	docker logs -f vault-dev

docker-dev-server-down:
	docker rm -f vault-dev
