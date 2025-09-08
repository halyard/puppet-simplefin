# @summary Configure simplefin metrics
#
# @param access_url sets the SimpleFIN access URL
# @param version sets the version of simplefin-exporter to install
# @param binfile sets the install path for the simplefin-exporter binary
# @param prometheus_server_ip sets the IP range to allow for prometheus connections
# @param port to serve the metrics on
# @param interval sets how frequently to poll in seconds
class simplefin (
  String $access_url,
  String $version = 'v0.0.1',
  String $binfile = '/usr/local/bin/simplefin-exporter',
  String $prometheus_server_ip = '0.0.0.0/0',
  Integer $port = 9093,
  Integer $interval = 3600,
) {
  $kernel = downcase($facts['kernel'])
  $arch = $facts['os']['architecture'] ? {
    'x86_64'  => 'amd64',
    'arm64'   => 'arm64',
    'aarch64' => 'arm64',
    'arm'     => 'arm',
    default   => 'error',
  }

  $filename = "simplefin-exporter_${kernel}_${arch}"
  $url = "https://github.com/akerl/simplefin-exporter/releases/download/${version}/${filename}"

  file { $binfile:
    ensure => file,
    source => $url,
    mode   => '0755',
    owner  => 'root',
    group  => 'root',
    notify => Service['simplefin-exporter'],
  }

  -> file { '/usr/local/etc/simplefin-exporter.yaml':
    ensure  => file,
    mode    => '0644',
    content => template('simplefin/simplefin-exporter.yaml.erb'),
    notify  => Service['simplefin-exporter'],
  }

  -> file { '/etc/systemd/system/simplefin-exporter.service':
    ensure => file,
    source => 'puppet:///modules/simplefin/simplefin-exporter.service',
  }

  ~> service { 'simplefin-exporter':
    ensure => running,
    enable => true,
  }

  firewall { '100 allow prometheus simplefin-exporter metrics':
    source => $prometheus_server_ip,
    dport  => $port,
    proto  => 'tcp',
    action => 'accept',
  }
}
