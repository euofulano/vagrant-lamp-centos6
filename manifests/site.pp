###############################################################################
# - https://github.com/pipe-devnull/vagrant-dev-lamp
# - https://github.com/puphpet/vagrant-puppet-lamp
# - https://github.com/vagrantee/vagrantee
# - 
#
#
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

define yumgroup($ensure = "present", $optional = false) {
   case $ensure {
      present,installed: {
         $pkg_types_arg = $optional ? {
            true => "--setopt=group_package_types=optional,default,mandatory",
            default => ""
         }
         exec { "Installing $name yum group":
            command => "yum -y groupinstall $pkg_types_arg $name",
            unless => "yum -y groupinstall $pkg_types_arg $name --downloadonly",
            timeout => 600,
         }
      }
   }
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
		command => "rpm -Uvh http://download.fedoraproject.org/pub/epel/6/i386/epel-release-6-8.noarch.rpm",
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
	
	yumgroup { '"Development tools"': }
	  
	package {['vim-enhanced', 'vim-common', 'vim-minimal', 'telnet','zip','unzip','git','nodejs','npm','upstart', 'zlib-devel', 'lynx', 'sendmail', 'sendmail-cf']:
		ensure => latest,
		require => Exec['yum-update']
	} 
}


class {'cntlm': 
	# Força a execução do cntlm antes de todos as outras tarefas
	stage => setup
}
	
class{'init': }
class{'apache': }

apache::dotconf { 'custom':
  content => 'EnableSendfile Off',
}

apache::module { 'rewrite': }

class { 'php':
  service => 'apache',
  require => Package['apache'],
}

php::module {['common', 'mysql', 'cli', 'intl', 'mcrypt', 'gd', 'xml', 'xmlrpc', 'mbstring', 'bcmath', 'dba', 'embedded', 'enchant', 'imap']: }

file { "/etc/php.d/extra.ini":
	ensure  => 'present',
	source => '/vagrant/files/extra.ini',
	require => Package['php'],
	notify  => Service['httpd'],
}

php::pecl::config { http_proxy: value => "http://localhost:3128" }
php::pecl::config { auto_discover: value => "1" }

file { "/var/www/html/phpinfo.php":
	owner   => "root",
	group   => "root",
	mode    => 644,
	replace => true,
	ensure  => present,
	content => '<?php phpinfo(); ?>',
	require => Class["php"]
}

class { 'php::pear':
  require => Class['php'],
}

class { 'php::devel':
  require => Class['php'],
}

#class { 'php::composer':
#  require => Package['php', 'curl'],
#}

class { "mysql":
  root_password => '123456',
}