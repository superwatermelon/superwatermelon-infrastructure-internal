[Unit]
Requires=home-jenkins.service docker.service
After=home-jenkins.service docker.service
[Service]
Restart=always
ExecStartPre=/usr/bin/docker pull ${docker_image}
ExecStart=/usr/bin/docker run \
  --rm \
  --publish 8080:8080 \
  --volume ${mount_point}:/var/jenkins_home \
  --env-file ${env_file} \
  --name ${container_name} \
  ${docker_image}
[Install]
WantedBy=multi-user.target
