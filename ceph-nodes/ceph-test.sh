sudo chmod +r /etc/ceph/ceph.client.admin.keyring
rados mkpool data
echo "stuff and nonsense" > test.txt
rados put test-data test.txt --pool=data
rados -p data ls
ceph osd map data test-data
sudo bash -c 'printf "\nrbd default features = 3\n" >> /etc/ceph/ceph.conf'
sudo rbd create foo --size 64
sudo rbd map foo
sudo mkfs.ext4 -m0 /dev/rbd0
mkdir m
sudo mount /dev/rbd0 m
df -h m
sudo dd if=/dev/urandom  of=m/r
