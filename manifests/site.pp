Exec {
    path => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ]
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

include cntlm	