FROM gdal-docker:2.2.1

ENV build_dir=/tmp/build/

ADD . $build_dir/mapcache-docker

RUN mkdir /usr/local/src/mapcache && \
    cd $build_dir/mapcache-docker && \
    cp mapcache.xml /usr/local/src/mapcache/mapcache.xml

RUN apt-get update && apt-get install -y \
	libfcgi-dev \
	fcgiwrap \
	libtiff-dev \
	cmake \
	libapr1-dev \
	libaprutil1-dev \
	nginx

RUN cd $build_dir && git clone https://github.com/mapserver/mapcache.git
RUN cd $build_dir && cd mapcache && git checkout branch-1-4 && mkdir build

RUN cd $build_dir/mapcache/build && cmake .. \
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

RUN cd $build_dir/mapcache/build && make

RUN cd $build_dir/mapcache/build && make install

RUN cd $build_dir/mapcache-docker && \
    cp mapcache.conf /etc/nginx/sites-available/mapcache && \
    ln -s /etc/nginx/sites-available/mapcache /etc/nginx/sites-enabled/mapcache && \
    rm /etc/nginx/sites-enabled/default

RUN service fcgiwrap start

RUN service nginx restart


