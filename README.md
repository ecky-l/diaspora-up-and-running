# diaspora-up-and-running

Ansible roles and playbooks to install a diaspora* social network pod on CentOS

This project contains [ansible](https://www.ansible.com/) playbooks and roles to install the [diaspora* ](https://diasporafoundation.org/) social network on your own server, running CentOS. The installation is done in a [docker](https://www.docker.com/) image, with [apache httpd](https://httpd.apache.org/) as proxy frontend and the [postgresql](https://www.postgresql.org/) database as backend.

When you run the playbook, a series of steps are performed:

- Some basic packages are installed, including epel and python dependencies for the host (role base_setup)
- The docker-ce repository is configured and enabled, and docker-ce is installed (refere to [here](https://docs.docker.com/install/linux/docker-ce/centos/) for the details), if not already done
- The postgresql database is installed and initialized, if it is not already present
- A docker image for building diaspora* releases is built, called _diaspora-build_. It contains the build dependencies, gcc, make etc. necessary to compile ruby and dependencies.
- A container from the previously built _diaspora-build_ image is used to fetch and build a tarball of a particular diaspora* release from git. The version, or git commit, or branch can be defined as variable.
- This tarball is used to build the actual diaspora* docker image, tagged with the version (or git tag, or commit or branch)
- Two docker volumes are created and prepared for the _public/uploads_ directory and the _log_ directory. They are used to run the container.
- The httpd is installed and prepared as proxy frontend for the diaspora container.
- Optionally, a mail server is set up with exim and dovecot, and it can be used to send mail from the diaspora pod.
- Finally, a docker container is created from the newly created image and run in daemon mode with port 3000 exposed to localhost.

On the way there, the firewall is modified and necessary firewall rules are applied.

## Usage

The playbook is best targeted to a CentOS machine, although Other RHEL based linuxes, such as Fedora or RHEL/OEL might work too (with minor tweaks). The client machine where the playbook is run doesn't have to be CentOS - every unix like OS or even windows with cygwin will work, as long as it has ansible installed. For instance I use macOS as my workstation OS and have a CentOS virtual machine in [VirtualBox](https://www.virtualbox.org/) as well as CentOS on all my servers. A debian or otherwise based linux is possible, but the tweaks are probably more exhausting.

Ansible must be installed on your workstation. Please refer to the official documentation for your platform... on CentOS it is in the EPEL repository, on macOS its in the [MacPorts](https://www.macports.org/).
Furthermore you need passwordless ssh access to the machine where you plan to install. The best way there is to use a ssh key without password (can be generated with `ssh-keygen ...` and installed on the target machine with `ssh-copy-id`). That's all the requirements. Then,

1. Review the variables in _group_vars/all.yaml_ and edit them to your needs. You can also overwrite variables in the inventory group files
2. Enter your server IPs or hostnames in the _servers.inventory_ file in the respective groups. It is possible and advisable to enter local testing, staging and productive hosts
3. Review the diaspora.yaml playbook to disable/enable the mail role, if you (don't) need it. It is optional and not necessary if your mail server is already installed.
4. **Before first installation**: if you have a database with diaspora already, create a dump of it: `pg_dump -d diaspora_production -Ft -f diaspora_production.dump` and put that in place of _roles/diaspora/files/diaspora\_production.dump_. If you don't have a database, the current file at this place creates an empty database.
5. **Before first installation**: As of now, ansible's _docker\_volume_ module has a bug which causes it to run into an exception, if no docker volumes are currently present on the host. To prevent this, log in to your host manually and create a dummy volume: `docker volume create dummy`. This is only necessary if you don't have any docker volumes yet on that host.  
6. Run `ansible-playbook diaspora.yaml -i servers.inventory`
7. Wait until the playbook run is complete
8. **After first installation**: If you had a running pod already, copy the content from public/uploads/* of your old instance to /var/lib/docker/volumes/diaspora-uploads/\_data. (alternatively make the new container use your old uploads/ directory as mounted volume to /var/local/diaspora/diaspora/public/uploads)

When everything was successful, a docker container with the name _diasproa-&lt;version&gt;_ is up and running on your host. The manual steps above must only be done the first time. For subsequent updates of the diaspora* codebase, the playbook can be run without manual intervention... that is when it pays off.

## What is not covered / prerequisites on your server

The playbook doesn't care about your DNS entries and httpd certificates. This must be done apart from the installation. You must own the domain that is set as diaspora\_hostname in _group\_vars/all.yaml_ and you must ensure that the domain points to your server via DNS entry from outside (for local testing it might be enough to set it in /etc/hosts on your client machine). If the mail role is executed, a MX record must exist in the DNS and a PTR record from your IPs to your mail server domain.

Communication with your new pod works https encrypted, and you need certificates. [Letsencrypt](https://letsencrypt.org/) provides class1 certificates for free and they can be acquired with the certbot tool. To get certificates from letsencrypt, the mentioned DNS entries must exist, then you can call `certbot run --apache -d <your.pod.domain>` to get them and install them automatically to the host configuration. Since the state of your DNS entries and certificates is special and not known to me, it is hard to automate this step.

What is also not yet included here is a role for XMPP chat setup. The current configuration is suited for a separate installation of [prosody](http://prosody.im/) as XMPP server using diaspora authentication plugins, described [here](https://wiki.diasporafoundation.org/Integration/XMPP/Prosody). It is possible to install prosody directly on CentOS or as a docker image... and maybe a future version of this project will include a role to do this. The author currently struggles with the question whether it is sufficient to install it natively ot whether it is better to install it as docker image... 

## Why docker?

Using docker has several advantages here. First, the build process requires build tools and dependencies which you usually don't want to have installed on a production server - hence the installation of them in a docker image which is used to build the release. Then, by having a docker image for every diaspora release has the advantage that it is possible to switch back and forth, and last but not least to rollback to a previous image easily if something failes during the upgrade (as long as the database allows it). It also makes the upgrade process reproducible and automated, which is important since diaspora comes out with a new release every few months. One diaspora* image is ca. 1.18GB large as of now. Of course it is not necessary to keep every release - they can be easily rebuilt, anyway.

Finally the docker deployment would make it easy to get fancy and run several instances distributed with failover, in a kubernetes stack or similar. This would be interresting for large pods with huge load... although it is probably not the most common use case. 

## Disclaimer

There is *absolutely no warranty* for any damage that you might do to your servers with this project. It is just there to help you get started and simplify the installation of a diaspora* pod, but beyond that it's not my responsibility. If you are unsure, please test the playbook first in a safe environment and do carefully study it and the roles before applying it to a production environment.
