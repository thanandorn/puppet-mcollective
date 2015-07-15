# private class
class mcollective::server::config {
  if $caller_module_name != $module_name {
    fail("Use of private class ${name} by ${caller_module_name}")
  }

  case $::kernel {
    'windows': {
      $site_confdir_owner = 'Administrator'
      $site_confdir_group = 'Administrators'
    }
    default: {
      $site_confdir_owner = 'root',
      $site_confdir_group = '0'
    }

    datacat { 'mcollective::server':
      owner    => $site_confdir_owner,
      group    => $site_confdir_group,
      mode     => '0400',
      path     => $mcollective::server_config_file_real,
      template => 'mcollective/settings.cfg.erb',
    }

    mcollective::server::setting { 'classesfile':
      value => $mcollective::classesfile,
    }

    mcollective::server::setting { 'daemonize':
      value => $mcollective::server_daemonize,
    }

    mcollective::server::setting { 'logfile':
      value => $mcollective::server_logfile,
    }

    mcollective::server::setting { 'loglevel':
      value => $mcollective::server_loglevel,
    }

    file { "${mcollective::confdir}/policies":
      ensure => 'directory',
      owner  => $site_confdir_owner,
      group  => $site_confdir_group,
      mode   => '0700',
    }

    if $mcollective::middleware_ssl or $mcollective::securityprovider == 'ssl' {
      file { "${mcollective::confdir}/ca.pem":
        owner    => $site_confdir_owner,
        group    => $site_confdir_group,
        mode   => '0444',
        source => $mcollective::ssl_ca_cert,
      }

      file { "${mcollective::confdir}/server_public.pem":
        owner    => $site_confdir_owner,
        group    => $site_confdir_group,
        mode   => '0444',
        source => $mcollective::ssl_server_public,
      }

      file { "${mcollective::confdir}/server_private.pem":
        owner    => $site_confdir_owner,
        group    => $site_confdir_group,
        mode   => '0400',
        source => $mcollective::ssl_server_private,
      }
    }

    mcollective::soft_include { [
        "::mcollective::server::config::connector::${mcollective::connector}",
        "::mcollective::server::config::securityprovider::${mcollective::securityprovider}",
        "::mcollective::server::config::factsource::${mcollective::factsource}",
        "::mcollective::server::config::registration::${mcollective::registration}",
        "::mcollective::server::config::rpcauditprovider::${mcollective::rpcauditprovider}",
        "::mcollective::server::config::rpcauthprovider::${mcollective::rpcauthprovider}",
      ]:
        start => Anchor['mcollective::server::config::begin'],
        end   => Anchor['mcollective::server::config::end'],
    }

    anchor { 'mcollective::server::config::begin': }
    anchor { 'mcollective::server::config::end': }
  }
