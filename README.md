# OpenResty Docker image

### Paths & config

NginX is configured with `/opt/openresty/nginx` [prefix path](http://nginx.org/en/docs/configure.html), which means that, by default, it loads configuration from `/opt/openresty/nginx/conf/nginx.conf` file. The default HTML root path is `/opt/openresty/nginx/html/`.

OpenResty bundle includes several useful Lua modules located in `/opt/openresty/lualib/` directory. This directory is already present in Lua package path, so you don't need to specify it in NginX `lua_package_path` directive.

The Lua NginX module is built with LuaJIT 2.1, which is also available as stand-alone `lua` binary.

NginX stores various temporary files in `/var/nginx/` directory. If you wish to launch the container in [read-only mode](https://github.com/docker/docker/pull/10093), you need to convert that directory into volume to make it writable:

```sh
# To launch container
docker run --name nginx --read-only -v /var/nginx ... reuters-media/openresty-luarocks

# To remove container and its volume
docker rm -v nginx
```

### Installing LuaRocks packages

To install a package via LuaRocks:

```sh
/opt/openresty/luajit/bin/luarocks install lua-zlib
```

Note that you may also need to install dependencies.  For example for lua-zlib, you will need gcc, g++, make, and zlib-dev.


### Command-line parameters

NginX is launched with the `nginx -g 'daemon off; error_log /dev/stderr info;'` command. This means that you should not specify the `daemon` directive in your `nginx.conf` file, because it will lead to NginX config check error (duplicate directive).

No-daemon mode is needed to allow host OS' service manager, like `systemd`, or [Docker itself](http://docs.docker.com/engine/reference/commandline/cli/#restart-policies) to detect that NginX has exited and restart the container. Otherwise in-container service manager would be required.

Error log is redirected to `stderr` to simplify debugging and log collection with [Docker logging drivers](https://docs.docker.com/engine/reference/logging/overview/) or tools like [logspout](https://github.com/gliderlabs/logspout).


### Usage during development

To avoid rebuilding your Docker image after each modification of Lua code or NginX config, you can add a simple script that mounts config/content directories to appropriate locations and starts NginX:

```bash
#!/usr/bin/env bash

exec docker run --rm -it \
  --name my-app-dev \
  -v "$(pwd)/nginx/conf":/opt/openresty/nginx/conf \
  -v "$(pwd)/nginx/lualib":/opt/openresty/nginx/lualib \
  -p 8080:8080 \
  reuters-media/openresty-luarocks:latest "$@"

# you may add more -v options to mount another directories, e.g. nginx/html/

# do not do -v "$(pwd)/nginx":/opt/openresty/nginx because it will hide
# the NginX binary located at /opt/openresty/nginx/sbin/nginx
```

Place it next to your `Dockerfile`, make executable and use during development. You may also want to temporarily disable [Lua code cache](https://github.com/openresty/lua-nginx-module#lua_code_cache) to allow testing code modifications without re-starting NginX.
