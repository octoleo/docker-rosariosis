docker-rosariosis
=================

A Dockerfile that installs the latest [RosarioSIS](http://www.rosariosis.org/). This file pulls from the master branch, but can be easily modified to pull from any other available branch or tagged release.

## Installation

```
git clone https://github.com/larryprice/docker-rosario.git
cd docker-rosario
docker build -t rosariosis .
```

## Usage

RosarioSIS uses a Postgres database:

``` bash
$ docker create --name rosariodb postgres:9.4
$ docker run -d --link rosariodb:rosariodb rosariosis
```

Port 80 will be exposed, so you can visit `localhost` to get started. The default username is `admin` and the default password is `admin`.
