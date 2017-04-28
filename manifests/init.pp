# Class: puppetboard
# ===========================
#
# Parameters
# ----------
#
#
# Variables
# ----------
#
#
# Examples
# --------
#
# Authors
# -------
#
# Benjamin Merot <benjamin.merot@dsg.dk>
#
# Copyright
# ---------
#
# Copyright 2017 Dansk Supermarked.
#
class puppetboard (
  $install_path,
  $install_site_packages,
  $manage_gcc,
  $manage_pip,
  $manage_supervisord,
  $pip_package_ensure,
  $pip_package_name,
  $service_name,
  $supervisor_dist_pkg_name,
  $supervisor_from_pip,
  $supervisord_conf_file,
  $use_gevent,
  $version,
) {

  if $manage_pip {
    package { $pip_package_name:
      ensure   => pip_package_ensure,
      notify   => Package['supervisor'],
      provider => 'pip',
    }
  }

  if !$install_site_packages {
    $pip_install_options = [
      '--ignore-installed',
      {
        '--target' => $install_path
      },
      '--upgrade'
    ]
  } else {
    $pip_install_options = []
  }

  package { 'gunicorn':
    ensure          => 'present',
    install_options => $pip_install_options,
    provider        => 'pip',
  }

  package { 'puppetboard':
    ensure          => $version,
    install_options => $pip_install_options,
    notify          => Service[$service_name],
    provider        => 'pip',
  }

  if $supervisor_from_pip {
    package { 'supervisor':
      ensure   => 'present',
      provider => 'pip',
    }

    file { '/etc/init.d/supervisord':
      ensure => 'file',
      source => 'puppet:///modules/puppetboard/supervisord',
    }

    file { '/etc/supervisord.d':
      ensure => 'directory',
    }

    file { '/var/log/supervisor':
      ensure => 'directory',
    }
  } else {
    package { $supervisor_dist_pkg_name:
      ensure   => 'present',
    }
  }

  if $use_gevent {
    if $manage_gcc {
      package { 'gcc':
        ensure => 'present',
        notify => Package['gevent'],
      }
    }

    package { 'gevent':
      ensure          => 'present',
      install_options => $pip_install_options,
      provider        => 'pip',
    }
  }

  service { 'puppetboard':
    ensure  => 'running',
    require => Service['supervisord'],
    restart => 'supervisorctl reread puppetboard && supervisorctl update puppetboard && supervisorctl restart puppetboard',
    start   => 'supervisorctl start puppetboard',
    status  => 'supervisorctl status puppetboard',
    stop    => 'supervisorctl stop puppetboard'
  }

  if $manage_supervisord {
    service { 'supervisord':
      ensure => 'running',
      require => Package['supervisor'],
    }
  }

  class { 'puppetboard::config': }

  # log rotation rule for gunicorn/supervisor?

}
