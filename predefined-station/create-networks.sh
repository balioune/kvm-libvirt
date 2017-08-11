#!/bin/bash

echo "Creating networks .."

../network/net-create.sh net1 192.168.1.0 255.255.255.0
../network/net-create.sh net2 192.168.2.0 255.255.255.0
../network/net-create.sh net3 192.168.3.0 255.255.255.0

sudo virsh net-list
