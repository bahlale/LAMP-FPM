#!/usr/bin/env bash
install_apache(){
echo -e "\n======\t Installing Apache and Modules \t======" 
  apt-get --purge -y remove libapache2-mod-php5
  apt-get install -y apache2 libapache2-mod-fastcgi
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
  vhost=$(/var/www/vhosts/$domain_name)
  touch /var/www/vhosts/$domain_name/logs/error.log
  touch /var/www/vhosts/$domain_name/logs/access.log
  chown $ftp_user:$ftp_user/var/www/vhosts/$domain_name/ -R
  echo -e "\n======\t Creating User \t======"
  sudo useradd -d $vhost $ftp_user
  echo -e "$pass\n$pass\n" | sudo passwd $ftp_user
}

create_config(){
  wget -O --no-check-certificate /tmp/vhost_$domain_name \
  https://raw.githubusercontent.com/bahlale/LAMP-FPM/dev/conf/apache_vhost_template
  sed -i 's\DOMAIN_NAME\$domain_name\g' /tmp/vhost_$domain_name
  sed -i 's\FTP_USER\$ftp_user\g'

}


install_apache;
install_php;