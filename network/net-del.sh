#!/bin/bash

if [ $# -ne 1 ] # verify if the required parameters are given
then
    echo "Give network name"
    exit 0
fi

DHCPPROC=`sudo ps -ax |grep eth0-$1 | awk '{print $1}'`
NETNAME=$1

function delete_dhcp_server()
{
  sudo ip netns del dhcp-server-$1
  ##delete dns server
  echo $DHCPPROC
  sudo kill -9 $DHCPPROC
  
}

function delete_kvm_ovs_net()
{
  # create OVS bridge. 
  # parameter net-name
  echo "Deleting network $1"
  sudo virsh net-destroy $1
  sudo virsh net-undefine $1
  echo "Deleting OVS br-$1"
  sudo ovs-vsctl del-br br-$1

}

delete_dhcp_server $NETNAME
delete_kvm_ovs_net $NETNAME

