jira-vagrant-install
===================

A project that uses Vagrant and Puppet to create and boot a VirtualBox VM and then download and install a copy of JIRA 6.0.  

## Notes

1. This is intended as a proof of concept and is not intended to be a full provisioning solution for JIRA.  You will need to manually supply your own JIRA license and use the "Evaluation Installation" option as the Puppet manifest does not install or configure a database.
2. Credit where credit is due: This project is very closely based off of Nicola Paolucci's Stash provisioning example https://bitbucket.org/durdn/stash-vagrant-install.git. Check out https://blogs.atlassian.com/2013/03/instant-java-provisioning-with-vagrant-and-puppet-stash-one-click-install/ for more details

# Dependencies

1. [Vagrant](http://downloads.vagrantup.com/)
2. [VirtualBox](https://www.virtualbox.org/wiki/Downloads)

# Usage

	$ git clone https://github.com/lwndev/jira-vagrant-install.git && cd jira-vagrant-install
	$ vagrant up

Once JIRA is up and running you can access it at http://localhost:8080 or http://192.168.33.11
