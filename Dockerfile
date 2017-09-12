FROM debian:stable

ENV BUILD_DIR=/tmp/build
ENV MAPCACHE_CONF=/var/www/html/mapcache/mapcache.xml
ENV TILESET_NAME=MeanNDVI
ENV ZOOM_LEVEL_END=3

# Dependencies

RUN apt-get update && apt-get install -y \
  cmake \
  build-essential \
  git \
  apache2-dev \
  libproj-dev \
  libtiff-dev \
  libapr1-dev \
  libaprutil1-dev \
  libpng-dev \
  libjpeg62-turbo-dev \
  libpcre3-dev \
  libpixman-1-dev \
  libgeotiff-dev \
  libgeos-dev \
  libgdal-dev 

RUN apt-get update && apt-get install -y \
    libxml2-utils \
    apache2 \
    gdal-bin

# Build Mapcache

RUN mkdir $BUILD_DIR && cd $BUILD_DIR && \
    git clone https://github.com/mapserver/mapcache.git && \
    cd mapcache && \
    git checkout branch-1-6 && \
    mkdir build

RUN cd $BUILD_DIR/mapcache/build && \
    cmake .. \
     -DCMAKE_INSTALL_PREFIX=/usr \
     -DWITH_APACHE=1 \
     -DWITH_OGR=1 \
     -DWITH_GEOS=1 \
     -DWITH_PCRE=1 \
     -DWITH_PIXMAN=1 \
     -DWITH_TIFF=1 \
     -DWITH_GEOTIFF=1 \
     -DWITH_FCGI=0 \
     -DWITH_SQLITE=0 \
     -DWITH_MEMCACHE=0 \
     -DWITH_MAPSERVER=0 \
     -DWITH_TIFF_WRITE_SUPPORT=0 \
     -DWITH_VERSION_STRING=0

RUN cd $BUILD_DIR/mapcache/build && \
    make && make install && ldconfig

# Configure Apache

RUN echo "LoadModule mapcache_module /usr/lib/apache2/modules/mod_mapcache.so" \
      >> /etc/apache2/mods-available/mapcache.load

RUN echo 'ServerName 127.0.0.1' >> /etc/apache2/apache2.conf

ADD ./mapcache-apache.conf /etc/apache2/sites-available/mapcache.conf

# Test mapcache seeder

ADD ./mapcache.xml $MAPCACHE_CONF

RUN mkdir /var/www/html/mapcache/cache

#ADD ./world.tif /var/www/html/mapcache/world.tif

RUN chown -R www-data:www-data /var/www/html/mapcache

RUN mapcache_seed -c $MAPCACHE_CONF -t $TILESET_NAME --force -z 0,$ZOOM_LEVEL_END

# Start apache

RUN a2dissite 000-default

RUN a2enmod mapcache
RUN a2ensite mapcache

EXPOSE 80

#RUN service apache2 restart

