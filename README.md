jira-vagrant-install
===================

A project that uses Vagrant and Puppet to download and install a copy of JIRA 5.2.10.  Closely based off of Nicola Paolucci's Stash provisioning example https://bitbucket.org/durdn/stash-vagrant-install.git

Check out https://blogs.atlassian.com/2013/03/instant-java-provisioning-with-vagrant-and-puppet-stash-one-click-install/ for more details

===================

Begin original README, created by Nicola Paolucci https://blogs.atlassian.com/author/npaolucci/

# Instant Java provisioning with Vagrant and Puppet: Stash one click install

Being an *efficiency and productivity* freak I always try to streamline and automate repetitive tasks. As such, my antennas went up immediately when I started hearing about [Provisioning frameworks][13]; I began to incorporate them more and more in my development workflow. A perfect opportunity to take advantage of this came up while ramping up as Developer Advocate here at [Atlassian][14].

Have you heard of [Vagrant][1] yet? It is awesome. Why? It automates much of the boilerplate we as developers have to endure while setting up our platforms and toolkits. So what does Vagrant do? In their words, it allows you to *Create and configure lightweight, reproducible, and portable development
environments*.

So what better testbed for this tool than the shiny new [Stash 2.2 release][2]?

## Objective: provide me and fellow developers a (almost) one-click install for Stash

Alright I say *almost* because you need just a few dependencies if you want to use a configuration/provisioning framework, specifically a recent version of [VirtualBox][3], [Vagrant][1] and of course [git][5].

First try out this magic for yourself and then I'll walk you through some interesting details of the setup:

1. Install [VirtualBox][3] and [Vagrant][1] and make sure you have [git][5] available.

2. Open your favorite terminal and add a <span class="text codecolorer">base</span> virtual machine or provide your own:

        vagrant box add base http://files.vagrantup.com/precise32.box

3. Clone the [stash-vagrant-install][4] project by typing at your command line:


        git clone https://bitbucket.org/durdn/stash-vagrant-install.git
        
        cd stash-vagrant-install

4. Start up and provision automatically all dependencies in the vm:


        vagrant up

5. ??? There is not step 5. *** You're DONE! ***

***Note:*** be sure to let the process finish as it might take a while to download all the required packages.

After it finishes you will be able to access your brand new [Stash][8] installation with a browser at http://localhost:7990/setup

If you need to access the vm you can ssh into the box, you will find the stash installation in the <span class="text codecolorer">/vagrant</span> folder:


        vagrant ssh

        cd /vagrant

And if you need to start Stash manually you can just type:


        STASH_HOME=/vagrant/stash-home /vagrant/atlassian-stash-2.2.0/bin/start-stash.sh

## Under the hood

Now let me explain how all this works in some detail. Under the hood I used an absolutely basic Vagrant setup and a single [Puppet][6] manifest. Here is the <span class="text codecolorer">Vagrantfile</span>:

    Vagrant::Config.run do |config|
      config.vm.box = "base"
      config.vm.forward_port 7990, 7990
      config.vm.provision :puppet, :module_path => "modules" do |puppet|
        puppet.manifests_path = "manifests"
        puppet.manifest_file  = "default.pp"
      end
    end

As you can see it only specifies the port forwarding for where Stash will run (port 7990) and [Puppet][6] as provisioning system. Nothing more.

## Java Installation Blues

The only major requirement (and the complication) of this setup comes from the task of installing [Java 7][9] and automatically accept the [Oracle][10] license terms. Java is not included in Ubuntu repositories for various licensing reasons therefore we have to cater for it.

First we need to instruct Puppet about [apt][11]; we do this by requiring the library:

    include apt

This allows us to interact with Ubuntu packages in a more advanced fashion. Then we need to add a repository to the [apt][11] sources, one that includes the Java installer:

    apt::ppa { "ppa:webupd8team/java": }

From there, update the [apt][11] infrastructure in two steps, first without the extra [ppa][12] repository and then with it:

    exec { 'apt-get update':
      command => '/usr/bin/apt-get update',
      before => Apt::Ppa["ppa:webupd8team/java"],
    }

    exec { 'apt-get update 2':
      command => '/usr/bin/apt-get update',
      require => [ Apt::Ppa["ppa:webupd8team/java"], Package["git-core"] ],
    }

After this we automatically accept the Java license:

    exec {
      "accept_license":
      command => "echo debconf shared/accepted-oracle-license-v1-1 select true | sudo debconf-set-selections && echo debconf shared/accepted-oracle-license-v1-1 seen true | sudo debconf-set-selections",
      cwd => "/home/vagrant",
      user => "vagrant",
      path    => "/usr/bin/:/bin/",
      before => Package["oracle-java7-installer"],
      logoutput => true,
    }

## Downloading and Running Stash

The rest is about downloading the Stash installation file:

    exec {
      "download_stash":
      command => "curl -L http://www.atlassian.com/software/stash/downloads/binary/atlassian-stash-2.2.0.tar.gz | tar zx",
      cwd => "/vagrant",
      user => "vagrant",
      path    => "/usr/bin/:/bin/",
      require => Exec["accept_license"],
      logoutput => true,
      creates => "/vagrant/atlassian-stash-2.2.0",
    }

Creating its home folder:

    exec {
      "create_stash_home":
      command => "mkdir -p /vagrant/stash-home",
      cwd => "/vagrant",
      user => "vagrant",
      path    => "/usr/bin/:/bin/",
      require => Exec["download_stash"],
      logoutput => true,
      creates => "/vagrant/stash-home",
    }

And kicking it off in the background:

    exec {
      "start_stash_in_background":
      environment => "STASH_HOME=/vagrant/stash-home",
      command => "/vagrant/atlassian-stash-2.2.0/bin/start-stash.sh &",
      cwd => "/vagrant",
      user => "vagrant",
      path    => "/usr/bin/:/bin/",
      require => [ Package["oracle-java7-installer"],
                  Exec["accept_license"],
                  Exec["download_stash"],
                  Exec["create_stash_home"] ],
      logoutput => true,
    }

Now we have a system that has all the required packages ready for Stash to run and that actually kicks it off in the background for you. Pretty awesome!

If you are interested in learning more check out the [Puppet manifest][7] to see all the magic in context. 

## Conclusions

In conclusion: [Vagrant][1] and [Puppet][6] rock and can help any coder or system administrator to assemble development boxes easily. This is great when evaluating solutions or when providing complete setups with all the required dependencies. Oh and don't forget to try [Stash 2.2][2] out!

[1]: http://www.vagrantup.com
[2]: http://www.atlassian.com/en/software/stash/whats-new/stash-22
[3]: https://www.virtualbox.org
[4]: https://bitbucket.org/durdn/stash-vagrant-install
[5]: http://git-scm.com
[6]: https://puppetlabs.com/puppet/what-is-puppet/
[7]: https://bitbucket.org/durdn/stash-vagrant-install/src/cc56cd22d175eba153c01d765c7943827004f987/manifests/default.pp?at=master
[8]: http://www.atlassian.com/software/stash/overview
[9]: http://jdk7.java.net
[10]: http://oracle.com
[11]: http://wiki.debian.org/Apt
[12]: http://www.makeuseof.com/tag/ubuntu-ppa-technology-explained/
[13]: http://en.wikipedia.org/wiki/Comparison_of_open_source_configuration_management_software 
[14]: http://www.atlassian.com
