data "template_file" "gitlist_nginx_service_unit" {
  template = <<EOF
[Unit]
Requires=git.service gitlist-php-fpm.service docker.service
After=git.service gitlist-php-fpm.service docker.service
[Service]
Restart=always
ExecStartPre=/usr/bin/docker pull superwatermelon/gitlist-nginx:0.5.0
ExecStart=/usr/bin/docker run \
  --rm \
  --publish 80:80 \
  --link gitlist-php-fpm:gitlist-php-fpm \
  --name gitlist-nginx superwatermelon/gitlist-nginx:0.5.0
[Install]
WantedBy=multi-user.target
EOF
}

data "template_file" "gitlist_php_fpm_service_unit" {
  template = <<EOF
[Unit]
Requires=git.service docker.service
After=git.service docker.service
[Service]
Restart=always
ExecStartPre=/usr/bin/docker pull superwatermelon/gitlist-php-fpm:0.5.0
ExecStart=/usr/bin/docker run \
  --rm \
  --volume /home/git/repos:/var/git:ro \
  --name gitlist-php-fpm superwatermelon/gitlist-php-fpm:0.5.0
[Install]
WantedBy=multi-user.target
EOF
}
