Docker RosarioSIS
=================

A Dockerfile that installs the latest [RosarioSIS](https://www.rosariosis.org/). This file pulls from the default branch, but can be easily modified to pull from any other available branch or tagged release.

## Installation

Minimum requirements: [Docker](https://www.docker.com/) & Git working.

```bash
$ git clone https://github.com/francoisjacquet/docker-rosariosis.git
$ cd docker-rosariosis
$ docker build -t rosariosis .
```

## Usage

RosarioSIS uses a PostgreSQL database:

```bash
$ docker run --name rosariodb -d postgres:9.5 --restart=always
$ docker run -e "ROSARIOSIS_ADMIN_EMAIL=admin@example.com" -h `hostname -f` -d -p 80:80 --name rosariosis --link rosariodb:rosariodb rosariosis --restart=always
```

Port 80 will be exposed, so you can visit `localhost` to get started. The default username is `admin` and the default password is `admin`.

## SMTP

RosarioSIS will attempt to send mail via the host's port 25. In order for this to work you must set the hostname of the rosariosis container to that of `host` (or some other hostname that your can appear on a legal `FROM` line) and configure the host to accept SMTP from the container. For postfix this means adding the container IP addresses to `/etc/postfix/main.cf` as in:

```
mynetworks = 192.168.0.0/16 172.16.0.0/12 10.0.0.0/8 127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128
```

