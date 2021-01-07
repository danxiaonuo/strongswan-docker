##########################################
#         构建基础镜像                   #
##########################################
FROM alpine:edge
# 作者描述信息
MAINTAINER danxiaonuo
# 时区设置
ARG TZ=Asia/Shanghai
ENV TZ=$TZ
# 语言设置
ARG LANG=C.UTF-8
ENV LANG=$LANG

# 镜像变量
ARG DOCKER_IMAGE=danxiaonuo/strongswan
ENV DOCKER_IMAGE=$DOCKER_IMAGE
ARG DOCKER_IMAGE_OS=alpine
ENV DOCKER_IMAGE_OS=$DOCKER_IMAGE_OS
ARG DOCKER_IMAGE_TAG=edge
ENV DOCKER_IMAGE_TAG=$DOCKER_IMAGE_TAG
ARG BUILD_DATE
ENV BUILD_DATE=$BUILD_DATE
ARG VCS_REF
ENV VCS_REF=$VCS_REF


# ##############################################################################

# ***** 设置变量 *****

# 构建依赖
ARG BUILD_DEPS="\
      build-base \
      gcc \
      ca-certificates \
      curl \
      curl-dev \
      bash \
      rsync \
      ip6tables \
      iproute2 \
      iptables-dev \
      gmp \
      gmp-dev \
      linux-pam \
      linux-pam-dev \
      openssl \
      openssl-dev"
ENV BUILD_DEPS=$BUILD_DEPS

# STRONGSWAN
ARG STRONGSWAN_RELEASE="https://download.strongswan.org/strongswan.tar.bz2"
ENV STRONGSWAN_RELEASE=$STRONGSWAN_RELEASE

# 修改源地址
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories
# ***** 安装依赖 *****
RUN set -eux \
   # 更新源地址
   && apk update \
   # 更新系统并更新系统软件
   && apk upgrade && apk upgrade \
   && apk add -U --update $BUILD_DEPS \
   # 更新时区
   && ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime \
   # 更新时间
   && echo ${TZ} > /etc/timezone


# 安装STRONGSWAN		
RUN set -eux \
    cd /tmp/strongswan && \			
    curl -Lo /tmp/strongswan.tar.bz2 $STRONGSWAN_RELEASE && \
    mkdir -p /tmp/strongswan && \
    tar --strip-components=1 -C /tmp/strongswan -xjf /tmp/strongswan.tar.bz2 && \
    cd /tmp/strongswan && \
    ./configure --prefix=/usr \
    --sysconfdir=/etc \
    --libexecdir=/usr/lib \
    --with-ipsecdir=/usr/lib/strongswan \
    --enable-aesni \
    --enable-chapoly \
    --enable-cmd \
    --enable-curl \
    --enable-dhcp \
    --enable-eap-dynamic \
    --enable-eap-identity \
    --enable-eap-md5 \
    --enable-eap-mschapv2 \
    --enable-eap-radius \
    --enable-eap-tls \
    --enable-eap-aka \
    --enable-eap-aka-3gpp2 \
    --enable-eap-gtc \
    --enable-eap-peap \
    --enable-eap-sim \
    --enable-eap-sim-file \
    --enable-eap-simaka-pseudonym \
    --enable-eap-simaka-reauth \
    --enable-eap-simaka-sql \
    --enable-eap-tnc \
    --enable-eap-ttls \
    --enable-xauth-eap \
    --enable-xauth-pam \
    --enable-dhcp \
    --enable-farp \
    --enable-unity \
    --enable-addrblock \
    --enable-files \
    --enable-certexpire \
    --enable-radattr \
    --enable-gcm \
    --enable-md4 \
    --enable-newhope \
    --enable-ntru \
    --enable-openssl \
    --enable-sha3 \
    --enable-shared \
    --enable-swanctl \
    --enable-kernel-netlink \
    --disable-aes \
    --disable-des \
    --disable-gmp \
    --disable-mysql \
    --disable-ldap \
    --disable-hmac \
    --disable-ikev1 \
    --disable-md5 \
    --disable-rc2 \
    --disable-sha1 \
    --disable-sha2 \
    --disable-static && \
    make -j$(($(nproc)+1)) && \
    make -j$(($(nproc)+1)) install && \
    rm -rf /tmp/* && \
    rm -rf /var/cache/apk/*


# 拷贝配置文件
#COPY ./conf/strongswan/config/swanctl.conf /etc/swanctl.conf
#COPY ./conf/strongswan/config/ipsec.secrets /etc/ipsec.secrets
#COPY ./conf/strongswan/config/strongswan.conf /etc/strongswan.conf
#COPY ./conf/strongswan/config/ipsec.d /etc/ipsec.d
COPY ./conf/strongswan/bin/ovw /usr/local/bin/ovw
RUN chmod a+x /usr/local/bin/*

# 设置环境
RUN echo ". /etc/profile" > /root/.bashrc
RUN echo "alias ll='ls -alF'"     >> /etc/profile
RUN echo "export PS1='\H:\w\\$ '" >> /etc/profile
RUN echo 'export TERM="xterm"'    >> /etc/profile


COPY ./entry.sh /entry.sh
RUN chmod a+x /entry.sh

# 监听端口
EXPOSE 500/udp \
       4500/udp

# 入口
ENTRYPOINT ["/entry.sh"]

# 启动命令
CMD ["/usr/sbin/ipsec", "start", "--nofork"]
