class domean (

  # class arguments
  # ---------------
  # setup defaults

  $user = 'web',

  # end of class arguments
  # ----------------------
  # begin class

) {

  # include node and mongo
  if ! defined(Class['donodejs']) {
    class { 'donodejs' :
      user => $user,
      require => [Class['docommon'], Class['dozendserver'], Class['dorepos']],
    }
  }
  if ! defined(Class['domongodb']) {
    class { 'domongodb' :
      user => $user,
    }
  }

  if ! defined(Package['meanio']) {
    package { 'meanio':
      ensure   => present,
      provider => 'npm',
      require => [Class['donodejs'], Class['domongodb']],
    }
  }

}