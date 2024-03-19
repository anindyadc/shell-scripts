#!/bin/bash

# Define the interface and configuration files
INTERFACE="wlp2s0"

# Get the current dynamic IP address of the interface
IP_ADDRESS=$(ip addr show dev $INTERFACE | grep -oP 'inet \K[\d.]+')

# Update /etc/hosts
sed -i "s/.*1005.mashmari.in$/$IP_ADDRESS 1005.mashmari.in/g" /etc/hosts
