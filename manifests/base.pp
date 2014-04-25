define domean::base (

  # class arguments
  # ---------------
  # setup defaults

  $user = 'web',
  $port = 3000,
  $app_name = $title,
  $content = 'MEAN',

  # install directory
  $target_dir = '/var/www/html',

  $firewall = true,
  $monitor = true,
  
  # create symlink and if so, where
  $symlinkdir = false,

  # end of class arguments
  # ----------------------
  # begin class

) {

  if ($firewall) {
    # open port
    @docommon::fireport { "domean-node-server-${port}":
      port => $port,
      protocol => 'tcp',
    }
  }

  if ($monitor) {
    # setup monitoring
    @nagios::service { "http_content:${port}-domean-${::fqdn}":
      # no DNS, so need to refer to machine by external IP address
      check_command => "check_http_port_url_content!${::ipaddress}!${port}!/!'${content}'",
    }
    @nagios::service { "int:process_node-domean-${::fqdn}":
      check_command => "check_procs!1:!1:!node",
    }
  }

  # if we've got a message of the day, include
  @domotd::register { "MEAN(${port})" : }

  # create and inflate node/mean example
  exec { "domean-base-create-${title}" :
    path => '/bin:/usr/bin:/sbin:/usr/sbin',
    command => "mean init ${app_name} && cd ${app_name} && npm install",
    user => $user,
    cwd => "${target_dir}",
  }

  # create symlink from our home folder
  if ($symlinkdir) {
    # create symlink from directory to repo (e.g. user's home folder)
    file { "${symlinkdir}/${app_name}" :
      ensure => 'link',
      target => "${target_dir}/${app_name}",
      require => [Exec["domean-base-create-${title}"]],
    }
  }

}
