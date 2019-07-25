# version: v1.1.20190725

FROM nginx:1.17.2
MAINTAINER chloroplast "41893204@qq.com"

ADD ./conf/nginx.conf   /etc/nginx/nginx.conf
ADD ./conf/conf.d/*     /etc/nginx/conf.d

RUN set -ex \
    && ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo "Asia/Shanghai" > /etc/timezone

WORKDIR /var/www/html
