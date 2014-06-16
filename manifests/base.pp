define domean::base (

  # class arguments
  # ---------------
  # setup defaults

  $user = 'web',
  $port = 3000,
  $port_livereload = 35729,
  $app_name = $title,
  $app_script = 'server.js',
  $content = 'MEAN',

  # install directory
  $target_dir = '/var/www/node',

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
    if ($port_livereload) {
      @docommon::fireport { "domean-node-server-livereload-${port_livereload}":
        port => $port_livereload,
        protocol => 'tcp',
      }
      @domotd::register { "LiveReload(${port_livereload})" : }
    }
  }

  if ($monitor) {
    # setup monitoring
    @nagios::service { "http_content:${port}-domean-${::fqdn}":
      # no DNS, so need to refer to machine by external IP address
      check_command => "check_http_port_url_content!${::ipaddress}!${port}!/!'${content}'",
    }
    @nagios::service { "int:process_node-domean-${::fqdn}":
      check_command => "check_nrpe_procs_node",
    }
  }

  # if we've got a message of the day, include
  @domotd::register { "MEAN(${port})" : }

  # check that target dir exists
  if ! defined(File["${target_dir}"]) {
    docommon::stickydir { "${target_dir}":
      user => $user,
      group => $group,
      context => 'httpd_sys_content_t',
      before => [Exec["domean-base-create-${title}"]],
    }
  }

  # create and inflate node/mean example
  exec { "domean-base-create-${title}" :
    path => '/bin:/usr/bin:/sbin:/usr/sbin',
    command => "mean init ${app_name} && cd ${app_name} && npm install",
    user => $user,
    cwd => "${target_dir}",
  }

  # create service and start on machine startup
  donodejs::foreverservice { "donodejs-base-service-${title}":
    app_name => $app_name,
    app_script => $app_script,
    target_dir => $target_dir,
    require => [Exec["domean-base-create-${title}"]],
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
