# puppetboard::config
# ===========================
#
# Authors
# -------
# Benjamin Merot <benjamin.merot@dsg.dk>
#
# Copyright
# ---------
# Copyright 2017 Dansk Supermarked.
#
class puppetboard::config inherits puppetboard{

  file { $puppetboard::config_supervisord_conf_folder :
    ensure => 'directory',
  }

  if $puppetboard::config_generate_supervisor_conf {
    exec { 'generate_supervisor_conf':
      command => "echo_supervisord_conf > ${puppetboard::config_supervisord_conf_file}",
      creates => $puppetboard::config_supervisord_conf_file,
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
    value   => $puppetboard::config_supervisord_include_rule,
  }

  if $puppetboard::use_gevent {
    $gunicorn_puppetboard_cmd = "gunicorn -b ${::ipaddress_lo}:${puppetboard::config_listen_port} --worker-class gevent --threads ${puppetboard::config_gunicorn_threads} --worker-connections ${puppetboard::config_gunicorn_worker_connections} puppetboard.app:app"
  } else {
    $gunicorn_puppetboard_cmd = "gunicorn -b ${::ipaddress_lo}:${puppetboard::config_listen_port} puppetboard.app:app"
  }

  ini_setting { 'supervisor_puppetboard_command':
    notify  => Service['puppetboard'],
    path    => $puppetboard::config_puppetboard_conf_path,
    require => File[$puppetboard::config_supervisord_conf_folder],
    section => 'program:puppetboard',
    setting => 'command',
    value   => $gunicorn_puppetboard_cmd,
  }

  ini_setting { 'supervisor_puppetboard_directory':
    notify  => Service['puppetboard'],
    path    => $puppetboard::config_puppetboard_conf_path,
    require => File[$puppetboard::config_supervisord_conf_folder],
    section => 'program:puppetboard',
    setting => 'directory',
    value   => $puppetboard::install_path,
  }

  ini_setting { 'supervisor_puppetboard_environment':
    notify  => Service['puppetboard'],
    path    => $puppetboard::config_puppetboard_conf_path,
    require => File[$puppetboard::config_supervisord_conf_folder],
    section => 'program:puppetboard',
    setting => 'environment',
    value   => "PUPPETBOARD_SETTINGS=\"${puppetboard::install_path}/puppetboard/settings.py\"",
  }

  ini_setting { 'supervisor_puppetboard_log':
    notify  => Service['puppetboard'],
    path    => $puppetboard::config_puppetboard_conf_path,
    require => [
      File[$puppetboard::config_log_folder],
      File[$puppetboard::config_supervisord_conf_folder]
    ],
    section => 'program:puppetboard',
    setting => 'stdout_logfile',
    value   => "${puppetboard::config_log_folder}/puppetboard.log",
  }

  ini_setting { 'supervisor_puppetboard_log_err':
    notify  => Service['puppetboard'],
    path    => $puppetboard::config_puppetboard_conf_path,
    require => File[$puppetboard::config_supervisord_conf_folder],
    section => 'program:puppetboard',
    setting => 'stderr_logfile',
    value   => "${puppetboard::config_log_folder}/puppetboard.error.log",
  }

  if $puppetboard::manage_user and $puppetboard::config_listen_port > 1024 {
    $supervisor_puppetboard_user_ensure = 'present'

    file { $puppetboard::config_log_folder :
      ensure       => 'directory',
      group        => $puppetboard::run_as_user,
      owner        => $puppetboard::run_as_user,
      recurse      => true,
      recurselimit => 1,
    }
  } else {
    $supervisor_puppetboard_user_ensure = 'absent'

    file { $puppetboard::config_log_folder :
      ensure => 'directory',
    }
  }

  ini_setting { 'supervisor_puppetboard_user':
    ensure  => $supervisor_puppetboard_user_ensure,
    notify  => Service['puppetboard'],
    path    => $puppetboard::config_puppetboard_conf_path,
    require => File[$puppetboard::config_supervisord_conf_folder],
    section => 'program:puppetboard',
    setting => 'user',
    value   => $puppetboard::run_as_user,
  }

}
