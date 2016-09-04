#!/bin/bash
# prefilight.sh
systemctl --now enable ntpd
systemctl --now disable firewalld NetworkManager || :

if [ -f /etc/selinux/config ]; then
  sed -i 's/enforcing/disabled/g' /etc/selinux/config
  echo 0 > /sys/fs/selinux/enforce
fi

if [[ $MY_ROLE =~ "controller" ]] ; then
  echo "running controller node setup"

systemctl --now enable memcached httpd rabbitmq-server

rabbitmqctl add_user $SERVICE_USER $SERVICE_PWD || echo "not needed"
rabbitmqctl set_permissions $SERVICE_USER ".*" ".*" ".*"

if [ -d /var/lib/mysql ]; then
  #wipe the database directory in case this is not the first attempt to install openstack
  systemctl stop mariadb || :
  rm -rf /var/lib/mysql/*
  rm -rf /etc/my.cnf*
  yum reinstall -y mariadb mariadb-server mariadb-config
fi

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

systemctl --now enable mariadb
mysqladmin -u root password $DBPASSWD
fi  # end controller only section

# create an lvm VG wherever one is needed....
if [ -n "$LVMDEV" ] ; then
  set +e
  vgremove -f $OS_VOL_GROUP || :
  vgcreate $OS_VOL_GROUP $LVMDEV
  set -e
fi
