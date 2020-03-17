#!/bin/bash

echo "Warning: replacing JVB_OPTS in videobridge config"
sed -i.bak s/JVB_OPTS=\"\"/JVB_OPTS=\"--apis=rest,xmpp\"/g /etc/jitsi/videobridge/config

echo "Adding export statistics to sip-communicator properties"
cat << EOF >> /etc/jitsi/videobridge/sip-communicator.properties
org.jitsi.videobridge.ENABLE_STATISTICS=true
org.jitsi.videobridge.STATISTICS_TRANSPORT=muc,colibri
org.jitsi.videobridge.STATISTICS_INTERVAL=5000
EOF

echo "Restarting the videobridge"
systemctl restart jitsi-videobridge.service jicofo.service

echo "Allowing firewall on port 8082"
ufw allow in 8082/tcp

echo "Adding systemd service"
cp iorestoacasa_metrics.service /etc/systemd/system/

echo "Starting to export metrics!"
systemctl start iorestoacasa_metrics.service
systemctl enable iorestoacasa_metrics.service
