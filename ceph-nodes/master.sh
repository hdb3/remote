#!/bin/bash
sudo ceph-nodes/build-vms.sh
#./remote.sh ceph-nodes ceph-deploy ceph-client vm1 vm2 vm3 vm4
set -e
sshpass -p root scp `dirname $0`/ceph.repo root@ceph-deploy:/etc/yum.repos.d
sshpass -p centos ssh centos@ceph-deploy bash -ves < ceph-nodes/ceph-deploy.sh
sshpass -p centos ssh centos@ceph-client bash -ves < ceph-nodes/ceph-test.sh
