local-dev-server:
	vault server -dev -dev-root-token-id root

docker-dev-server-up:
	docker run -d --name vault-dev -p 8200:8200 vault server -dev -dev-root-token-id root -dev-listen-address 0.0.0.0:8200

docker-dev-server-logs:
	docker logs -f vault-dev

docker-dev-server-down:
	docker rm -f vault-dev
