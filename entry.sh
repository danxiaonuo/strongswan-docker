#!/bin/bash

set -e

[ "$DEBUG" == 'true' ] && set -x

echo "# check and apply for overwrites (ovw) :"
if [ ! -e  /service/ovw ] ; then
  mkdir -p /service/ovw
fi
if [ ! -e  /service/mig ] ; then
  mkdir -p /service/mig
fi
rsync -av /service/ovw/ /


if [ "$VPN_SUBNET" != "" ] ; then
  echo "iptables -t nat -A POSTROUTING -s $VPN_SUBNET -j MASQUERADE"
  iptables -t nat -A POSTROUTING -s $VPN_SUBNET -j MASQUERADE
fi
sysctl -w net.ipv4.ip_forward=1
sysctl -w net.ipv4.conf.default.forwarding=1
sysctl -w net.ipv4.conf.all.forwarding=1
sysctl -w net.ipv6.conf.default.forwarding=1
sysctl -w net.ipv6.conf.all.forwarding=1
sysctl -w net.ipv6.conf.all.accept_redirects=0
sysctl -w net.ipv6.conf.all.accept_source_route=0
sysctl -w net.ipv6.conf.default.disable_ipv6=0
sysctl -w net.ipv6.conf.all.disable_ipv6=0
sysctl -w net.ipv6.conf.lo.disable_ipv6=0
sysctl -w net.ipv6.conf.all.proxy_ndp=1
sysctl -w net.ipv6.conf.all.accept_ra=2
sysctl -w net.ipv6.conf.default.router_solicitations=0
sysctl -w net.ipv6.conf.default.accept_ra_rtr_pref=0
sysctl -w net.ipv6.conf.default.accept_ra_pinfo=0
sysctl -w net.ipv6.conf.default.accept_ra_defrtr=0
sysctl -w net.ipv6.conf.default.autoconf=0
sysctl -w net.ipv6.conf.default.dad_transmits=0
sysctl -w net.ipv6.conf.default.max_addresses=1
rm -f /var/run*.pid

echo "Running $@"
exec "$@"
