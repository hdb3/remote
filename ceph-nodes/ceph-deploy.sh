test -f /etc/yum.repos.d/ceph.repo
grep "enabled=0" /etc/yum/pluginconf.d/fastestmirror.conf
#sudo cp /root/ceph.repo /etc/yum.repos.d
sudo yum -y install epel-release
sudo yum -y install ceph-deploy sshpass
sudo chown -R centos:centos /home/centos/.ssh/
ssh-keygen -N "" -t rsa -f ~/.ssh/id_rsa
echo "StrictHostKeyChecking No" >> /home/centos/.ssh/config
chmod og-rwx /home/centos/.ssh/config
for vm in vm1 vm2 vm3 vm4 ceph-client ; do sshpass -p centos ssh-copy-id $vm ; done
ceph-deploy new vm1
ceph-deploy install vm1 vm2 vm3 vm4
ceph-deploy mon create-initial
for h in vm1 vm2 vm3 vm4
  do
   ceph-deploy osd prepare $h:/dev/vdb $h:/dev/vdc $h:/dev/vdd
   ceph-deploy osd activate $h:/dev/vdb1 $h:/dev/vdc1 $h:/dev/vdd1
   ceph-deploy admin $h
  done
ceph-deploy install ceph-client
ceph-deploy admin ceph-client
ceph-deploy mds create vm1
ceph-deploy rgw create vm1
echo "ceph deply completed, time to test the installation?"
