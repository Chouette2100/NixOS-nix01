#!/bin/sh
sudo ip addr add 133.18.146.63/23 dev ens3
sudo ip link set ens3 up
sudo ip route add default via 133.18.146.1 dev ens3
echo "nameserver 210.134.55.219" | tee /etc/resolv.conf
ping -4 -c 3 google.com
