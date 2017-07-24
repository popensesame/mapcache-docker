FROM gdal-docker:2.2.1

RUN apt-get update && apt-get install -y \
	libfcgi-dev \
	fcgiwrap \
	libtiff-dev \
	cmake \
	libapr1-dev \
	libaprutil1-dev \
	nginx

ENV BUILD_DIR=/tmp/build
ENV MAPCACHE_CONFIG_FILE=/usr/local/src/mapcache/mapcache.xml

ADD . $BUILD_DIR/mapcache-docker
ADD ./mapcache.xml $MAPCACHE_CONFIG_FILE

RUN cd $BUILD_DIR && git clone https://github.com/mapserver/mapcache.git && \
    cd mapcache && git checkout branch-1-4 && mkdir build

RUN cd $BUILD_DIR/mapcache/build && cmake .. \
     -DWITH_PIXMAN=1 \
     -DWITH_OGR=1 \
     -DWITH_GEOS=1 \
     -DWITH_PCRE=1 \
     -DWITH_FCGI=1 \
     -DWITH_TIFF=1 \
     -DWITH_TIFF_WRITE_SUPPORT=0 \
     -DWITH_GEOTIFF=0 \
     -DWITH_SQLITE=0 \
     -DWITH_MEMCACHE=0 \
     -DWITH_APACHE=0 \
     -DWITH_VERSION_STRING=0 \
     -DWITH_MAPSERVER=0

RUN cd $BUILD_DIR/mapcache/build && make

RUN cd $BUILD_DIR/mapcache/build && make install

RUN cd $BUILD_DIR/mapcache-docker && \
    cp mapcache.conf /etc/nginx/sites-available/mapcache && \
    ln -s /etc/nginx/sites-available/mapcache /etc/nginx/sites-enabled/mapcache && \
    rm /etc/nginx/sites-enabled/default

RUN service fcgiwrap start
RUN service nginx restart

RUN chown www-data:www-data /var/run/fcgiwrap.socket && \
    chmod og+rw /var/run/fcgiwrap.socket

RUN echo "Hello World" > /var/www/html/test && \
    chown root:www-data /var/www/html/test
