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
	helm upgrade --install \
		vault \
		--repo https://helm.releases.hashicorp.com vault \
		--namespace vault \
		--create-namespace \
		-f examples/k8s/general.values.yml \
		-f examples/k8s/sikademo.values.yml

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
