data "template_file" "git_service_unit" {
  template = <<EOF
[Unit]
Requires=home-git.service docker.service
After=home-git.service docker.service
[Service]
Restart=always
ExecStartPre=/usr/bin/docker pull superwatermelon/git:v0.1.0
ExecStart=/usr/bin/docker run \
  --rm \
  --publish 22:22 \
  --volume /home/git/ssh:/etc/ssh \
  --volume /home/git/repos:/var/git \
  --name git superwatermelon/git:v0.1.0
[Install]
WantedBy=multi-user.target
EOF
}

data "template_file" "git_sshd_socket_unit" {
  template = <<EOF
[Unit]
Conflicts=sshd.service
[Socket]
ListenStream=2222
FreeBind=true
Accept=yes
[Install]
WantedBy=sockets.target
EOF
}

data "template_file" "git_home_service_unit" {
  template = <<EOF
[Unit]
Requires=home-git.mount
After=home-git.mount
[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/bin/chown -R git:git /home/git
[Install]
WantedBy=multi-user.target
EOF
}

#
# Formatting in multi-user.target rather than local-fs.target
# as local-fs.target appears to be too soon and results in
# the format script occasionally reformatting an already
# formatted disk. The multi-user.target happens later. The
# following provides some useful information:
#
# https://www.freedesktop.org/software/systemd/man/bootup.html#System%20Manager%20Bootup
#
data "template_file" "git_home_mount_unit" {
  template = <<EOF
[Unit]
Requires=dev-$${volume}1.device
After=dev-$${volume}1.device git-format.service
[Mount]
What=/dev/$${volume}1
Where=/home/git
Type=ext4
[Install]
WantedBy=multi-user.target
EOF
  vars = {
    volume = "${var.git_volume_device}"
  }
}

data "template_file" "git_format_service" {
  template = <<EOF
[Unit]
Requires=dev-$${volume}.device
After=dev-$${volume}.device
[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/bin/bash -xc "parted /dev/$${volume} mklabel gpt mkpart primary 0%% 100%% && mkfs.ext4 /dev/$${volume}1"
[Install]
WantedBy=multi-user.target
EOF
  vars = {
    volume = "${var.git_volume_device}"
  }
}
