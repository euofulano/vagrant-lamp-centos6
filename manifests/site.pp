stage { setup: before => Stage[main] }

Exec {
    path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ]
}

#define apply_proxy {
#	$proxy = $name
#	notify { "Aplicando regra de proxy $name":; }
#	file_line {"/etc/yum.conf $proxy":
#		ensure => present,
#		line => $proxy,
#		path => '/etc/yum.conf'
#	}
#}

define config_proxy() {
	file {$name:
		owner   => "root",
		group   => "root",
		mode => '0644',
		ensure => present,
		replace => true,
		path => "/etc/${name}",
		source => "/vagrant/files/${name}"
	}

	notify {"Aplicando configuração de proxy em ${name}":}
}

class cntlm {
	$proxy_username = 't31291157816'
	$proxy_domain = 'DASA'
	$proxy_password = '7187A15D1382A8D03C856613F5A554FE'
	$proxy_url = 'proxy-sp.dasa.net'
	$proxy_port = '3128'
	$proxy_no_proxy = 'localhost, 127.0.0.*, 10.*, 192.168.*, *.dasa.com.br, *.dasa.net, 172.*'
	$proxy_listen = '3128'	
	$proxys = ["proxy=http://${proxy_url}:${proxy_port}","proxy=ftp://${proxy_url}:${proxy_port}","proxy=https://${proxy_url}:${proxy_port}"]	
	$config_proxys = ['yum.conf', 'profile', 'wgetrc']
	
	exec {'install-cntlm':
		command => 'rpm -Uvh /vagrant/files/cntlm-*.rpm',
		creates => "/etc/cntlm.conf"
	}
	
	file { '/etc/cntlm.conf':
		mode => '0644',
		owner   => "root",
		group   => "root",
		ensure => present,
		replace => true,
		require => Exec['install-cntlm'],
		notify => Service['cntlmd'],
		content => template("/vagrant/templates/cntlm/cntlm.conf.erb")
	}
	
	service { 'cntlmd':
		ensure => 'running'
	}
		
	config_proxy {$config_proxys:}
}

class init {
	exec { 'yum-update':
		command => '/usr/bin/yum -y update',
		require => Exec["grap-epel"],
		timeout => 60,
		tries   => 3
	}

	exec { "grap-epel":
		command => "rpm -Uvh --httpproxy 127.0.0.1 --httpport 3128 http://download.fedoraproject.org/pub/epel/6/i386/epel-release-6-8.noarch.rpm",
		creates => "/etc/yum.repos.d/epel.repo",
		alias   => "grab-epel",
		logoutput => true
	}
	
	package { "iptables": 
		ensure => present;
	}
	
	service { "iptables":
		require => Package["iptables"],
		hasstatus => true,
		status => "true",
		hasrestart => false,
	}
	
	file { "/etc/sysconfig/iptables":
		owner   => "root",
		group   => "root",
		mode    => 600,
		replace => true,
		ensure  => present,
		source  => "/vagrant/files/iptables.txt",
		require => Package["iptables"],
		notify  => Service["iptables"],
	}
	  
	  
	  
	  
}

#class repository {
  # We need cURL installed to import the key
#  package { 'curl': ensure => installed }

  # Install the GPG key
#  exec { 'import-key':
#	path    => '/bin:/usr/bin',
#    command => 'curl http://repos.servergrove.com/servergrove-rhel-6/RPM-GPG-KEY-servergrove-rhel-6 -o /etc/pki/rpm-gpg/RPM-GPG-KEY-servergrove-rhel-6',
#    unless  => 'ls /etc/pki/rpm-gpg/RPM-GPG-KEY-servergrove-rhel-6',
#    require => Package['curl'],
#  }

 # exec { "epel.repo":
 #   command => 'sudo rpm -ivh --httpproxy 127.0.0.1 --httpport 3128 http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm',
#	path    => ['/bin', '/usr/bin'],
 #   unless  => 'rpm -qa | grep epel'
#  }

  #yumrepo { 'servergrove':
  #  baseurl  => 'http://repos.servergrove.com/servergrove-rhel-6/$basearch',
  #  enabled  => 1,
  #  gpgcheck => 1,
  #  gpgkey   => 'file:///etc/pki/rpm-gpg/RPM-GPG-KEY-servergrove-rhel-6',
  #  require  => Exec['import-key']
  #}

  # Creates the source file for the ServerGrove repository
  #file { 'servergrove.repo':
  #  path    => '/etc/yum.repos.d/servergrove.repo',
  #  require => Yumrepo['servergrove']
  #}
#}

class {'cntlm': 
	# Força a execução do cntlm antes de todos as outras tarefas
	stage => setup
}	
include init