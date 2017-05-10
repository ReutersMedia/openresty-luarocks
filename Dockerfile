FROM alpine:3.3

ENV OPENRESTY_VERSION=1.9.7.4 \
    OPENRESTY_PREFIX=/opt/openresty \
    NGINX_PREFIX=/opt/openresty/nginx \
    VAR_PREFIX=/var/nginx

# NginX prefix is automatically set by OpenResty to $OPENRESTY_PREFIX/nginx
# look for $ngx_prefix in https://github.com/openresty/ngx_openresty/blob/master/util/configure

RUN echo "==> Installing dependencies..." \
 && apk update \
 && apk upgrade \
 && apk add curl \
 && apk add --virtual build-deps \
    make gcc musl-dev \
    pcre-dev openssl-dev zlib-dev ncurses-dev readline-dev perl \
 && mkdir -p /root/ngx_openresty \
 && cd /root/ngx_openresty \
 && echo "==> Downloading OpenResty..." \
 && curl -sSL http://openresty.org/download/openresty-${OPENRESTY_VERSION}.tar.gz | tar -xvz \
 && cd openresty-* \
 && echo "==> Configuring OpenResty..." \
 && readonly NPROC=$(grep -c ^processor /proc/cpuinfo 2>/dev/null || 1) \
 && echo "using upto $NPROC threads" \
 && ./configure \
    --prefix=$OPENRESTY_PREFIX \
    --http-client-body-temp-path=$VAR_PREFIX/client_body_temp \
    --http-proxy-temp-path=$VAR_PREFIX/proxy_temp \
    --http-log-path=$VAR_PREFIX/access.log \
    --error-log-path=$VAR_PREFIX/error.log \
    --pid-path=$VAR_PREFIX/nginx.pid \
    --lock-path=$VAR_PREFIX/nginx.lock \
    --with-luajit \
    --with-pcre-jit \
    --with-ipv6 \
    --with-http_ssl_module \
    --without-http_ssi_module \
    --without-http_userid_module \
    --without-http_uwsgi_module \
    --without-http_scgi_module \
    -j${NPROC} \
    
 && echo "==> Building OpenResty..." \
 && make -j${NPROC} install \
 && ln -sf $NGINX_PREFIX/sbin/nginx /usr/local/bin/nginx \
 && ln -sf $NGINX_PREFIX/sbin/nginx /usr/local/bin/openresty \
 && ln -sf $OPENRESTY_PREFIX/bin/resty /usr/local/bin/resty \
 && ln -sf $OPENRESTY_PREFIX/luajit/bin/luajit-* $OPENRESTY_PREFIX/luajit/bin/lua \
 && ln -sf $OPENRESTY_PREFIX/luajit/bin/luajit-* /usr/local/bin/lua \
 && echo "==> Adding LuaRocks..." \
 && cd /tmp \
 && curl -sSL http://keplerproject.github.io/luarocks/releases/luarocks-2.3.0.tar.gz | tar -xvz \ 
 && cd luarocks-* \
 && ./configure --prefix=/opt/openresty/luajit \
  		--with-lua=/opt/openresty/luajit \
    		--lua-suffix=jit-2.1.0-beta1 \
		--with-lua-include=/opt/openresty/luajit/include/luajit-2.1 \
 && make install \
 && rm -rf /tmp/luarocks-* \
 && rm -rf /root/ngx_openresty \
 && apk del build-deps \
 && apk add libpcrecpp libpcre16 libpcre32 openssl libssl1.0 pcre libgcc libstdc++ git curl unzip \
 && rm -rf /var/cache/apk/* 


# leave build tools installed, as some required for luarocks builds
# to install e.g. lua-zlib.  git and curl
# 
# /opt/openresty/luajit/bin/luarocks install lua-zlib
#

CMD ["nginx", "-g", "daemon off; error_log /dev/stderr info;"]
