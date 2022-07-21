#!/bin/bash

sudo apt update -y 
sudo apt upgradge -y
sudo apt install apache2 mysql-server php php-mysql libapache2-mod-php  openssl php-bz2 php-mysqli php-curl php-gd php-intl php-common php-mbstring php-xml -y 
#MYSQL
db_name="drupal`date +%s`"
#db_user="wpusr`date +%s`"
db_user=$db_name
db_password=`date |md5sum |cut -c '1-12'`
sleep 1
mysqlrootpass=`date |md5sum |cut -c '1-10'`
sleep 1

/usr/bin/mysql -e "USE mysql;"
/usr/bin/mysql -e "UPDATE user SET Password=PASSWORD($mysqlrootpass) WHERE user='root';" &> /dev/null
/usr/bin/mysql -e "FLUSH PRIVILEGES;"
touch /root/.my.cnf
chmod 640 /root/.my.cnf
echo "[client]">>/root/.my.cnf
echo "user=root">>/root/.my.cnf
echo "password="$mysqlrootpass>>/root/.my.cnf

/usr/bin/mysql -u root -e "CREATE DATABASE $db_name"
/usr/bin/mysql -u root -e "CREATE USER '$db_name'@'localhost' IDENTIFIED WITH mysql_native_password BY '$db_password';"
/usr/bin/mysql -u root -e "GRANT ALL PRIVILEGES ON $db_name.* TO '$db_user'@'localhost';"
/usr/bin/mysql -u root -e "FLUSH PRIVILEGES;"


touch /opt/creds
echo "Database Name: " $db_name >> /opt/creds 
echo "Database User: " $db_user >> /opt/creds
echo "Database Password: " $db_password >> /opt/creds
echo "Mysql root password: " $mysqlrootpass >> /opt/creds

sudo rm -rf /var/www/html/*
sudo wget https://www.drupal.org/download-latest/tar.gz -O drupal ; sudo tar xvf drupal -C /var/www/html/
cd /var/www/html & sudo mv /var/www/html/* /var/www/html/drupal

sudo chown -R www-data:www-data /var/www/html/drupal
sudo chmod -R 775 /var/www/html/drupal
sudo a2dissite 000-default.conf
sudo rm -rf  /etc/apache2/sites-available/000-default.conf
sudo touch /etc/apache2/sites-available/drupal.conf
sudo echo "
<VirtualHost *:80>
  ServerName localhost
  DocumentRoot /var/www/html/drupal/
  <Directory /var/www/html/drupal/>
    AllowOverride All
  </Directory>
</VirtualHost>
"  > /etc/apache2/sites-available/drupal.conf
sudo a2enmod rewrite
sudo a2ensite drupal.conf
sudo systemctl  restart apache2

sudo mkdir /var/www/html/drupal/sites/default/files
sudo cp /var/www/html/drupal/sites/default/default.settings.php /var/www/html/drupal/sites/default/settings.php
sudo chmod 664 /var/www/html/drupal/sites/default/settings.php
sudo chmod 775 /var/www/html/drupal/sites/default/files
sudo chown -R :www-data /var/www/html/drupal/*
sudo systemctl restart apache2


