#!/bin/bash
# https://docs.mongodb.com/manual/tutorial/transparent-huge-pages/

echo '[Unit]
Description=Disable Transparent Huge Pages (THP)
DefaultDependencies=no
After=sysinit.target local-fs.target
Before=mongod.service
[Service]
Type=oneshot
ExecStart=/bin/sh -c '\''echo never | tee /sys/kernel/mm/transparent_hugepage/enabled > /dev/null'\''
ExecStart=/bin/sh -c '\''echo never | tee /sys/kernel/mm/transparent_hugepage/defrag > /dev/null'\''
ExecStart=/bin/sh -c '\''blockdev --setra 256 /dev/dm-0'\''[Install]
WantedBy=basic.target' > \
/etc/systemd/system/disable-transparent-huge-pages.service

sudo systemctl daemon-reloadva

sudo systemctl start disable-transparent-huge-pages
sudo systemctl enable disable-transparent-huge-pages
