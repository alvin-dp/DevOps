[Unit]
Description=Custom rundeck service
After=network-online.target
After=network.service

[Service]
Type=simple
WorkingDirectory=/opt/rundeck
ExecStart=/usr/bin/java ${rundeck_args} -jar /opt/rundeck/rundeck-${rundeck_version}.war
TimeoutSec=180
KillMode=process
Restart=on-failure