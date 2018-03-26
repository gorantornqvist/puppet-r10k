class r10k::profile_webhook(
  $proxy_hostname = undef,
  $proxy_port = undef,
  $no_proxy = undef
)
{

  # Usage example profile

  if $proxy_hostname != undef and $proxy_port != undef {
    $environmentfile="http_proxy=http://${proxy_hostname}:${proxy_port}\nhttps_proxy=http://${proxy_hostname}:${proxy_port}\nno_proxy=${no_proxy}\n"
    file {'/etc/sysconfig/webhook':
      ensure  => present,
      content => $environmentfile,
      before  => Class['::r10k::webhook'],
    }
  }

  file {'/usr/local/bin/prefix_command.rb':
    ensure => file,
    mode   => '0755',
    owner  => 'root',
    group  => '0',
    source => 'puppet:///modules/r10k/prefix_command.bitbucket.rb',
  }

  file {'/usr/local/bin/r10k-postrun.sh':
    ensure => file,
    mode   => '0755',
    owner  => 'root',
    group  => '0',
    source => 'puppet:///modules/r10k/r10k-postrun.sh',
    before  => Class['::r10k::webhook'],
  }

  class {'::r10k::webhook':
    use_mcollective  => false,
    manage_packages  => false,
    user             => 'root',
    group            => 'root',
    bin_template     => 'r10k/webhook.custom.bin.erb',
    service_template => 'webhook.custom.service.erb',
    require          => Class['r10k::webhook::config'],
  }

  class {'::r10k::webhook::config':
    use_mcollective           => false,
    protected                 => false,
    r10k_deploy_arguments     => '--config /etc/puppet/r10k/r10k.yaml --verbose error',
    r10k_deploymodule_postrun => '/usr/local/bin/r10k-postrun.sh module',
    public_key_path           => "/etc/pki/tls/certs/host.crt",
    private_key_path          => "/etc/pki/tls/private/host.key",
    prefix                    => true,
    prefix_command            => '/usr/local/bin/prefix_command.rb',
    require                   => File['/usr/local/bin/prefix_command.rb'],
  }

}
