FROM alpine:3.11.6

LABEL maintainer="Ztj <ztj1993@gmail.com>"

RUN apk add --no-cache git curl redis supervisor

# PHP
RUN apk update \
  && apk search -qe php7-* | grep -v gmagick | xargs apk add \
  && rm -rf /var/cache/apk/*

# Apache
RUN apk add --no-cache apache2 \
  && mkdir -p /run/apache2 \
  && ln -sf /dev/stdout /var/log/apache2/access.log \
  && ln -sf /dev/stderr /var/log/apache2/error.log \
  && sed -i 's@^#ServerName.*@ServerName localhost@' /etc/apache2/httpd.conf \
  && sed -i "s@Require ip 127@Require ip 127 192 10@" /etc/apache2/conf.d/info.conf \
  && sed -i "s@AllowOverride None@AllowOverride All@" /etc/apache2/httpd.conf \
  && sed -i "s@AllowOverride none@AllowOverride all@" /etc/apache2/httpd.conf \
  && sed -i "s@^#LoadModule rewrite_module@LoadModule rewrite_module@" /etc/apache2/httpd.conf \
  && sed -i "s@^#LoadModule info_module@LoadModule info_module@" /etc/apache2/httpd.conf

# Composer
RUN apk add --no-cache composer \
  && composer config -g repo.packagist composer https://mirrors.aliyun.com/composer/ \
  && composer config -g secure-http false \
  && composer self-update

# SSH
RUN apk add --no-cache openssh-server openssh-sftp-server \
  && ssh-keygen -q -N "" -t dsa -f /etc/ssh/ssh_host_dsa_key \
  && ssh-keygen -q -N "" -t rsa -f /etc/ssh/ssh_host_rsa_key \
  && sed -i "s@^#PermitRootLogin.*@PermitRootLogin yes@" /etc/ssh/sshd_config \
  && sed -i "s@^PermitRootLogin.*@PermitRootLogin yes@" /etc/ssh/sshd_config \
  && sed -i "s@^PasswordAuthentication.*@PasswordAuthentication yes@" /etc/ssh/sshd_config \
  && sed -i "s@^AllowTcpForwarding.*@AllowTcpForwarding yes@" /etc/ssh/sshd_config \
  && sed -i "s@^GatewayPorts.*@GatewayPorts yes@" /etc/ssh/sshd_config

# MySQL
RUN apk add --no-cache mysql mysql-client \
  && mkdir -p /run/mysqld \
  && chown mysql /run/mysqld \
  && mysql_install_db --user=mysql --datadir=/var/lib/mysql \
  && sed -i 's@skip-networking@# skip-networking@' /etc/my.cnf.d/mariadb-server.cnf

# PHPUnit
ADD https://phar.phpunit.de/phpunit.phar /usr/local/bin/phpunit
RUN chmod +x /usr/local/bin/phpunit

COPY rootfs /
RUN chmod +x /entrypoint.sh

EXPOSE 22 80 3306 9001

ENTRYPOINT ["/entrypoint.sh"]

CMD ["supervisord", "-c", "/etc/supervisord.conf", "--nodaemon"]
