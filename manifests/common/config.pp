#
class mcollective::common::config {
  if $caller_module_name != $module_name {
    fail("Use of private class ${name} by ${caller_module_name}")
  }

  case $::kernel {
    'windows': {
      $site_libdir_owner = 'Administrator'
      $site_libdir_group = 'Administrators'
      mcollective::common::setting { 'libdir':
        value => "${mcollective::site_libdir};${mcollective::core_libdir}",
      } # Windows uses semicolons to separate paths to avoid a clash with drive letters
    }
    default: {
      $site_libdir_owner = 'root'
      $site_libdir_group = '0'
      mcollective::common::setting { 'libdir':
        value => "${mcollective::site_libdir}:${mcollective::core_libdir}",
      }
    }
  }

  file { $mcollective::site_libdir:
    ensure       => directory,
    owner        => $site_libdir_owner,
    group        => $site_libdir_group,
    mode         => '0644',
    recurse      => true,
    purge        => true,
    force        => true,
    source       => [],
    sourceselect => 'all',
  }

  if $mcollective::server {
    # if we have a server install, reload when the plugins change
    File[$mcollective::site_libdir] ~> Class['mcollective::server::service']
  }

  datacat_collector { 'mcollective::site_libdir':
    before          => File[$mcollective::site_libdir],
    target_resource => File[$mcollective::site_libdir],
    target_field    => 'source',
    source_key      => 'source_path',
  }

  datacat_fragment { 'mcollective::site_libdir':
    target => 'mcollective::site_libdir',
    data   => {
      source_path => [ 'puppet:///modules/mcollective/site_libdir' ],
    }
  }

  mcollective::common::setting { 'connector':
    value => $mcollective::connector,
  }

  mcollective::common::setting { 'securityprovider':
    value => $mcollective::securityprovider,
  }

  mcollective::common::setting { 'collectives':
    value => join(flatten([$mcollective::collectives]), ','),
  }

  mcollective::common::setting { 'main_collective':
    value => $mcollective::main_collective,
  }

  mcollective::soft_include { [
      "::mcollective::common::config::connector::${mcollective::connector}",
      "::mcollective::common::config::securityprovider::${mcollective::securityprovider}",
    ]:
      start => Anchor['mcollective::common::config::begin'],
      end   => Anchor['mcollective::common::config::end'],
  }

  anchor { 'mcollective::common::config::begin': }
  anchor { 'mcollective::common::config::end': }
}
