
for user in keystone nova glance cinder neutron
    do mysql -u root --password=$DBPASSWD -e "\
         DROP DATABASE IF EXISTS $user;\
         CREATE DATABASE $user; \
         GRANT ALL PRIVILEGES ON $user.* TO '$user'@'localhost' IDENTIFIED BY '$DBPASSWD';
         GRANT ALL PRIVILEGES ON $user.* TO '$user'@'$CONTROLLER_IP' IDENTIFIED BY '$DBPASSWD';
    "; done
mysql -u root --password=$DBPASSWD -e "FLUSH PRIVILEGES;"
