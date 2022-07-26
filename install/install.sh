IFNAME=$1

set -euo

# Update the hosts and other networking stuff
# Source: https://github.com/mbaykara/k8s-cluster/blob/main/Vagrantfile
ADDRESS="$(ip -4 addr show $IFNAME | grep "inet" | head -1 |awk '{print $2}' | cut -d/ -f1)"
sed -e "s/^.*${HOSTNAME}.*/${ADDRESS} ${HOSTNAME} ${HOSTNAME}.local/" -i /etc/hosts

cat >> /etc/hosts <<EOF
192.168.33.13 k8s-cp
192.168.33.14 k8s-worker-1
192.168.33.15 k8s-worker-2
EOF

# Set iptables bridging
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
echo '1' > /proc/sys/net/ipv4/ip_forward
sysctl --system

# load a couple of necessary modules 
modprobe overlay
modprobe br_netfilter
# disable swaping
sed 's/#   /swap.*/#swap.img/' /etc/fstab
swapoff -a

service systemd-resolved restart



# Install some pacakges
apt-get update && apt-get upgrade -y
# https://github.com/weaveworks/weave/issues/3942
apt-get install -y vim curl containerd=1.5.11-1

# Setup containerd
mkdir -p /etc/containerd
containerd config default  /etc/containerd/config.toml

# Add k8s to deb
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" \
  |  tee -a /etc/apt/sources.list.d/kubernetes.list

# Add gpg key
curl -s \
	https://packages.cloud.google.com/apt/doc/apt-key.gpg \
	| apt-key add -
apt-get update

# Install kubeadm
apt-get install -y kubeadm=v1.24.1 kubelet kubectl


# apt-get install -y kubeadm=1.22.1-00 kubelet=1.22.1-00 kubectl=1.22.1-00
# apt-mark hold kubelet kubeadm kubectl
