#!/bin/sh
# Maintained by: Omer SEN <omer_D_O_T_sen@serra___pw>
# 

################## VARS BEGIN ###############
FROM_IP=`hostname -i`
IPA_SERVERS="192.168.122.101 192.168.122.102"
DOMAIN="serra.pw"
TCP_PORTS="53 88 389 636 443 464"
UDP_PORTS="53 88 123 464"
################## VARS END   ###############


# DOMAIN="serra.pw"
# IPA_SERVERS="192.168.122.101 192.168.122.102"


if [ `whoami` != "root" ];then
	echo
	echo "This script must be run as root user"
	echo
	exit 1
fi


echo "=============================================================================="
echo "=============================================================================="
echo "== This is `hostname` with IP Address of `hostname -i` =="
echo "=============================================================================="
echo "=============================================================================="
echo ""
echo ""




echo "Checking TCP PORTS          "
echo "=========================================="
PROTO=tcp
for IPA_IP in `echo $IPA_SERVERS`
do
  echo "For IPA SERVER: ${IPA_IP}"
  echo "---------------------------------------"
  for PORT in `echo $TCP_PORTS`
  do
	(echo > /dev/${PROTO}/${IPA_IP}/${PORT}) >/dev/null 2>&1 
	if [ $? -eq 0 ]
	   then
		echo "${IPA_IP} and Port ${PROTO}:${PORT} is OK from ${FROM_IP}"  
	   else
	 	echo "${IPA_IP} and Port ${PROTO}:${PORT} is NOT reachable from ${FROM_IP}"
		echo "=================================================="
		echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
		echo "Test failed please fix firewalll rules"
		echo "And re-run test"
		echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
		echo "=================================================="
		exit 10
	
	fi
  done
done

echo
echo

echo "Checking UDP PORTS          "
echo "=========================================="
PROTO=udp

for IPA_IP in `echo $IPA_SERVERS`
do
  for PORT in `echo $UDP_PORTS`
  do
        (echo > /dev/${PROTO}/${IPA_IP}/${PORT}) >/dev/null 2>&1 
        if [ $? -eq 0 ]
           then 
                echo "${IPA_IP} and Port ${PROTO}:${PORT} is OK from ${FROM_IP}"   
           else
                echo "${IPA_IP} and Port ${PROTO}:${PORT} is NOT reachable from ${FROM_IP}"
                echo "=================================================="
                echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
                echo "Test failed please fix firewalll rules"
                echo "And re-run test"
                echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
                echo "=================================================="
                exit 10

        fi
  done
done

echo
echo






echo
echo
echo "Checking /etc/resolv.conf contains NEW IPA DNS Server"
echo "====================================================="
for IPA_IP in `echo $IPA_SERVERS`
do
        grep -v "^#" /etc/resolv.conf | grep -q "${IPA_IP}"
        if [ $? -ne 0 ]
        then
                echo "========================================================================================="
                echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
                echo "IPA SERVER ${IPA_IP} is NOT addded to /etc/resolv.conf as DNS SERVER please add ${IPA_IP}"
                echo "to /etc/resolv.conf and re-run test"
                echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
                echo "========================================================================================="
                exit 11
        else
                echo "We found ${IPA_IP} in /etc/resolv.conf which is OK"
        fi

done


############# Check if we have FQDN AS HOSTNAME ################


echo
echo
echo "Checking hostname of client is FQDN "
echo "====================================================="
hostname |grep -q "\."

if [ $? -ne "0" ] ;then
	echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
	echo "Your hostname is not FQDN. You need to set it"
	echo "like `hostname`.${DOMAIN} PERMANENTLY"
	echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
	echo 
	exit 13

else
	echo "Your Hostname: `hostname -f` is OK"

fi

############### END OF FQDN CHECK ##############################


########## START OF IPA_PACKAGES ##############################
echo
echo
echo "Checking if ipa-client RPM Packages are installed"
echo "====================================================="
rpm -qa |grep -q  ipa-client- 
if [ $? -ne "0" ] ;then
        echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        echo "Please install ipa-client-* packages"
	echo "And re-run this script again"
        echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        echo
        exit 14

else
        echo "IPA client package: ipa-client is installed OK"
	rpm -qa |grep ipa-client
	echo
	echo

fi

############ END OF IPA_PACKAGES ###########################


########### CHECKING REDHAT VERSION #####################
rpm -qa |grep -qi redhat-release-server-7

if [ $? -ne "0" ];then
	RHEL6_VERS=`rpm -qa |grep -i redhat-release-server-6Server-6 |cut -f 2 -d "."`
	if [ ${RHEL6_VERS} -lt 10 ] ;then
		echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
		echo "Your Red Hat 6 Server version is less than 6.10 which is not compatible"
		echo "Please UPGRADE to 6.10 or above"
		echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
		echo
		exit 14
	fi
else

echo "==============================================="
echo "Your Server Version is RHEL7 which is compatible"
echo "==============================================="
echo


fi


########### END CHECKING REDHAT VERSION #####################



############ CHECKING IF WE ARE UNDER Network Manager ##################
INT_NAME=`ip addr show | awk '/inet.*brd/{print $NF; exit}'`

eval `cat /etc/sysconfig/network-scripts/ifcfg-${INT_NAME}|grep NM_CONT`
if [ ${NM_CONTROLLED} = "yes" ];then
	
	eval `cat /etc/sysconfig/network-scripts/ifcfg-${INT_NAME} |grep DNS`
			
	grep -q ${DNS1} /etc/sysconfig/network-scripts/ifcfg-${INT_NAME}

	if [ $? -ne 0 ];then
	echo
	echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
	echo "You need to modify /etc/sysconfig/network-scripts/ifcfg-${INT_NAME} file"
	echo "and add DNS1 and DNS2 variables to reflect IPA Servers"
	echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
	echo
	echo
	exit 16
	fi



       grep -q ${DNS2} /etc/sysconfig/network-scripts/ifcfg-${INT_NAME}

       if [ $? -ne 0 ];then
        echo
        echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        echo "You need to modify /etc/sysconfig/network-scripts/ifcfg-${INT_NAME} file"
        echo "and add DNS1 and DNS2 variables to reflect IPA Servers"
        echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        echo
        echo
	exit 16
       fi
	

fi


############ CHECKING IF WE ARE UNDER Network Manager ##################


for IPA_IP in `echo $IPA_SERVERS`
do
echo
echo
echo "DNS RECORDS CHECKED AGAINST ${IPA_IP} IPA SERVER"
echo "======================================================================"
echo
   for SRV_RECORD in _ldap._tcp _kerberos._tcp _kerberos._udp _kerberos-master._tcp _kerberos-master._udp _kpasswd._tcp _kpasswd._udp _ntp._udp
   do 
       echo "DNS Records for ${SRV_RECORD}.${DOMAIN} by ${IPA_IP}"
       echo "--------------------------------------------------------------------------"
       dig ${IPA_IP} ${SRV_RECORD}.${DOMAIN} srv +nocmd +noquestion +nocomments +nostats +noaa +noadditional +noauthority| egrep -v "^;"|egrep _
       echo
       
   done 

done


### NEEDS TO BE FIXED AS /dev/udp ALWAYS RETURNS 0!!!!!!
echo
echo
echo "Checking NTP conection UDP Port 123"
echo "====================================================="

for IPA_IP in `echo $IPA_SERVERS`
do
	ntpdate -q ${IPA_IP} 2>&1  |grep -q "no server suitable"
        if [ $? -eq 0 ]
        then
		echo
                echo "========================================================================================="
                echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
                echo "Cant sync time against ${IPA_IP} UDP Port 123"
		echo "Please fix firewall rules and re-run test"
                echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
                echo "========================================================================================="
		echo
		exit 12
	else
		echo
		echo "========================================================================================="
		echo "NTP Connection to port UDP:123 to ${IPA_IP} is OK"
		echo "========================================================================================="
		echo
	fi


done





echo 
echo




