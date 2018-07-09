[Unit]
Requires=home-jenkins.mount
After=home-jenkins.mount
[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/bin/rsync -rdavh --progress /mnt/jenkins/ /home/jenkins/
ExecStart=/usr/bin/chown -R jenkins:jenkins /home/jenkins
[Install]
WantedBy=multi-user.target
