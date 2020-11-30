export SHELL := /bin/sh
export NAME := proxytest
IMAGE := nginx:1.19

dist:
	mkdir -p dist

	docker pull $(IMAGE)
	docker system prune \
			-af \
			--filter "label=group=$(NAME)"
	docker network create $(NAME) \
		--label "group=$(NAME)" \
		--subnet "172.25.0.0/16"
	docker run -d --rm \
		--name site \
		--network $(NAME) \
		--label "group=$(NAME)" \
		--volume "$(PWD)/rootfs/etc/nginx/conf.d/site.conf:/etc/nginx/conf.d/default.conf:ro" \
		--publish 80 \
		$(IMAGE)
	docker run -d --rm \
		--name proxy \
		--network $(NAME) \
		--label "group=$(NAME)" \
		--volume "$(PWD)/rootfs/etc/nginx/conf.d/proxy.conf:/etc/nginx/conf.d/default.conf:ro" \
		--publish 80 \
		-- \
		$(IMAGE)

	docker port proxy
	docker port site

check:
	docker run \
		--name check \
		--rm \
		--network $(NAME) \
		--label "group=$(NAME)" \
		--volume "$(PWD)/rootfs/etc/nginx/conf.d:/etc/nginx/conf.d" \
		--publish 80 \
		-- $(IMAGE) \
		nginx -tc /etc/nginx/nginx.conf

header:
	docker port $(target) \
		| awk -F: '{ print $$NF }' \
		| xargs -I% -- curl -I localhost:%

reload:
	printf "%s\n" site proxy | xargs -n1 -I% -- docker exec % nginx -s reload

utils:
	printf "%s\n" site proxy \
		| xargs -n1 -I% -- docker exec % sh -c 'apt update; apt install -y coreutils dnsutils iproute2 netcat' _

clean:
	rm -rf dist
	docker stop site proxy
	docker system prune \
			-af \
			--volumes \
			--filter "label=group=$(NAME)"
