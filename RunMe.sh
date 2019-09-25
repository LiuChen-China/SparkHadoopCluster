#!/bin/bash
#生成镜像
docker build -t spark_hadoop_cluster .
#主节点容器
docker run -d -h master --add-host master:172.17.0.2 --add-host slave1:172.17.0.3 --name=master spark_hadoop_cluster
#从节点容器
docker run -d -h slave1 --add-host master:172.17.0.2 --add-host slave1:172.17.0.3 --name=slave1 spark_hadoop_cluster
#主节点开启hadoop和spark服务
docker exec master /srv/hadoop/sbin/start-all.sh
docker exec master /srv/spark/sbin/start-all.sh