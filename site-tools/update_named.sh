#!/bin/bash

# Define the interface and configuration files
INTERFACE="eth0"
NAMED_CONF="/etc/bind/named.conf.local"
ZONE_FILE="/etc/bind/zones/mashmari.in"
REV_ZONE_FILE="/etc/bind/zones/mashmari.in.rev"

# Get the current dynamic IP address of the interface
IP_ADDRESS=$(ip addr show dev $INTERFACE | grep -oP 'inet \K[\d.]+')

# Update named.conf with the new IP address
sed -i "s/listen-on { .*; }/listen-on { $IP_ADDRESS; };/g" $NAMED_CONF

# Update the zone file with the new IP address
sed -i "s/bindserver\s*IN\s*A\s*.*$/bindserver      IN      A       $IP_ADDRESS/g" $ZONE_FILE
sed -i "s/1005\s*IN\s*A\s*.*$/1005      IN      A       $IP_ADDRESS/g" $ZONE_FILE
sed -i "s/bindserver\s*IN\s*A\s*.*$/bindserver      IN      A       $IP_ADDRESS/g" $REV_ZONE_FILE

# Update /etc/hosts
sed -i "s/.*1005.mashmari.in$/$IP_ADDRESS 1005.mashmari.in/g" /etc/hosts

# Restart BIND to apply changes
systemctl restart named
