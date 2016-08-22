#!/bin/bash
# prefilight.sh
systemctl enable --now ntpd
systemctl disable --now firewalld NetworkManager || :

if [ -f /etc/selinux/config ]; then
  sed -i 's/enforcing/disabled/g' /etc/selinux/config
  echo 0 > /sys/fs/selinux/enforce
fi

if [[ $MY_ROLE =~ "controller" ]] ; then
  echo "running controller node setup"
systemctl enable --now rabbitmq-server

rabbitmqctl add_user $RABBIT_USER $RABBIT_PASSWORD || :
rabbitmqctl set_permissions openstack ".*" ".*" ".*"

systemctl enable --now memcached

systemctl enable --now httpd

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
mkdir -p /etc/systemd/system/mariadb.service.d
crudini --set --verbose /etc/systemd/system/mariadb.service.d/limits.conf Service LimitNOFILE 10000
systemctl --system daemon-reload

#wipe the database directory in case this is not the first attempt to install openstack
systemctl stop mariadb || :
rm -rf /var/lib/mysql/*
systemctl enable --now mariadb
mysqladmin -u root password $DBPASSWD
fi 
