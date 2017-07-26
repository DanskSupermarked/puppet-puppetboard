# puppetboard
# ===========================
# Authors
# -------
# Benjamin Merot <benjamin.merot@dsg.dk>
#
# Copyright
# ---------
# Copyright 2017 Dansk Supermarked.
#
class puppetboard (
  String $config_err_log_path,
  Boolean $config_generate_supervisor_conf,
  Integer[1, default] $config_gunicorn_threads,
  Integer[1, default] $config_gunicorn_worker_connections,
  Integer[1, 65535] $config_listen_port,
  String $config_log_folder,
  String $config_puppetboard_conf_path,
  String $config_supervisord_conf_file,
  String $config_supervisord_conf_folder,
  String $config_supervisord_include_rule,
  String $gevent_pkg_ensure,
  String $gunicorn_pkg_ensure,
  String $install_path,
  Boolean $install_site_packages,
  Boolean $manage_gcc,
  Boolean $manage_pip,
  Boolean $manage_supervisord,
  String $pip_package_ensure,
  String $pip_package_name,
  String $service_name,
  Boolean $supervisor_from_pip,
  String $supervisor_pkg_ensure,
  String $supervisor_pkg_name,
  Boolean $use_gevent,
  String $version,
) {

  if $manage_pip {
    package { $pip_package_name:
      ensure => pip_package_ensure,
      notify => [
        Package['gunicorn'],
        Package['puppetboard'],
        Package[$supervisor_pkg_name]
      ],
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
    ensure          => $gunicorn_pkg_ensure,
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
    package { $supervisor_pkg_name :
      ensure   => $supervisor_pkg_ensure,
      provider => 'pip',
    }

    file { '/etc/init.d/supervisord':
      ensure => 'file',
      notify => Service['supervisord'],
      source => 'puppet:///modules/puppetboard/supervisord',
    }
  } else {
    package { $supervisor_pkg_name:
      ensure => $supervisor_pkg_ensure,
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
      ensure          => $gevent_pkg_ensure,
      install_options => $pip_install_options,
      provider        => 'pip',
    }
  }

  service { 'puppetboard':
    ensure    => 'running',
    restart   => 'supervisorctl reread puppetboard && supervisorctl update puppetboard && supervisorctl restart puppetboard',
    start     => 'supervisorctl start puppetboard',
    status    => 'supervisorctl status puppetboard',
    stop      => 'supervisorctl stop puppetboard',
    subscribe => Service['supervisord'],
  }

  if $manage_supervisord {
    service { 'supervisord':
      ensure  => 'running',
      require => Package['supervisor'],
    }
  }

  contain puppetboard::config

  # log rotation rule for gunicorn/supervisor?

}
