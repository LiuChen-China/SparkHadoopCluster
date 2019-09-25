#继承基础镜像
FROM ubuntu:16.04
#工作路径
WORKDIR /srv
#更改apt源
COPY ./Static/sources.list /etc/apt/sources.list
#####更新源，注意在容器中并没有创建hadoop等用户管理
RUN apt-get update &&\
    #一些必要的软件工具
    apt-get install -y wget openssh-server python3 python3-pip &&\
    #安装pyspark中缺失的模块
    pip3 install py4j &&\
    #换时区
    apt install -y tzdata && rm /etc/localtime &&\
    ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime &&\
    #安装JDK
    apt install -y default-jdk &&\
    #安装hadoop2.9.2
    wget http://mirror.bit.edu.cn/apache/hadoop/common/hadoop-2.9.2/hadoop-2.9.2.tar.gz &&\
    tar -zxvf hadoop-2.9.2.tar.gz -C /srv &&\
    mv hadoop-2.9.2 hadoop &&\
    rm -rf hadoop-2.9.2.tar.gz &&\
    #配置root密码
    echo "root:123456" | chpasswd &&\
    #配置ssh第一次连接不需要敲yes
    sed -i '$a StrictHostKeyChecking no' /etc/ssh/ssh_config &&\
    #配置ssh允许root登录
    sed -i 's/^PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config &&\
    #配合hadoop配置ssh连接自己免密码
    ssh-keygen -f ~/.ssh/id_rsa -N '' &&\
    touch ~/.ssh/authorized_keys &&\
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys &&\
    #手动配置hadoop的JAVA_HOME(这是个BUG...)
    sed -i "s?JAVA_HOME=\${JAVA_HOME}?JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-i386?g" hadoop/etc/hadoop/hadoop-env.sh &&\
    #安装spark2.4.4
    wget http://mirror.bit.edu.cn/apache/spark/spark-2.4.4/spark-2.4.4-bin-without-hadoop.tgz &&\ 
    tar -zxf spark-2.4.4-bin-without-hadoop.tgz &&\
    mv spark-2.4.4-bin-without-hadoop spark &&\
    rm spark-2.4.4-bin-without-hadoop.tgz &&\
    #配置spark连接hadoop的hdfs系统
    cp spark/conf/spark-env.sh.template spark/conf/spark-env.sh &&\
    sed -i '$a export SPARK_DIST_CLASSPATH=$(/srv/hadoop/bin/hadoop classpath)' spark/conf/spark-env.sh &&\
    sed -i '$a export HADOOP_CONF_DIR=/srv/hadoop/etc/hadoop' spark/conf/spark-env.sh &&\
    sed -i '$a export SPARK_MASTER_IP=172.17.0.2' spark/conf/spark-env.sh 
#hadoop配置文件
COPY ./Static/slaves hadoop/etc/hadoop/slaves
COPY ./Static/core-site.xml hadoop/etc/hadoop/core-site.xml
COPY ./Static/hdfs-site.xml hadoop/etc/hadoop/hdfs-site.xml
COPY ./Static/mapred-site.xml hadoop/etc/hadoop/mapred-site.xml
COPY ./Static/yarn-site.xml hadoop/etc/hadoop/yarn-site.xml
#spark配置文件
COPY ./Static/slaves spark/conf/slaves
#环境变量
ENV LANG C.UTF-8
ENV JAVA_HOME /usr/lib/jvm/default-java
ENV JRE_HOME ${JAVA_HOME}/jre
ENV CLASSPATH .:${JAVA_HOME}/lib:${JRE_HOME}/lib
ENV PATH ${JAVA_HOME}/bin:$PATH
ENV HADOOP_HOME /srv/hadoop
ENV SPARK_HOME /srv/spark
ENV PYTHONPATH $SPARK_HOME/python:$SPARK_HOME/python/lib/py4j-0.10.4-src.zip:$PYTHONPATH
ENV PYSPARK_PYTHON python3
ENV PATH $HADOOP_HOME/bin:$SPARK_HOME/bin:$PATH
#测试英文诗歌文件，python脚本转移
COPY ./Static/Test.py Test.py
####hadoop节点目录格式化
RUN hdfs namenode -format
#开启ssh服务 && 开启 NameNode 和 DataNode 守护进程
CMD sh -c '/etc/init.d/ssh start && while true;do echo hello docker;sleep 1;done'

    