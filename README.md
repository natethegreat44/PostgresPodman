# Introduction

This is a simple, quick way to get a postgres database up and running in a container.

To get started quickly:

1. copy `credentials.mk.template` to `credentials.mk` and then customize to your liking
1. next, just run `make dbstart` to fire things up. In a few seconds, you should have a live Postgres database
1. when you're all done, `make dbclean` can be used to clean things up

# Notes

We're using [rootless podman](https://github.com/containers/podman/blob/main/docs/tutorials/rootless_tutorial.md) to run this container, you'll end up with files not owned by you in the `data/` directory. The best way to clean them up is with `make dbclean`.

# Troubleshooting

## Firewall on Redhat/others running with a more strict firewalld configuration

If you're trying to connect to the database from another machine and having trouble, it could be
that a firewall is blocking you. Redhat seems to keep things fairly locked down (a good thing in
my opinion), whereas [Fedora has things pretty open](https://src.fedoraproject.org/rpms/firewalld/blob/rawhide/f/FedoraWorkstation.xml), and debian doesn't use a firewall at all (!?).

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