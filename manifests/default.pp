define append_if_no_such_line($file, $line, $refreshonly = 'false') {
   exec { "/bin/echo '$line' >> '$file'":
      unless      => "/bin/grep -Fxqe '$line' '$file'",
      path        => "/bin",
      refreshonly => $refreshonly,
   }
}

class must-have {
  include apt
  include postgresql::server

  apt::ppa { "ppa:webupd8team/java": }

  $jira_home = "/vagrant/jira-home"
  $jira_version = "6.0"

  # It's OK to install unsigned packages
  file { "/etc/apt/apt.conf.d/99auth":
    owner => root,
    group => root,
    content => "APT::Get::AllowUnauthenticated yes;",
    mode => 644;
  }

  file { "sites-available.default":
    path => "/etc/apache2/sites-available/default",
    content => template('jira/jira.sites-available.default'),
    require => Package["apache2"],
  }

  exec { 'apt-get update':
    command => '/usr/bin/apt-get update',
    before => Apt::Ppa["ppa:webupd8team/java"],
  }

  exec { 'apt-get update 2':
    command => '/usr/bin/apt-get update',
    require => Apt::Ppa["ppa:webupd8team/java"],
  }

  package { ["vim",
             "curl",
             "bash",
             "apache2"]:
    ensure => present,
    require => Exec["apt-get update"],
    before => Apt::Ppa["ppa:webupd8team/java"],
  }

  postgresql::db { 'jira':
    user     => 'jira',
    password => 'jira',
    require  => Exec['create_jira_home'],
  }

  package { ["oracle-java7-installer"]:
    ensure => present,
    require => Exec["apt-get update 2"],
  }

  exec { "/usr/sbin/a2enmod proxy":
    unless => "/bin/readlink -e /etc/apache2/mods-enabled/proxy.load",
    notify => Exec["reload-apache2"],
    require => File["sites-available.default"],
  }

  exec { "/usr/sbin/a2enmod proxy_http":
    unless => "/bin/readlink -e /etc/apache2/mods-enabled/proxy_http.load",
    notify => Exec["reload-apache2"],
    require => File["sites-available.default"],
  }

  exec {
    "accept_license":
    command => "echo debconf shared/accepted-oracle-license-v1-1 select true | sudo debconf-set-selections && echo debconf shared/accepted-oracle-license-v1-1 seen true | sudo debconf-set-selections",
    cwd => "/home/vagrant",
    user => "vagrant",
    path    => "/usr/bin/:/bin/",
    require => Package["curl"],
    before => Package["oracle-java7-installer"],
    logoutput => true,
  }

  exec {
    "download_jira":
    command => "curl -L http://www.atlassian.com/software/jira/downloads/binary/atlassian-jira-${jira_version}.tar.gz | tar zx",
    cwd => "/vagrant",
    user => "vagrant",
    path    => "/usr/bin/:/bin/",
    require => Exec["accept_license"],
    logoutput => true,
    creates => "/vagrant/atlassian-jira-${jira_version}-standalone",
  }

  exec {
    "create_jira_home":
    command => "mkdir -p ${jira_home}",
    cwd => "/vagrant",
    user => "vagrant",
    path    => "/usr/bin/:/bin/",
    require => Exec["download_jira"],
    logoutput => true,
    creates => "${jira_home}",
  }

  exec {
    "start_jira_in_background":
    environment => "JIRA_HOME=${jira_home}",
    command => "/vagrant/atlassian-jira-${jira_version}-standalone/bin/start-jira.sh &",
    cwd => "/vagrant",
    user => "vagrant",
    path    => "/usr/bin/:/bin/",
    require => [ Package["oracle-java7-installer"],
                 Exec["accept_license"],
                 Exec["download_jira"],
                 Exec["create_jira_home"] ],
    logoutput => true,
  }

  append_if_no_such_line { motd:
    file => "/etc/motd",
    line => "Run JIRA with: JIRA_HOME=${jira_home} /vagrant/atlassian-jira-${jira_version}-standalone/bin/start-jira.sh",
    require => Exec["start_jira_in_background"],
  }

   # Notify this when apache needs a reload. This is only needed when
   # sites are added or removed, since a full restart then would be
   # a waste of time. When the module-config changes, a force-reload is
   # needed.
   exec { "reload-apache2":
      command => "/etc/init.d/apache2 reload",
      refreshonly => true,
   }

   exec { "force-reload-apache2":
      command => "/etc/init.d/apache2 force-reload",
      refreshonly => true,
   }

   # We want to make sure that Apache2 is running.
   service { "apache2":
      ensure => running,
      hasstatus => true,
      hasrestart => true,
      require => Package["apache2"],
   }
}

include must-have
