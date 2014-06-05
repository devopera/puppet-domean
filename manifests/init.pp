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
      before => [Anchor['domean-ready']],
    }
  }
  if ! defined(Class['domongodb']) {
    class { 'domongodb' :
      user => $user,
      before => [Anchor['domean-ready']],
    }
  }

  if ! defined(Package['meanio']) {
    package { 'meanio':
      ensure   => present,
      provider => 'npm',
      require => [Class['donodejs'], Class['domongodb']],
      before => [Anchor['domean-ready']],
    }
  }

  anchor { 'domean-ready': }
}