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

On the way there, the firewall rules are applied, which are necessary to bring everything together.

## Usage

The playbook is best targeted to a CentOS machine (although other RHEL based linuxes, such as Fedora or RHEL/OEL might work with minor tweaks). This does not mean that you must have CentOS installed on your workstation, instead every unix like OS or even windows with cygwin will work, as long as it is possible to use ansible there. I use macOS and a CentOS virtual machine in [VirtualBox](https://www.virtualbox.org/), for instance.
The server where you plan to run the image should also be CentOS or any RHEL based linux. A debian or otherwise based linux is possible, but the tweaks are more exhausting, I guess ;-).

You need to have ansible installed on your workstation, where you plan to use the playbooks. On CentOS it is in the EPEL repositories and can be installed by a simple `yum -y install ansible`. On macOS its in the [MacPorts](https://www.macports.org/). There are instructions for all major environments, this is beyond the scope of this project.
Once you have ansible, you need passwordless ssh access to the machine where you plan to install. The best way there is to use a ssh key without password (can be generated with `ssh-keygen ...` and installed on the target machine with `ssh-copy-id`, just in case you don't know that already). That's all the requirements. When you have that,

1. Look carefully over the variables in _group_vars/all.yaml_ and edit them to your needs. You can also overwrite variables in the inventory group files
2. Enter your server IPs or hostnames in the _servers.inventory_ file under the respective groups. It is possible to enter local testing, staging and productive hosts
3. Review the diaspora.yaml playbook to disable/enable the mail role, if you (don't) need it. It is optional and not necessary if you have already a mail server running.
4. Run the magic line `ansible-playbook diaspora.yaml -i servers.inventory`
5. Wait until the playbook run is complete

## Disclaimer

There is *absolutely no warranty* for any damage that you might do to your servers with this project. It is just there to help you get started and simplify the installation of a diaspora* pod, but beyond that it's not my responsibility. If you are unsure, please test the playbook first in a safe environment and do carefully study it and the roles before applying it to a production environment.
