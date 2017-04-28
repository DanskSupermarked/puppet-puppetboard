# Class: puppetboard::config
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
class puppetboard::config (
  $err_log_path,
  $generate_supervisor_conf,
  $gunicorn_threads,
  $gunicorn_worker_connections,
  $listen_port,
  $log_path,
  $puppetboard_conf_path,
  $supervisord_conf_file,
  $supervisord_conf_folder,
  $supervisord_include_rule,
) {

  file { $supervisord_conf_folder:
    ensure => 'directory',
  }

  if $generate_supervisor_conf {
    exec { 'generate_supervisor_conf':
      command => "echo_supervisord_conf > ${supervisord_conf_file}",
      creates => $supervisord_conf_file,
      notify  => Ini_setting['supervisord_include'],
      path    => '/usr/bin',
      require => Package['supervisor'],
    }
  }

  ini_setting { 'supervisord_include':
    notify  => Service['supervisord'],
    path    => '/etc/supervisord.conf',
    section => 'include',
    setting => 'files',
    value   => $supervisord_include_rule,
  }

  if $puppetboard::use_gevent {
    $gunicorn_puppetboard_cmd = "gunicorn -b ${::ipaddress_lo}:${listen_port} --worker-class gevent --threads ${gunicorn_threads} --worker-connections ${gunicorn_worker_connections} puppetboard.app:app"
  } else {
    $gunicorn_puppetboard_cmd = "gunicorn -b ${::ipaddress_lo}:${listen_port} puppetboard.app:app"
  }

  ini_setting { 'supervisor_puppetboard_command':
    notify  => Service['puppetboard'],
    path    => $puppetboard_conf_path,
    require => File[$supervisord_conf_folder],
    section => 'program:puppetboard',
    setting => 'command',
    value   => $gunicorn_puppetboard_cmd,
  }

  ini_setting { 'supervisor_puppetboard_directory':
    notify  => Service['puppetboard'],
    path    => $puppetboard_conf_path,
    require => File[$supervisord_conf_folder],
    section => 'program:puppetboard',
    setting => 'directory',
    value   => $puppetboard::install_path,
  }

  ini_setting { 'supervisor_puppetboard_environment':
    notify  => Service['puppetboard'],
    path    => $puppetboard_conf_path,
    require => File[$supervisord_conf_folder],
    section => 'program:puppetboard',
    setting => 'environment',
    value   => "PUPPETBOARD_SETTINGS=\"${puppetboard::install_path}/puppetboard/settings.py\"",
  }

  ini_setting { 'supervisor_puppetboard_log':
    notify  => Service['puppetboard'],
    path    => $puppetboard_conf_path,
    require => File[$supervisord_conf_folder],
    section => 'program:puppetboard',
    setting => 'stdout_logfile',
    value   => $log_path,
  }

  ini_setting { 'supervisor_puppetboard_log_err':
    notify  => Service['puppetboard'],
    path    => $puppetboard_conf_path,
    require => File[$supervisord_conf_folder],
    section => 'program:puppetboard',
    setting => 'stderr_logfile',
    value   => $err_log_path,
  }

}
