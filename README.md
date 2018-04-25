# redis-cluster

Deploy a redis cluster in an existing VPC

## Deploying

In order to deploy the redis cluster you will need to provide some parameters of an existing VPC.

```
export REGION=us-east-1
export AZ=us-east-1a
export VPC=vpc-6e543f21
export SUBNET_ID=subnet-f1c45fgh
export STACK_NAME=redis-cluster
export SSH_KEY_NAME=jhernandez

# Import your ssh key if you haven't
aws ec2 --region $REGION import-key-pair --key-name $SSH_KEY_NAME --public-key-material "$(cat ~/.ssh/id_rsa.pub)"

aws cloudformation create-stack \
 --region $REGION \
 --stack-name $STACK_NAME \
 --template-url https://s3.amazonaws.com/jhernandez.me/redis-chef/redis-cluster.template \
 --parameters \
 ParameterKey=AvailabilityZone,ParameterValue=$AZ \
 ParameterKey=KeyName,ParameterValue=$SSH_KEY_NAME \
 ParameterKey=VPCID,ParameterValue=$VPC \
 ParameterKey=SubnetId,ParameterValue=$SUBNET_ID
```

## Architecture

For simplicity we use the `chef-solo` feature for this deployment so we don't need a chef server and instead all recipes are deliveried as a `chef-solo.tar.gz` package as part of the bootstraping phase.

This stack creates a master redis instance which is provisioned by a chef recipe that runs redis in a docker container.

Slave instances are part of an autoscaling group and each instance run both the redis slave and the redis sentinel in the same instance.

Sentinel needs a quorum of 2 instances to work.

### Recipes

* **redis::master** which runs a redis server
* **redis::save** which runs a redis slave mounting configs from /etc/redis/slave.conf
* **redis::sentinel** which runs a redis sentinel mounting configs from /etc/redis/sentinel.conf

## Verify the cluster

All the instances have public ip address to make it easier to test.

```bash
# ssh in to the master instance
ssh ubuntu@master-ip-address
# root
sudo su

# docker ps -a to check the container is running
docker ps -a
  CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS                    NAMES
  e0f6296a98c1        redis:latest        "docker-entrypoint.s…"   10 minutes ago      Up 10 minutes       0.0.0.0:6379->6379/tcp   redis-master

# log into the container
docker exec -it redis-master /bin/bash

# inside the container run redis-cli command
redis-cli info
  # Replication
  role:master
  connected_slaves:3
  slave0:ip=10.0.0.202,port=6379,state=online,offset=130226,lag=0
  slave1:ip=10.0.0.203,port=6379,state=online,offset=130365,lag=0
  slave2:ip=10.0.0.253,port=6379,state=online,offset=130365,lag=0

# check a sentinel server (do not exit from the container) by login into the private ip of a redis-slave instance
# which runs both the slave and the sentinel
redis-cli -h 10.0.0.203 -p 26379

# type the command
10.0.0.203:26379> sentinel master redis-master
  1) "name"
  2) "redis-master"
  3) "ip"
  4) "10.0.0.147"
  ....
```

## Failover

In order to test a fail of the master you can do the following

```bash
# ssh in to the master instance
ssh ubuntu@master-ip-address
# root
sudo su

# docker ps -a to check the container is running
docker ps -a
  CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS                    NAMES
  e0f6296a98c1        redis:latest        "docker-entrypoint.s…"   10 minutes ago      Up 10 minutes       0.0.0.0:6379->6379/tcp   redis-master

# stop the container
docker stop redis-master

# in another terminal log into a slave ec2 instance
ssh ubuntu@slave-public-ip

# root
sudo su

# check containers are running
docker ps -a
  CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS                                NAMES
  1bf1b56f1b95        redis:latest        "docker-entrypoint.s…"   18 minutes ago      Up 18 minutes       6379/tcp, 0.0.0.0:26379->26379/tcp   redis-sentinel
  5ed1103ad83b        redis:latest        "docker-entrypoint.s…"   18 minutes ago      Up 18 minutes       0.0.0.0:6379->6379/tcp               redis-slave

# log into the sentinel container
docker exec -it redis-sentinel /bin/bash

# run redis-cli
redis-cli -p 26379
# check sentinel
127.0.0.1:26379> sentinel master redis-master
 1) "name"
 2) "redis-master"
 3) "ip"
 4) "10.0.0.202"
 5) "port"
 6) "6379"
 7) "runid"
```

After that you will be able to confirm that the master switched to a different server
