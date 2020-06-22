FROM alpine:3.11.6

LABEL maintainer="Ztj <ztj1993@gmail.com>"

ENV ROOT_PASSWORD="123456"

ADD https://phar.phpunit.de/phpunit.phar /usr/local/bin/phpunit
RUN chmod +x /usr/local/bin/phpunit

RUN apk add --no-cache git openssh-server curl

RUN apk update
RUN apk search -qe php7-* | grep -v gmagick | xargs apk add
RUN rm -rf /var/cache/apk/*

RUN apk add --no-cache apache2
RUN mkdir -p /run/apache2
RUN ln -sf /dev/stdout /var/log/apache2/access.log
RUN ln -sf /dev/stderr /var/log/apache2/error.log
RUN sed -i 's@^#ServerName.*@ServerName localhost@' /etc/apache2/httpd.conf
RUN sed -i "s@Require ip 127@Require ip 127 192 10@" /etc/apache2/conf.d/info.conf
RUN sed -i "s@AllowOverride None@AllowOverride All@" /etc/apache2/httpd.conf
RUN sed -i "s@AllowOverride none@AllowOverride all@" /etc/apache2/httpd.conf
RUN sed -i "s@^#LoadModule rewrite_module@LoadModule rewrite_module@" /etc/apache2/httpd.conf
RUN sed -i "s@^#LoadModule info_module@LoadModule info_module@" /etc/apache2/httpd.conf

RUN apk add --no-cache composer
RUN composer config -g repo.packagist composer https://mirrors.aliyun.com/composer/
RUN composer config -g secure-http false
RUN composer self-update

RUN apk add --no-cache openssh-server openssh-sftp-server
RUN ssh-keygen -q -N "" -t dsa -f /etc/ssh/ssh_host_dsa_key
RUN ssh-keygen -q -N "" -t rsa -f /etc/ssh/ssh_host_rsa_key
RUN sed -i "s@^#PermitRootLogin.*@PermitRootLogin yes@" /etc/ssh/sshd_config
RUN sed -i "s@^PermitRootLogin.*@PermitRootLogin yes@" /etc/ssh/sshd_config
RUN sed -i "s@^PasswordAuthentication.*@PasswordAuthentication yes@" /etc/ssh/sshd_config
RUN sed -i "s@^AllowTcpForwarding.*@AllowTcpForwarding yes@" /etc/ssh/sshd_config
RUN sed -i "s@^GatewayPorts.*@GatewayPorts yes@" /etc/ssh/sshd_config
RUN echo "root:${ROOT_PASSWORD}" | chpasswd

RUN apk add --no-cache mysql mysql-client
RUN mkdir -p /run/mysqld
RUN chown mysql /run/mysqld
RUN mysql_install_db --user=mysql --datadir=/var/lib/mysql

RUN apk add --no-cache redis
RUN apk add --no-cache supervisor

RUN chown -R apache:apache /srv

COPY etc /etc

EXPOSE 22 80 3306 9001

CMD ["supervisord", "-c", "/etc/supervisord.conf", "--nodaemon"]
