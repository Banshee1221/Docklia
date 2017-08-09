FROM centos:6

MAINTAINER banshee

ENV GANGLIA_VERSION 3.7.2
ENV GANGLIA_WEB_VERSION 3.7.1

ADD Makefile Makefile

#### Add user and group for ganglia
RUN useradd -M ganglia && usermod -L ganglia

#### Install the necessary packages for compilation and Ganglia dependencies
RUN yum -y update && yum -y install epel-release && \
    yum -y install \
      wget \
      rsync \
      tar \
      apr-devel \
      rrdtool-devel \
      libconfuse-devel \
      pcre-devel \
      expat-devel \
      gcc \
      zlib-devel \
      make \
      python2 \
      php \
      httpd \
      python-setuptools && \
    yum clean all && \
    cd /usr/local/src && \
      wget https://sourceforge.net/projects/ganglia/files/ganglia%20monitoring%20core/$GANGLIA_VERSION/ganglia-$GANGLIA_VERSION.tar.gz/download -O /usr/local/src/ganglia.tar.gz && \
      tar -xzvf ganglia.tar.gz && \
      rm -rf ganglia.tar.gz && \
      cd ganglia-$GANGLIA_VERSION && ./configure --with-gmetad && \
        make -j8 && make install && \
        mkdir /etc/ganglia && \
    cd /usr/local/src/ganglia-$GANGLIA_VERSION && \
      ldconfig && \
      cp gmetad/gmetad.init /etc/rc.d/init.d/gmetad && \
      cp gmond/gmond.init /etc/rc.d/init.d/gmond && \
    cd / && \
      rm -rf /usr/local/src/ganglia-$GANGLIA_VERSION && \
    sed -i 's/GMETAD\=\/usr\/sbin\/gmetad/GMETAD\=\/usr\/local\/sbin\/gmetad/g' /etc/init.d/gmetad && \
    sed -i 's/daemon\ $GMETAD/#daemon\ $GMETAD\ -c\ \/etc\/ganglia\/gmetad.conf/g' /etc/init.d/gmetad && \
    sed -i 's/GMOND\=\/usr\/sbin\/gmond/GMOND\=\/usr\/local\/sbin\/gmond/g' /etc/init.d/gmond && \
    sed -i 's/daemon\ $GMOND/#daemon\ $GMOND\ -c\ \/etc\/ganglia\/gmond.conf/g' /etc/init.d/gmond && \
    mkdir -p /var/lib/ganglia/rrds && \
    chown nobody:nobody /var/lib/ganglia/rrds && \
    cd /usr/local/src && \
      wget -q https://sourceforge.net/projects/ganglia/files/ganglia-web/$GANGLIA_WEB_VERSION/ganglia-web-$GANGLIA_WEB_VERSION.tar.gz/download -O /usr/local/src/ganglia-web.tar.gz && \
      tar -zxvf ganglia-web.tar.gz && \
      rm -rf ganglia-web.tar.gz && \
    cd ganglia-web-$GANGLIA_WEB_VERSION && \
      mv /Makefile . && \
      make install && \
    cd / && \
      rm -rf /usr/local/src/ganglia-web-$GANGLIA_WEB_VERSION && \
    rm -rf /usr/local/src/*

EXPOSE 80
EXPOSE 8649
EXPOSE 6343

# Start services
RUN mkdir /var/log/ganglia
ADD services.py services.py
ENTRYPOINT ["python2", "services.py"]
