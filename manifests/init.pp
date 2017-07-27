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
  Boolean $config_generate_supervisor_conf,
  Integer[1, default] $config_gunicorn_threads,
  Integer[1, default] $config_gunicorn_worker_connections,
  Integer[1, 65535] $config_listen_port,
  String $config_log_folder,
  String $config_puppetboard_conf_path,
  String $config_supervisord_conf_file,
  String $config_supervisord_conf_folder,
  String $config_supervisord_include_rule,
  Integer[1, 365] $daily_reports_chart_days,
  String $default_environment,
  String $gevent_pkg_ensure,
  Boolean $gevent_use_wheel_bin,
  String $gunicorn_pkg_ensure,
  String $install_path,
  Boolean $install_site_packages,
  Integer[1, 100] $little_table_count,
  Enum['critical', 'debug', 'error', 'info', 'warning'] $log_level,
  Boolean $manage_pip,
  Boolean $manage_supervisord,
  Boolean $manage_user,
  Integer[1, 200] $normal_table_count,
  String $pip_package_ensure,
  String $pip_package_name,
  String $puppetdb_host,
  Integer[1, 65535] $puppetdb_port,
  Integer[1, 120] $puppetdb_timeout,
  String $python_devel_pkg,
  Integer[1, 240] $refresh_rate,
  String $run_as_user,
  String $service_name,
  String $settings_path,
  Boolean $supervisor_from_pip,
  String $supervisor_pkg_ensure,
  String $supervisor_pkg_name,
  Integer[1, 96] $unresponsive_hours,
  Boolean $use_gevent,
  String $version,
) {

  if $manage_pip {
    package { $pip_package_name:
      ensure => $pip_package_ensure,
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
    if !$gevent_use_wheel_bin {
      package { $python_devel_pkg:
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

  if $manage_user {
    group { $run_as_user :
      ensure => present,
      system => true,
    }

    user { $run_as_user :
      gid     => $run_as_user,
      require => Group[$run_as_user],
      shell   => '/bin/false',
      system  => true,
    }
  }

  file { $settings_path :
    ensure  => 'file',
    content => template('puppetboard/settings.py.erb'),
    notify  => Service['puppetboard'],
  }

  service { 'puppetboard':
    ensure    => 'running',
    require   => Package['puppetboard'],
    restart   => 'supervisorctl reread puppetboard && supervisorctl update puppetboard && supervisorctl restart puppetboard',
    start     => 'supervisorctl start puppetboard',
    status    => 'supervisorctl status puppetboard | grep RUNNING',
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

}
