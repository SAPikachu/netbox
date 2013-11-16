[ `df / | tail -1 | awk '{ print $4 }'` -gt 200000 ] && exit 0
touch /etc/sapikachu/discard-aufs
shutdown -r now

