jira-vagrant-install
===================

A project that uses Vagrant and Puppet to create and boot a VirtualBox VM and then download and install a copy of JIRA 6.0.  

## Notes

1. This is intended as a proof of concept and is not intended to be a full provisioning solution for JIRA.  You will need to manually supply your own JIRA license.  You can get a free trial license from Atlassian or purchase a 10 user license for $10.
2. JIRA can take *awhile* to startup and be accessible after installation.  Give it a few minutes to go through initial startup.
2. A PostgreSQL server is installed by default but you're not required to use it.  You can choose to use the "Evaluation Installation" database setting as well.
4. If you want to use the installed PostgreSQL server, you should provide the following information in JIRA setup:
	1. Database Type: PostgreSQL
	2. Hostname: localhost
	2. Port: 5432
	3. Database: jira
	4. Username: jira
	5. Password: jira
	6. Schema: public
6. An Apache revers proxy is used to map port 8080 to 80.  This occassionally will fail the first time you access JIRA after getting the VM up and running.  No fear, just reload the page.
5. 2. Credit where credit is due: This project is very closely based off of Nicola Paolucci's Stash provisioning example https://bitbucket.org/durdn/stash-vagrant-install.git. Check out https://blogs.atlassian.com/2013/03/instant-java-provisioning-with-vagrant-and-puppet-stash-one-click-install/ for more details 
	

## Dependencies

1. [Vagrant](http://downloads.vagrantup.com/)
2. [VirtualBox](https://www.virtualbox.org/wiki/Downloads)

## Usage

	$ git clone https://github.com/lwndev/jira-vagrant-install.git && cd jira-vagrant-install
	$ vagrant up

Once JIRA is up and running you can access it at http://192.168.33.10
