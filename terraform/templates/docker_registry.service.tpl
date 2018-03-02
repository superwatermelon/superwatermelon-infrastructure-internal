[Unit]
Requires=var-lib-registry.mount docker.service
After=var-lib-registry.mount docker.service
[Service]
Restart=always
ExecStartPre=/usr/bin/docker pull registry:2.5.2
ExecStart=/usr/bin/docker run --rm --publish 5000:5000 --volume /var/lib/registry:/var/lib/registry --name registry registry:2.5.2
[Install]
WantedBy=multi-user.target
