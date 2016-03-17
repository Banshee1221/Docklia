FROM centos:6

MAINTAINER banshee


#### Install the necessary packages for compilation and Ganglia dependencies

# Get EPEL
RUN yum -y install wget && \
    wget http://ftp.riken.jp/Linux/fedora/epel/RPM-GPG-KEY-EPEL-6 && \
    rpm --import RPM-GPG-KEY-EPEL-6 && \
    wget https://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm && \
    rpm -i epel-release-6-8.noarch.rpm

# Update base packages
RUN yum -y update

# Install dependencies for Ganglia
RUN yum -y install rsync tar apr-devel rrdtool-devel libconfuse-devel pcre-devel expat-devel gcc zlib-devel make

# Install extra functionality
RUN yum -y install python2 php httpd python-setuptools

# Install docopt module for Python2
RUN easy_install docopt

#### Compile Ganglia

RUN useradd -M ganglia && usermod -L ganglia

# Install libconfuse
#RUN cd /usr/local/src && \
#    wget http://pkgs.repoforge.org/libconfuse/libconfuse-devel-2.6-2.el6.rf.x86_64.rpm && \
#    wget http://pkgs.repoforge.org/libconfuse/libconfuse-2.6-2.el6.rf.x86_64.rpm && \
#    rpm -ivh libconfuse-devel-2.6-2.el6.rf.x86_64.rpm \
#    libconfuse-2.6-2.el6.rf.x86_64.rpm

# Install rrdtool
#RUN cd /usr/local/src && \
#    wget http://oss.oetiker.ch/rrdtool/pub/rrdtool.tar.gz && \
#    tar -xzvf rrdtool.tar.gz && \
#    cd rrdtool-1.4.9/ && \
#    ./configure --prefix=/usr && \ 
#    make -j8 && make install

# ldconfig for libs
#RUN echo "/usr/local/lib" >> /etc/ld.so.conf && \
#    ldconfig

# Install Ganglia with gmetad
RUN cd /usr/local/src && \
    wget https://sourceforge.net/projects/ganglia/files/latest/download -O /usr/local/src/ganglia.tar.gz && \
    tar -xzvf ganglia.tar.gz && \
    cd ganglia-3.7.2 && ./configure --with-gmetad && \
    make -j8 && make install

# Post-process Ganglia install
RUN mkdir /etc/ganglia && \
    cd /usr/local/src/ganglia-3.7.2 && \
    ldconfig && \
    cp gmetad/gmetad.init /etc/rc.d/init.d/gmetad && \
    cp gmond/gmond.init /etc/rc.d/init.d/gmond

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
    cd ganglia-web-3.7.1 && \
    mv /Makefile . && \
    make install

# Cleanup
RUN yum clean all && \
    rm -rf /usr/local/src/*

EXPOSE 80
EXPOSE 8649
EXPOSE 6343

# Start services
RUN mkdir /var/log/ganglia
ADD services.sh services.sh
ENTRYPOINT ["bash", "services.sh"]
