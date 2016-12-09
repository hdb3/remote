VG=`lvs|awk '/ home / {print $2}'`
# umount /home
lvremove -f $VG/home && sed -i -e '/\/home/ d' /etc/fstab
