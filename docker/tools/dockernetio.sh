#!/bin/sh
#
# dockernetio.sh - a monitoring tool to map networks and their traffic to docker containers.
#
# (C) 2018 jw@owncloud.com
# Distribute under GPLv2 or ask.
#
# Usage:
#  watch -n 9 'dockernetio.sh | persec -c 2 | persec -c 3'
#

if [ -n "$1" ]; then
  echo "Usage:"
  echo "watch -n 9 '$0 | persec -c 2 -u K -n TX_KBytes | persec -c 3 -u K -n RX_KBytes'"
  exit 1
fi

echo "BRIDGE              TX_BYTES     RX_BYTES IFNAME       CONTAINER_NAME"

unknown_if=
text=
for c in $(docker ps -q); do
  nspid=$(docker inspect --format='{{.State.Pid}}' $c)
  cname=$(docker inspect --format='{{.Name}}' $c | sed -e 's@^/@@')
  ## nsenter -m runs the ls command or the cat command of the container.
  ## Elegant, but fails with traefik container, which does not have a populated file system.
  # devs=$(nsenter -t $nspid -m ls /sys/class/net)
  ## nsenter -n runs the ip command of the host with the nextwork context if the container. That always works.
  devs_at=$(nsenter -t $nspid -n ip a | grep @if | sed -e 's@^[0-9]*:\s*@@' -e 's@:.*@@')
  for dev_at in $devs_at; do
      # iflink=$(nsenter -t $nspid -m cat /sys/class/net/$dev/iflink)
      iflink=$(echo $dev_at | sed -e 's/.*@if//')
      ifname=$(grep -l $iflink /sys/class/net/*/ifindex | sed -e 's@^/sys/class/net/@@' -e 's@/ifindex@@')
      if [ -n "$ifname" ]; then
        bridge=$(readlink /sys/class/net/$ifname/master | sed -e 's@.*/@@')
        rx_bytes=$(cat /sys/class/net/$ifname/statistics/rx_bytes)
        tx_bytes=$(cat /sys/class/net/$ifname/statistics/tx_bytes)
        text=$(echo "$text"; printf "%-15s %12s %12s %-12s %s\n" $bridge $tx_bytes $rx_bytes $ifname $cname)
      else
        # dind?
        unknown_if="$unknown_if $nspid:$dev_at"
      fi
  done
done
echo "$text" | sort	# group by bridge
test -n "$unknown_if" && echo "unknown interfaces: $unknown_if"
