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

postgres-up:
	docker run --name postgres -d -e POSTGRES_PASSWORD=pg -p 5432:5432 postgres:14

postgres-create-ro:
	docker exec -u postgres postgres psql -c "CREATE ROLE \"ro\" NOINHERIT; GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"ro\";"

k8s-prod-server:
	helm repo add hashicorp https://helm.releases.hashicorp.com
	helm upgrade --install vault hashicorp/vault \
		--namespace vault \
		--create-namespace \
		-f prod-values-general.yml \
		-f prod-values-sikademo.yml

k8s-prod-server-with-injector:
	helm repo add hashicorp https://helm.releases.hashicorp.com
	helm upgrade --install vault hashicorp/vault \
		--namespace vault \
		--create-namespace \
		-f prod-values-general.yml \
		-f prod-values-sikademo.yml \
		-f prod-values-injector.yml

tergum-copy-config:
	cp tergum.example.yml tergum.yml

tergum-backup:
	tergum backup -c tergum.yml

fmt:
	terraform fmt -recursive

fmt-check:
	terraform fmt -recursive -check

setup-git-hooks:
	rm -rf .git/hooks
	(cd .git && ln -s ../.git-hooks hooks)
