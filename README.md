Description
============
Installs and configures Atlassian Crowd.

Usage
==============
After your initial install, please:
* Add the hostname to the local /etc/hosts file as an alias for 127.0.0.1
* Add the `node:crowd][:url]` to the local /etc/hosts file as an alias for 127.0.0.1

If you are installing from a backup, make sure to run chef-client after you are done.

Upgrading 
======================
* Shutdown the old version on the server
* Remove the following variable from the node: `node[:crowd][:install][:current]`
* Upgrade the following variable: `node[:crowd][:version]`
* Follow the Atlassian steps for upgrade from the screens


Attributes
=======================
`node[:crowd][:application][:url]` = URL used for applications to contact crowd (Make sure to escape the :)
`node[:crowd][:url]` = URL used users to contact crowd (Make sure to escape the :)
