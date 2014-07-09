#!/usr/bin/env bash
domain_name=$1
ftp_user=$2
pass=$3
install_apache(){
echo -e "\n======\t Installing Apache and Modules \t======" 
  apt-get --purge -y remove libapache2-mod-php5
  apt-get install -y apache2 apache2.2-common libapache2-mod-fastcgi
  a2enmod rewrite actions fastcgi alias ssl
  service apache2 restart
}

install_php(){
echo -e "\n======\t Installing PHP and Modules \t======"
  apt-get install -y php5 php5-mysql php5-fpm php5-curl php5-gd php5-imagick php-apc 
}

user_add(){
  mkdir -p /var/www/vhosts/$domain_name/httpdocs
  mkdir /var/www/vhosts/$domain_name/logs
  touch /var/www/vhosts/$domain_name/logs/error.log
  touch /var/www/vhosts/$domain_name/logs/access.log
  chown $ftp_user:$ftp_user /var/www/vhosts/$domain_name/ -R
  echo -e "\n======\t Creating User \t======"
  sudo useradd -d /var/www/vhosts/$domain_name $ftp_user
  echo -e "$pass\n$pass\n" | sudo passwd $ftp_user
}

create_config(){
  echo -e "\n======\t Creating Configuration Files \t======"
  wget --no-check-certificate -O /etc/apache2/sites-available/$domain_name.conf \
    https://raw.githubusercontent.com/bahlale/LAMP-FPM/dev/conf/apache_vhost_template
  sed -i "s@DOMAIN_NAME@$domain_name@g" /etc/apache2/sites-available/$domain_name.conf
  sed -i "s@FTP_USER@$ftp_user@g" /etc/apache2/sites-available/$domain_name.conf
  a2ensite $domain_name
  wget --no-check-certificate -O /etc/apache2/conf.d/php-fpm.conf \
    https://raw.githubusercontent.com/bahlale/LAMP-FPM/dev/conf/apache_php_fpm_template
  rm -rf /etc/php5/fpm/pool.d/www.conf
  wget --no-check-certificate  -O /etc/apache2/conf.d/php-fpm.conf \
    https://raw.githubusercontent.com/bahlale/LAMP-FPM/dev/conf/php_fpm_pool_template
  sed -i "s@FTP_USER@$ftp_user@g" /etc/apache2/conf.d/php-fpm.conf
  service php5-fpm restart
  service apache2 restart  
}


install_apache;
install_php;
user_add;
create_config;