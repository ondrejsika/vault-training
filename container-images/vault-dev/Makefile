all: build push

build:
	docker build --platform linux/amd64 -t ondrejsika/training-vault-dev .

push:
	docker push ondrejsika/training-vault-dev
