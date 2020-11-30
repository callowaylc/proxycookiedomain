# Proxy Cookie Domain

Example of nginx proxy_cookie_domain using two nginx containers to simulate proxy and target sites

## Requirements

- Docker
```sh
$ docker -v
Docker version 19.03.13, build 4484c46d9d
```
- Bash
```sh
$ bash --version
GNU bash, version 5.0.18(1)-release (x86_64-apple-darwin17.7.0)
```
\* versions tested

## Usage

- Install containers `make`.
```sh
$ make
mkdir -p dist
docker pull nginx:1.19
...
docker port proxy
80/tcp -> 0.0.0.0:34182
docker port site
80/tcp -> 0.0.0.0:34181
```
\* Port values will be different

- Check installation (and configuration) `make check`.
```sh
$ make check
docker run \
		--name check \
...
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

- Review target site headers `make header target=site`.
```sh
$ make header target=site
docker port site \
		| awk -F: '{ print $NF }' \
		| xargs -I% -- curl -I localhost:%
HTTP/1.1 200 OK
...
Set-Cookie: cookiename=cookievalue; Domain=site
```

- Review proxy headers `make header target=proxy`.
```sh
$ make header target=proxy
docker port proxy \
		| awk -F: '{ print $NF }' \
		| xargs -I% -- curl -I localhost:%
HTTP/1.1 200 OK
...
Set-Cookie: cookiename=cookievalue; Domain=proxy
```

- Cleanup
```sh
$ make clean
rm -rf dist
docker stop site proxy
site
proxy
docker system prune \
			-af \
			--volumes \
			--filter "label=group=proxytest"
Deleted Networks:
proxytest

Total reclaimed space: 0B
```

## Dev

You can use `make check` and `make reload` to check modified configuration and reload against running daemons, respectively.

- Confirm configuration and service is loaded.
```sh
$ make check
docker run \
		--name check \
...
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

- Introduce error to configuration and check configuration
```sh
$ echo fubar >>rootfs/etc/nginx/conf.d/proxy.conf
$ make check
docker run \
		--name check \
...
2020/11/30 22:51:54 [emerg] 1#1: unexpected end of file, expecting ";" or "}" in /etc/nginx/conf.d/proxy.conf:13
nginx: [emerg] unexpected end of file, expecting ";" or "}" in /etc/nginx/conf.d/proxy.conf:13
nginx: configuration file /etc/nginx/nginx.conf test failed
make: *** [check] Error 1
```
