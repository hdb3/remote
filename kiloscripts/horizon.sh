patch --forward -d / -p1 < patch.horizon || echo "patch ignored, this is probably a reinstall attempt"
sed -n -e "/^OPENSTACK_HOST.*127.0.0.1/s/127.0.0.1/$CONTROLLER_IP/" /etc/openstack-dashboard/local_settings
setsebool -P httpd_can_network_connect on
chown -R apache:apache /usr/share/openstack-dashboard/static
systemctl enable httpd memcached
systemctl start httpd memcached
