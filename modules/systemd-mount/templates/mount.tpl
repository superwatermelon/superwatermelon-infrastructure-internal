[Unit]
Requires=dev-${volume}.device ${requires}
After=dev-${volume}.device ${after}
[Mount]
What=/dev/${volume}
Where=${mount_point}
Type=${type}
[Install]
WantedBy=multi-user.target
