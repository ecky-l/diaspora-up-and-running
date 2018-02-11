FROM centos:7

COPY build_diaspora.sh /usr/local/bin/build_diaspora.sh
RUN useradd -m -d /var/local/diaspora -u 1011 diaspora
RUN yum -y reinstall filesystem && yum -y update && \
	yum -y install epel-release && \
	yum -y install tar make automake gcc gcc-c++ git net-tools \
		libcurl-devel libxml2-devel libffi-devel libxslt-devel wget \
		ImageMagick nodejs postgresql-devel which patch bison bzip2 \
		libtool patch readline-devel sqlite-devel libyaml-devel openssl-devel && \
	yum clean all && rm -rf /var/cache/yum && \
	chmod 755 /usr/local/bin/build_diaspora.sh

VOLUME /var/local/diaspora
USER diaspora:diaspora
ENTRYPOINT ["/usr/local/bin/build_diaspora.sh"]
