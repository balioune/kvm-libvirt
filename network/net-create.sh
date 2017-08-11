#!/bin/bash

if [ $# -ne 3 ] # verify if the required parameters are given
then
    echo "Give all required parameters \n"
    echo " create-net.sh <net-name> <ip-range>  <net-mask> "
    exit 0
fi

NETNAME=$1
IPRANGE=$2
IPMASK=$3

#Get IP bytes for DHCP
CN1=`echo $2 | cut -d . -f 1`
CN2=`echo $2 | cut -d . -f 2`
CN3=`echo $2 | cut -d . -f 3`
CN4=`echo $2 | cut -d . -f 4`
DHCPIP=$CN1.$CN2.$CN3.1
DHRANGE1=$CN1.$CN2.$CN3.2
DHRANGE2=$CN1.$CN2.$CN3.253

function validate_ip()
{
  
  if [[ $1 =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Correct IP address"
  else
    echo "IP address not valide"
    exit 0
  fi
}

function create_dhcp_server()
{
  sudo ip link add eth0-$1 type veth peer name dhcp-$1
  sudo ip link set eth0-$1 up
  sudo ip link set dhcp-$1 up
  
  # create namespace of dhsmasq
  sudo ip netns add dhcp-server-$1
  
  ##set the interface eth0 of dhcp-server, make it up and set IP address
  sudo ip link set eth0-$1 netns dhcp-server-$1
  
  sudo ip netns exec dhcp-server-$1 ip link set lo up
  sudo ip netns exec dhcp-server-$1 ip link set eth0-$1 up
  sudo ip netns exec dhcp-server-$1 ifconfig eth0-$1 $DHCPIP netmask $3
  
  #sudo ip netns exec dhcp-server-$1 dnsmasq --interface=eth0-$1 --dhcp-range=$DHRANGE1,$DHRANGE2,$3
  #sudo ip netns exec dhcp-server-$1 dnsmasq --interface=eth0-$1 --dhcp-range=$DHRANGE1,$DHRANGE2,$3 --dhcp-option=3 --dhcp-option=6
  sudo touch /var/lib/misc/dnsmasq.leases.$1
  sudo ip netns exec dhcp-server-$1 dnsmasq --interface=eth0-$1 --dhcp-leasefile=/var/lib/misc/dnsmasq.leases.$1 --dhcp-range=$DHRANGE1,$DHRANGE2,$3 --dhcp-option=3 --dhcp-option=6
}

function create_kvm_ovs_net()
{
  # create OVS bridge. 
  # parameter net-name
  sudo ovs-vsctl add-br br-$1
  net_xml="<network>
    <name>$1</name>
    <forward mode='bridge'/>
    <bridge name='br-$1'/>
    <virtualport type='openvswitch'>
    </virtualport>
  </network>"
  cat > network.xml <<EOF
$net_xml
EOF

  sudo virsh net-define network.xml
  sudo virsh net-start $1
  ##Add DHCP port to the OVS bridge
  sudo ovs-vsctl add-port br-$1 dhcp-$1

  sudo rm network.xml 
}

## Public network rules
#sudo iptables -A FORWARD --dst 192.168.1.0/24 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
#sudo iptables -A FORWARD --src 192.168.1.0/24 -j ACCEPT
#sudo iptables -t nat  -A POSTROUTING --src 192.168.1.0/24 -o eth0 -j SNAT --to 10.0.2.15

create_dhcp_server $NETNAME $IPRANGE $IPMASK

create_kvm_ovs_net $NETNAME

