class loadbalancer::haproxy {
    $lbvip = ""
    $lb1_host = "lb1.domain.tld"
    $lb2_host = "lb2.domain.tld"
    $lb1_ip = ""
	$lb2_ip = ""
    $bk1_ip = ""
    $bk2_ip = ""
    $authkey = "Azerty1234"
    package { "ipvsadm" : ensure => present }
    package { "keepalived" : ensure => present }
    package { "haproxy": ensure => present }
    package { "hatop": ensure => present }
    package { "socat": ensure => present }

    sysctl { 'net.ipv4.ip_forward': value => '1' }
    sysctl { 'net.ipv4.ip_nonlocal_bind': value => '1' }
	sysctl { 'net.ipv4.tcp_tw_recycle': value => '0' }
    sysctl { 'fs.file-max': value => '10000000' }
    sysctl { 'net.ipv4.tcp_mem': value => '786432 1697152 1945728' }
    sysctl { 'net.ipv4.tcp_rmem': value => '4096 4096 16777216' }
    sysctl { 'net.ipv4.tcp_wmem': value => '4096 4096 16777216' }
    sysctl { 'net.ipv4.ip_local_port_range': value => '1000 65535' }

    file_line { 'haproxy_soft_nofile':
        line => '* soft nofile 10000000',
        path => '/etc/security/limits.conf',
    }

    file_line { 'haproxy_hard_nofile':
        line => '* hard nofile 10000000',
        path => '/etc/security/limits.conf',
    }

    file_line { 'haproxy_root_soft_nofile':
        line => 'root soft nofile 10000000',
        path => '/etc/security/limits.conf',
    }

    file_line { 'haproxy_root_hard_nofile':
        line => 'root hard nofile 10000000',
        path => '/etc/security/limits.conf',
    }

    if $fqdn == $lb1_host {
        file { "/etc/keepalived/keepalived.conf":
            mode   => "640",
            owner  => root,
            group  => root,
            content => template('${module_name}/keepalived-primary.conf.erb')
        }
    }
    if $fqdn == $lb2_host {
	    file { "/etc/keepalived/keepalived.conf":
    	    mode   => "640",
      		owner  => root,
      	    group  => root,
      	    content => template('${module_name}/keepalived-secondary.conf.erb')
        }
    }

    file { "/etc/init.d/firewall-loadbalancer":
        mode   => "755",
        owner  => root,
        group  => root,
        source => "puppet:///modules/${module_name}/firewall-loadbalancer"
    }

    service { "firewall-loadbalancer":
        ensure => "running",
    	enable => true,
    	require => File["/etc/init.d/firewall-loadbalancer"]
    }

    file { "/etc/haproxy/haproxy.cfg":
    	mode   => "440",
    	owner  => root,
    	group  => root,
    	content => template('${module_name}/haproxy.cfg.erb')
    }

    file { "/etc/default/haproxy":
    	mode   => "644",
    	owner  => root,
    	group  => root,
    	source => "puppet:///modules/loadbalancer/haproxy-enable"
    }

    service { "haproxy":
        ensure => "running",
	    enable => true,
    	subscribe => File['/etc/haproxy/haproxy.cfg'],
    }
}
