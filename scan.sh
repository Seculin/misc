#!/bin/bash

# Get system information
HOSTNAME=`hostname`
if [ -f /etc/os-release ]; then
  DISTRO=`cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2- | tr -d '"'`
  VERSION=`cat /etc/os-release | grep VERSION_ID | cut -d= -f2`
  if [ -n "$(command -v apt)" ]; then
    DISTRO_UPDATE=`apt-get --just-print upgrade | grep -P '^\d+ upgraded,' | awk '{print $1}'`
    KERNEL_UPDATE=`apt-get --just-print upgrade | grep -P 'linux-image-\d+' | awk '{print $2}'`
  else
    DISTRO_UPDATE=`yum check-update --quiet | wc -l`
    KERNEL_UPDATE=`yum check-update --quiet kernel | wc -l`
  fi
else
  DISTRO=`cat /etc/redhat-release`
  VERSION=`uname -r`
fi
KERNEL=`uname -r`
UPTIME=`uptime -p`



if [ -f /sys/hypervisor/uuid ]; then
    IS_VM="This server is a virtual machine."
else
    IS_VM="This server is a physical machine."
fi
# Get IP addresses and interfaces
IP_ADDRESSES=`ip addr show | grep 'inet ' | awk '{print $2 " " $NF}'`
ip_nat=`curl ifconfig.me`
# Get open ports with associated services and IPs
OPEN_PORTS=`ss -tulnp4 | awk '$1 ~ /^(tcp|udp)/ && $1 !~ /LISTEN/ {print $4 " " $6 " " $NF}' | sed 's/.*://g'`

# Get local users
LOCAL_USERS=`awk -F: '$3>=1000{printf "%s:%s\n",$1,$3}' /etc/passwd`

# Get installed packages
if [ -n "$(command -v apt)" ]; then
  INSTALLED_PACKAGES=`dpkg-query -W -f='${binary:Package} ${Version} ${Status}\n' | awk '$4=="installed" {print $1 " " $2}'`
  AVAILABLE_UPDATES=`apt update > /dev/null && apt list --upgradable 2> /dev/null | awk -F/ '/\// {print $1, $2}'`
else
  INSTALLED_PACKAGES=`yum list installed | awk '{print $1 " " $2}'`
  AVAILABLE_UPDATES=`yum check-update --quiet | awk '{print $1, $2}'`
fi

# Get list of running services
if [ -n "$(command -v systemctl)" ]; then
  RUNNING_SERVICES=`systemctl list-units --type=service --state=running | awk '{print $1}'`
elif [ -n "$(command -v service)" ]; then
  RUNNING_SERVICES=`service --status-all | grep running | awk '{print $4}'`
fi

# Get available disk space
DISK_SPACE=`df -h`

# Get system memory
MEMORY=`free -h`

# Get number of CPUs
CPUS=`nproc`

# Print system information in a table
echo "+--------------------------------------------------+"
echo "|                    SYSTEM INFO                   |"
echo "+--------------------------------------------------+"
echo "| Hostname             | $HOSTNAME                  |"
echo "| Distribution         | $(printf '%-25s' "$DISTRO") |"
echo "| Version              | $(printf '%-25s' "$VERSION") |"
echo "| Kernel version       | $(printf '%-37s' "$KERNEL") |"
echo "| Uptime               | $(printf '%-37s' "$UPTIME") |"
echo "+--------------------------------------------------+"

# Print IP addresses in a table
echo "+--------------------------------------------------+"
echo "|            IP ADDRESSES AND INTERFACES            |"
echo "+--------------------------------------------------+"
echo "$IP_ADDRESSES" | while read line; do
  echo "| $(echo $line | cut -d' ' -f2)        | $(echo $line | cut -d' ' -f1)               |"
done
echo "+--------------------------------------------------+"

# Print open ports in a table
echo "+-----------------------------------------------------------------------+"
echo "|                         OPEN PORTS                                   |"
echo "+-----------------------------------------------------------------------+"
netstat -tlnp | awk '{print $4, $7}' | sed 's/.*://' | grep -v "^-" | sort -u
echo "+-----------------------------------------------------------------------+"

# Print local users in a table
echo "+--------------------------------------------------+"
echo "|                    LOCAL USERS                   |"
echo "+--------------------------------------------------+"
echo "| Username           | UID                          |"
echo "+--------------------+------------------------------+"
echo "$LOCAL_USERS" | while read line; do
  USERNAME=$(echo $line | cut -d':' -f1)
  UUID=$(echo $line | cut -d':' -f2)
  echo "| $(printf '%-20s' $USERNAME) | $(printf '%-30s' $UUID) |"
done
echo "+--------------------------------------------------+"

# Print installed packages in a table
echo "+-----------------------------------------------------------------------+"
echo "|                           INSTALLED PACKAGES                           |"
echo "+-----------------------------------------------------------------------+"
echo "| Package                  | Installed | Available                      |"
echo "+--------------------------+-----------+--------------------------------+"
while read line; do
  PACKAGE=$(echo $line | awk '{print $1}')
  VERSION=$(echo $line | awk '{print $2}')
  if [ -n "$AVAILABLE_UPDATES" ]; then
    AVAILABLE=$(echo "$AVAILABLE_UPDATES" | grep -E "^$PACKAGE " | awk '{print $2}')
  fi
  if [ -z "$AVAILABLE" ]; then
    AVAILABLE="-"
  fi
  echo "| $(printf '%-25s' "$PACKAGE") | $(printf '%-9s' "$VERSION") | $(printf '%-30s' "$AVAILABLE") |"
done <<< "$INSTALLED_PACKAGES"
echo "+-----------------------------------------------------------------------+"

# Print list of running services in a table
echo "+--------------------------------------------------+"
echo "|                RUNNING SERVICES                  |"
echo "+--------------------------------------------------+"
echo "$RUNNING_SERVICES" | while read line; do
  echo "| $line |"
done
echo "+--------------------------------------------------+"

# Print available disk space in a table
echo "+--------------------------------------------------+"
echo "|                    DISK SPACE                    |"
echo "+--------------------------------------------------+"
echo "$DISK_SPACE" | while read line; do
  echo "| $line |"
done
echo "+--------------------------------------------------+"

# Print system memory in a table
echo "+--------------------------------------------------+"
echo "|                 SYSTEM MEMORY                    |"
echo "+--------------------------------------------------+"
echo "|          total        used        free           |"
echo "| Mem:     $(echo "$MEMORY" | awk 'NR==2{print $2}')     $(echo "$MEMORY" | awk 'NR==2{print $3}')     $(echo "$MEMORY" | awk 'NR==2{print $4}')     |"
echo "| Swap:    $(echo "$MEMORY" | awk 'NR==4{print $2}')     $(echo "$MEMORY" | awk 'NR==4{print $3}')     $(echo "$MEMORY" | awk 'NR==4{print $4}')     |"
echo "+--------------------------------------------------+"

# Print number of CPUs in a table
echo "+--------------------------------------------------+"
echo "|                   CPU INFO                       |"
echo "+--------------------------------------------------+"
echo "| Number of CPUs: $(printf '%-31s' $CPUS) |"
echo "+--------------------------------------------------+"


#NAT IP
echo "+--------------------------------------------------+"
echo "|                   NAT IP                         |"
echo "+--------------------------------------------------+"
echo "| $ip_nat                                   |"
echo "+--------------------------------------------------+"


#NAT IP
echo "+--------------------------------------------------+"
echo "|                   VM or dedicated server?        |"
echo "+--------------------------------------------------+"
echo "| $IS_VM                                   |"
echo "+--------------------------------------------------+"
