#!/bin/bash
# prefilight.sh
systemctl enable ntpd
systemctl restart ntpd
systemctl stop firewalld || :
systemctl disable firewalld || :

sed -i 's/enforcing/disabled/g' /etc/selinux/config
echo 0 > /sys/fs/selinux/enforce || echo "not needed"

if [[ $MY_ROLE =~ "controller" ]] ; then
  echo "running controller node setup"
#install messaging service
systemctl enable rabbitmq-server
systemctl restart rabbitmq-server

rabbitmqctl add_user openstack Service123 || echo "not needed"
rabbitmqctl set_permissions openstack ".*" ".*" ".*"

systemctl enable memcached
systemctl restart memcached

systemctl enable httpd
systemctl restart httpd

sed -i -e "/^\!includedir/d" /etc/my.cnf
sed -i -e "/^#/d" /etc/my.cnf
echo "CONTROLLER_IP=$CONTROLLER_IP"
crudini --set --verbose /etc/my.cnf mysqld bind-address $CONTROLLER_IP
crudini --set --verbose /etc/my.cnf mysqld default-storage-engine innodb
crudini --set --verbose /etc/my.cnf mysqld innodb_file_per_table
crudini --set --verbose /etc/my.cnf mysqld collation-server utf8_general_ci
crudini --set --verbose /etc/my.cnf mysqld init-connect "'SET NAMES utf8'"
crudini --set --verbose /etc/my.cnf mysqld character-set-server utf8
crudini --set --verbose /etc/my.cnf mysqld max_connections 25000

#wipe the database directory in case this is not the first attempt to install openstack
systemctl stop mariadb || :
rm -rf /var/lib/mysql/*
systemctl enable mariadb
systemctl restart mariadb
mysqladmin -u root password $DBPASSWD
fi 
