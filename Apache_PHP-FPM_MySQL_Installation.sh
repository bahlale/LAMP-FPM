#!/usr/bin/env bash
domain_name=$1
ftp_user=$2
pass=$3

install_apache(){
  apt-get -y update; apt-get -y upgrade;
  ubuntu_ver=$(cat /etc/issue | awk '{print $2}')
  if [ $ubuntu_ver = "14.04" ];then
    apt-get install -y apache2 libapache2-mod-fastcgi
    a2enmod rewrite actions fastcgi alias ssl
    a2dissite 000-default
    install_php;
    user_add;
    create_config_apache24;
  else
    apt-get install -y apache2 apache2.2-common libapache2-mod-fastcgi
    a2enmod rewrite actions fastcgi alias ssl
    a2dissite default
    install_php;
    user_add;
    create_config_apache22;
  fi
}

install_php(){
  if dpkg-query -W php5-fpm;then
    echo "\n======\t  PHP-FPM Already installed \t======"
  else
    echo -e "\n======\t PHP-FPM not found installing PHP and Modules \t======"
    apt-get --purge -y remove libapache2-mod-php5
    apt-get install -y php5 php5-mysql php5-fpm php5-curl php5-gd php5-imagick php-apc 
  fi   
}

user_add(){
  mkdir -p /var/www/vhosts/$domain_name/httpdocs
  mkdir /var/www/vhosts/$domain_name/logs
  touch /var/www/vhosts/$domain_name/logs/error.log
  touch /var/www/vhosts/$domain_name/logs/access.log
  echo -e "\n======\t Creating User \t======"
  useradd -d /var/www/vhosts/$domain_name $ftp_user
  echo -e "$pass\n$pass\n" | passwd $ftp_user
}

create_config_apache22(){
  echo -e "\n======\t Creating Configuration Files \t======"
  wget -q --no-check-certificate -O /etc/apache2/sites-available/$domain_name \
    https://raw.githubusercontent.com/bahlale/LAMP-FPM/dev/conf/apache_vhost_template
  sed -i "s@DOMAIN_NAME@$domain_name@g" /etc/apache2/sites-available/$domain_name
  sed -i "s@FTP_USER@$ftp_user@g" /etc/apache2/sites-available/$domain_name
  a2ensite $domain_name
  wget -q --no-check-certificate -O /etc/apache2/conf.d/php-fpm.conf \
    https://raw.githubusercontent.com/bahlale/LAMP-FPM/dev/conf/apache_php_fpm_template
  rm -rf /etc/php5/fpm/pool.d/www.conf
  wget -q --no-check-certificate  -O /etc/php5/fpm/pool.d/$ftp_user.conf \
    https://raw.githubusercontent.com/bahlale/LAMP-FPM/dev/conf/php_fpm_pool_template
  sed -i "s@FTP_USER@$ftp_user@g" /etc/php5/fpm/pool.d/$ftp_user.conf
  service php5-fpm restart
  service apache2 restart  
  domain_template;
}

create_config_apache24(){
  echo -e "\n======\t Creating Configuration Files \t======"
  wget -q --no-check-certificate -O /etc/apache2/sites-available/$domain_name.conf \
    https://raw.githubusercontent.com/bahlale/LAMP-FPM/dev/conf/apache24_vhost_template
  sed -i "s@DOMAIN_NAME@$domain_name@g" /etc/apache2/sites-available/$domain_name.conf
  sed -i "s@FTP_USER@$ftp_user@g" /etc/apache2/sites-available/$domain_name.conf
  a2ensite $domain_name
  wget -q --no-check-certificate -O /etc/apache2/conf-available/php-fpm.conf \
    https://raw.githubusercontent.com/bahlale/LAMP-FPM/dev/conf/apache24_php_fpm_template
  a2enconf php-fpm.conf  
  rm -rf /etc/php5/fpm/pool.d/www.conf
  wget -q --no-check-certificate  -O /etc/php5/fpm/pool.d/$ftp_user.conf \
    https://raw.githubusercontent.com/bahlale/LAMP-FPM/dev/conf/php_fpm_pool_template
  sed -i "s@FTP_USER@$ftp_user@g" /etc/php5/fpm/pool.d/$ftp_user.conf
  service php5-fpm restart
  service apache2 restart  
  domain_template;
}

domain_template(){
  echo "Index page of $domain_name" > /var/www/vhosts/$domain_name/httpdocs/index.html
  echo "<?php phpinfo();" > /var/www/vhosts/$domain_name/httpdocs/info.php
  chown -cR $ftp_user.$ftp_user /var/www/vhosts/$domain_name
  clear;
  echo -e "\n\n"
  echo -e "\t\tCheck PHP Status through --> http://$domain_name/info.php"
  echo -e "\n\n"
}

check_debian(){
  os=$(for f in $(find /etc -type f -maxdepth 1 \( ! -wholename /etc/os-release ! -wholename \
   /etc/lsb-release -wholename /etc/\*release -o -wholename /etc/\*version \) 2> /dev/null); \
   do echo ${f:5:${#f}-13}; done;)
  if [ "$os" == "debian" ];then
    cp -arp /etc/apt/sources.list /etc/apt/sources.list.ori
    sed -i '/ftp/ s/$/ non-free/' /etc/apt/sources.list
  fi
}

# install_mysql(){

# }

check_debian;
if dpkg-query -W libapache2-mod-fastcgi;then
  echo "\n======\t Apache Already installed \t======"
else
  echo -e "\n======\t Installing Apache and Modules \t======" 
  install_apache;
fi