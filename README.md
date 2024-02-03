# Introduction

This is a simple, quick way to get a [PostgreSQL](https://postgresql.org) database up and running in a container.

To get started quickly:

1. copy `credentials.template` to `credentials` and then customize to your liking.
1. next, just run `./cpg run` to fire things up. In a few seconds, you should have a live Postgres database. Use `./cpg runbg` if you want the database running in the background.
1. when you're all done, `./cpg clean` can be used to clean things up

# Notes

1. We're using [rootless podman](https://github.com/containers/podman/blob/main/docs/tutorials/rootless_tutorial.md) to run this container, you'll end up with files not owned by you in the `data/` and `shared/` directory. The best way to clean them up is with `./cpg clean`.
1. If you need to share files between your local machine and the container, copy them into the `shared/` directory. Note that `shared/` is currently considered as transient and WILL BE DELETED if you run `./cpg clean`.
1. The scripts in the `init` directory are run in order when the container is created. The first one creates the database and user. More scripts can be added as needed.
1. [PGVector](https://github.com/pgvector/pgvector) is also supported! Just set the `DBTYPE` environment variable to `pgvector` before running. For example, `DBTYPE=pgvector ./cpg run` 

# Troubleshooting

## Firewall on Redhat/others running with a more strict firewalld configuration

If you're trying to connect to the database from another machine and having trouble, it could be
that a firewall is blocking you. Redhat seems to keep things fairly locked down (a good thing in
my opinion), whereas [Fedora has things pretty open](https://src.fedoraproject.org/rpms/firewalld/blob/rawhide/f/FedoraWorkstation.xml), and default debian [doesn't seem to use a firewall at all](https://www.debian.org/doc/manuals/securing-debian-manual/firewall-setup.en.html) (yikes!).

To see if the firewall is blocking you, running `firewall-cmd --list-all` will show the rules. On
a clean, minimal installation of [Alma Linux 9.3](https://almalinux.org), for example:

```sh
alma9 ➜  ~ sudo firewall-cmd --list-all
public (active)
  target: default
  icmp-block-inversion: no
  interfaces: enp1s0
  sources:
  services: cockpit dhcpv6-client ssh
  ports:
  protocols:
  forward: yes
  masquerade: no
  forward-ports:
  source-ports:
  icmp-blocks:
  rich rules:
```

As you can see, the Postgres port `5432/tcp` is not open, nor are any other ports. To open the port, you can take the quick and dirty
approach with:

```sh
# firewall-cmd --zone=public --add-port=5432/tcp --permanent
success
# firewall-cmd --reload
success 
```

or you can be a little more proper and descriptive by adding an entry to `/etc/firewalld/zones/public.xml` (or whichever zone you're in):

```
<service name=”postgresql” />
```

After reloading the firewall rules with `firewall-cmd --reload`, you should now be able to see `postgresql` in the services:

```sh
alma9 ➜  ~ sudo firewall-cmd --list-all
public (active)
  target: default
  icmp-block-inversion: no
  interfaces: enp1s0
  sources:
  services: cockpit dhcpv6-client postgresql ssh
  ports:
  protocols:
  forward: yes
  masquerade: no
  forward-ports:
  source-ports:
  icmp-blocks:
  rich rules:
```

This means that the file `/usr/lib/firewalld/services/postgresql.xml` has been loaded, which opens the `5432/tcp` port:

```xml
<?xml version="1.0" encoding="utf-8"?>
<service>
  <short>PostgreSQL</short>
  <description>PostgreSQL Database Server</description>
  <port protocol="tcp" port="5432"/>
</service>
```

For more information, see [the documentation](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/configuring_and_managing_networking/using-and-configuring-firewalld_configuring-and-managing-networking).
