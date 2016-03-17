# Docklia

Docklia is a Dockerized version of Ganglia based on CentOS 6. 

This program allows you to create server and client instances of Ganglia to deploy across a cluster.

Note: Edit the gmetad.conf and gmond.conf files in the confDir directory to reflect the ip or your server. Hostnames aren't working yet. (Need to figure that out)

Example usage:

```bash
cd <git clone dir>
docker build -t ganglia .
docker run -h archganglia -d -ti -v /path/to/Docklia/clone/dir/confDir/:/usr/local/etc/ -p 80:80 -p 6343:6343/udp -p 8649:8649/udp -p 8649:8649/tcp ganglia --zone Africa/Johannesburg --server
# OR
docker run -d -ti -v /path/to/Docklia/clone/dir/confDir/:/usr/local/etc/ --net=host ganglia --zone Africa/Johannesburg --server
```

The commands specify the following:
- -d:           daemon
- -ti:          interactive
- -v /path/...  binds the configuration directory from the host to the container
- -p 80:80...   publishes the ports that ganglia uses on the equivalent ports on the host
- --zone        Allows you to set the timezone of the container (useful for Ganglia issues sometimes)
- --server      Runs the container instance as a Ganglia server.

You can also use the --client flag instead of server to deploy a gmond client on a node.
