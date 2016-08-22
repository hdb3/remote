pip install --upgrade pip
pip install --upgrade etcd urllib3 six
cat > /etc/yum.repos.d/calico.repo << EOF0
[calico]
name=Calico Repository
baseurl=http://binaries.projectcalico.org/rpm_kilo/
enabled=1
skip_if_unavailable=0
gpgcheck=1
gpgkey=http://binaries.projectcalico.org/rpm/key
priority=97
EOF0
yum update -y
