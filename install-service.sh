#!/bin/bash -xe
set -xe

SERVICE="artifact-server"

exec 1> >(logger -s -t $(basename $0)) 2>&1

echo "[Unit]
Description=ArtifactServer
After=multi-user.target

[Service]
ExecStart=/bin/bash -c '/datadisk/docker.$SERVICE/run-docker.sh >> /tmp/$SERVICE.log 2>&1'
ExecStop=/bin/bash -c '/datadisk/docker.$SERVICE/run-docker.sh stop=true >> /tmp/$SERVICE.log 2>&1'

[Install]
WantedBy=multi-user.target
" | sudo tee /lib/systemd/system/$SERVICE.service

sudo systemctl daemon-reload
sudo systemctl start $SERVICE.service
sudo systemctl enable $SERVICE.service
