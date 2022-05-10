package-install "libtemplate-perl carton";

my $user = "sph";

systemd-service "sparrow6hub", %(
  user => $user,
  workdir => "/home/$user/projects/Sparrow6Hub",
  command => "/usr/bin/bash  --login -c 'cro run 1>>~/.Sparrow6Hub.log 2>&1'"
);

bash "systemctl daemon-reload";

# start service

service-restart "sparrow6hub";

service-enable "sparrow6hub";

