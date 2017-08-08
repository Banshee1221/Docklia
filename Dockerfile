FROM centos:6

MAINTAINER banshee


#### Install the necessary packages for compilation and Ganglia dependencies

# Get EPEL
RUN yum -y install wget && \
    wget http://ftp.riken.jp/Linux/fedora/epel/RPM-GPG-KEY-EPEL-6 && \
    rpm --import RPM-GPG-KEY-EPEL-6 && \
    wget https://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm && \
    rpm -i epel-release-6-8.noarch.rpm && \
    yum -y update && \
    yum -y install rsync tar apr-devel rrdtool-devel libconfuse-devel pcre-devel expat-devel gcc zlib-devel make python2 php httpd python-setuptools && \
    yum clean all

# Install docopt module for Python2
RUN easy_install docopt

#### Compile Ganglia

RUN useradd -M ganglia && usermod -L ganglia

# Install Ganglia with gmetad
RUN cd /usr/local/src && \
    wget https://sourceforge.net/projects/ganglia/files/latest/download -O /usr/local/src/ganglia.tar.gz && \
    tar -xzvf ganglia.tar.gz && \
    rm ganglia.tar.gz && \
    cd ganglia-3.7.2 && ./configure --with-gmetad && \
    make -j8 && make install && \
    mkdir /etc/ganglia && \
    cd /usr/local/src/ganglia-3.7.2 && \
    ldconfig && \
    cp gmetad/gmetad.init /etc/rc.d/init.d/gmetad && \
    cp gmond/gmond.init /etc/rc.d/init.d/gmond && \
    cd / && rm -r /usr/local/src/ganglia-3.7.2

# Configure basics in gmetad and gmond conf
RUN sed -i 's/GMETAD\=\/usr\/sbin\/gmetad/GMETAD\=\/usr\/local\/sbin\/gmetad/g' /etc/init.d/gmetad && \
    sed -i 's/daemon\ $GMETAD/#daemon\ $GMETAD\ -c\ \/etc\/ganglia\/gmetad.conf/g' /etc/init.d/gmetad && \
    sed -i 's/GMOND\=\/usr\/sbin\/gmond/GMOND\=\/usr\/local\/sbin\/gmond/g' /etc/init.d/gmond && \
    sed -i 's/daemon\ $GMOND/#daemon\ $GMOND\ -c\ \/etc\/ganglia\/gmond.conf/g' /etc/init.d/gmond

ADD Makefile Makefile

# Install Ganglia web
RUN mkdir -p /var/lib/ganglia/rrds && \
    chown nobody:nobody /var/lib/ganglia/rrds && \
    cd /usr/local/src && \
    wget -q https://sourceforge.net/projects/ganglia/files/ganglia-web/3.7.1/ganglia-web-3.7.1.tar.gz/download -O /usr/local/src/ganglia-web.tar.gz && \
    tar -zxvf ganglia-web.tar.gz && \
    rm ganglia-web.tar.gz && \
    cd ganglia-web-3.7.1 && \
    mv /Makefile . && \
    make install && \
    cd / && rm -r /usr/local/src/ganglia-web-3.7.1

# Cleanup
RUN rm -rf /usr/local/src/*

EXPOSE 80
EXPOSE 8649
EXPOSE 6343

# Start services
RUN mkdir /var/log/ganglia
ADD services.py services.py
ENTRYPOINT ["python2", "services.py"]
