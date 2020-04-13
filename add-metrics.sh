#!/bin/bash

echo "Warning: replacing JVB_OPTS in videobridge config"
sed -i.bak s/JVB_OPTS=\"\"/JVB_OPTS=\"--apis=rest,xmpp\"/g /etc/jitsi/videobridge/config

grep "org.jitsi.videobridge.ENABLE_STATISTICS=true"  /etc/jitsi/videobridge/sip-communicator.properties
if [ ! "$?" -eq 0 ]; then
    echo "Adding export statistics to sip-communicator properties"
    cat << EOF >> /etc/jitsi/videobridge/sip-communicator.properties
org.jitsi.videobridge.ENABLE_STATISTICS=true
org.jitsi.videobridge.STATISTICS_TRANSPORT=muc,colibri
org.jitsi.videobridge.STATISTICS_INTERVAL=5000
EOF
fi

JvbServiceName="jitsi-videobridge.service"
Jvb2ServiceName="jitsi-videobridge2.service"
JicofoServiceName="jicofo.service"

echo "Restarting $JvbServiceName..."
if systemctl --all --type service | grep -q "$JvbServiceName"; then
    systemctl restart $JvbServiceName
    echo "$JvbServiceName restarted."
else
    echo "$JvbServiceName not found, re-trying with $Jvb2ServiceName"
    if systemctl --all --type service | grep -q "$Jvb2ServiceName"; then
	systemctl restart $Jvb2ServiceName
	echo "$Jvb2ServiceName restarted."
    else
	echo "I found neither $JvbServiceName nor $Jvb2ServiceName."
	exit 1
    fi
fi

echo "Restarting $JicofoServiceName..."
systemctl restart $JicofoServiceName
echo "$JicofoServiceName restarted."

iptables -L INPUT -n -v | grep 8080 | grep tcp
if [ ! "$?" -eq 0 ]; then
    echo "Denying firewall on port 8080"
    iptables -I INPUT 1 -j DROP -p tcp --destination-port=8080
    iptables -I INPUT 1 -i lo -j ACCEPT -p tcp --destination-port=8080
fi
iptables -L INPUT -n -v | grep 8081 | grep tcp
if [ ! "$?" -eq 0 ]; then
    echo "Allowing firewall on port 8081"
    iptables -I INPUT 1 -j ACCEPT -p tcp --destination-port=8081
fi

echo "Adding systemd service"
sed "s@IORESTOACASA_PLACEHOLDER@$(pwd)/iorestoacasa_metrics.py@g" iorestoacasa_metrics.service > /etc/systemd/system/iorestoacasa_metrics.service

echo "Starting to export metrics!"
systemctl enable iorestoacasa_metrics.service
systemctl daemon-reload
systemctl start iorestoacasa_metrics.service
