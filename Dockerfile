FROM debian:stable

# Install dependencies

ADD ./before_install.sh /tmp/before_install.sh
RUN /bin/bash /tmp/before_install.sh


# Install Mapcache

ENV BUILD_DIR=/tmp/build
ENV MAPCACHE_CONF=/var/www/html/mapcache/mapcache.xml

# Cmake options
ENV WITH_FCGI=0
ENV WITH_APACHE=1

# Checkout mapcache 1.6 source
RUN mkdir $BUILD_DIR && cd $BUILD_DIR && \
    git clone https://github.com/mapserver/mapcache.git && \
    cd mapcache && \
    git checkout branch-1-6 && \
    mkdir build

RUN cd $BUILD_DIR/mapcache/build && \
    cmake .. \
     -DCMAKE_INSTALL_PREFIX=/usr \
     -DWITH_FCGI=$WITH_FCGI \
     -DWITH_APACHE=$WITH_APACHE \
     -DWITH_OGR=1 \
     -DWITH_GEOS=1 \
     -DWITH_PIXMAN=1 \
     -DWITH_TIFF=1 \
     -DWITH_GEOTIFF=1 \
     -DWITH_PCRE=0 \
     -DWITH_SQLITE=0 \
     -DWITH_MEMCACHE=0 \
     -DWITH_MAPSERVER=0 \
     -DWITH_TIFF_WRITE_SUPPORT=0 \
     -DWITH_VERSION_STRING=0

RUN cd $BUILD_DIR/mapcache/build && \
    make && \
    make install && \
    ldconfig


# Test mapcache seeder

ENV TILESET_NAME=MeanNDVI
ENV ZOOM_LEVEL_END=3

RUN cd /

ADD ./mapcache.xml $MAPCACHE_CONF

RUN mkdir /var/www/html/mapcache/cache

RUN mapcache_seed -c $MAPCACHE_CONF -t $TILESET_NAME --force -z 0,$ZOOM_LEVEL_END

# Install NGINX

ENV NGINX_MAPCACHE_MOD_PATH=$BUILD_DIR/mapcache/build/nginx

RUN useradd -r nginx

RUN cd $BUILD_DIR && \
    curl -O http://nginx.org/download/nginx-1.12.1.tar.gz && \
    tar -xvzf nginx-1.12.1.tar.gz && \
    cd nginx-1.12.1 && \
    ./configure \
        --add-module=$NGINX_MAPCACHE_MOD_PATH \
        --sbin-path=/usr/local/sbin/nginx \
        --user=nginx \
        --group=nginx \
        --with-debug \
        --with-file-aio \
        --with-pcre \
        --with-http_ssl_module \
    && make && make install 

ADD ./nginx-init /etc/init.d/nginx
RUN chmod +x /etc/init.d/nginx
RUN /usr/sbin/update-rc.d -f nginx defaults

ADD ./nginx.conf /usr/local/nginx/conf/nginx.conf

RUN chown -R nginx:nginx /var/www/html/mapcache

EXPOSE 80


