#!/usr/bin/env bash
domain_name=$1
ftp_user=$2
pass=$3
mysql_pass=$4

if(( $(id -u) > 0 ));then
   echo "This $0 script must be run as root" 1>&2
   exit 1
fi

[ ! $# -eq 4 ] && \
echo "Usage: $0 Domain_Name FTP_User_Name FTP_Password MySQL_Root_Password" && exit 1;

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
  install_mysql;
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

install_mysql(){
  echo -e "\n======\t Installing Prcona MySQL \t======" 
  apt-key adv --keyserver keys.gnupg.net --recv-keys 1C4CBDCDCD2EFD2A  
  percona_os=( squeeze wheezy lucid precise saucy trusty )
  for i in "${percona_os[@]}"
  do
    os_count=$(grep -c $i /etc/apt/sources.list)
    if(( $os_count > 0 ));then
      echo "found $i"
      echo -e "\n## Percona Repo" > /etc/apt/sources.list.d/percona.list
    echo "deb http://repo.percona.com/apt VERSION main" | sed "s/VERSION/$i/" \
     >> /etc/apt/sources.list.d/percona.list
    echo "deb-src http://repo.percona.com/apt VERSION main" | sed "s/VERSION/$i/" \
     >> /etc/apt/sources.list.d/percona.list
    fi
  done
  sh -c 'cat <<EOF >/etc/apt/preferences.d/00percona.pref
  Package: *
  Pin: release o=Percona Development Team
  Pin-Priority: 1001
  EOF' > /etc/apt/preferences.d/00percona.pref
  apt-get -y update;
  if dpkg-query -W percona-server-common-5.5;then
    echo "\n======\t  MySQL Already installed \t======"
  else
    mysql_server_conf="percona-server-server-5.5 percona-server-server"
    echo "${mysql_server_conf}/root_password password $mysql_pass" | debconf-set-selections
    echo "${mysql_server_conf}/root_password_again password $mysql_pass" | debconf-set-selections
    apt-get -y install percona-server-server-5.5 percona-server-client-5.5 
    if dpkg-query -W phpmyadmin;then
      echo "\n======\t  PHPMyAdmin Already installed \t======"
    else
      myadmin_conf="phpmyadmin phpmyadmin"
      echo "$myadmin_conf/dbconfig-install boolean true" | debconf-set-selections
      echo "$myadmin_conf/mysql/app-pass password $pass" | debconf-set-selections
      echo "$myadmin_conf/app-password-confirm password $pass" | debconf-set-selections
      echo "$myadmin_conf/mysql/admin-pass password $my_pass" | debconf-set-selections
      echo "$myadmin_conf/reconfigure-webserver multiselect apache2" | debconf-set-selections
      apt-get -y install phpmyadmin
    fi  
  fi  
}

check_debian;
if dpkg-query -W libapache2-mod-fastcgi;then
  echo "\n======\t Apache Already installed \t======"
else
  echo -e "\n======\t Installing Apache and Modules \t======" 
  install_apache;
fi