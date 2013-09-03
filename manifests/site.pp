Exec {
    path => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ]
}

class cntlm {
	$proxy_username = 't31291157816'
	$proxy_domain = 'DASA'
	$proxy_password = '7187A15D1382A8D03C856613F5A554FE'
	$proxy_url = 'proxy-sp@dasa.net'
	$proxy_port = '3128'
	$proxy_no_proxy = 'localhost, 127.0.0.*, 10.*, 192.168.*, *.dasa.com.br, *.dasa.net, 172.*'
	$proxy_listen = '3128'	

	exec {'install-cntlm':
		command => 'rpm -Uvh /vagrant/files/cntlm-*.rpm'
	}
	
	file { '/etc/cntlm.conf':
		mode => '0644',
		owner   => "root",
		group   => "root",
		ensure => present,
		replace => true,
		require => Exec['install-cntlm'],
		notify => Service['cntlmd'],
		content => template("cntlm/cntml.conf.erb")
	}
	
	service { 'cntlmd':
		ensure => 'running'
	}
}

include cntlm	