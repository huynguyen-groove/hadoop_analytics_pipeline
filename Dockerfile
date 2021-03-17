FROM docker.io/ubuntu:16.04
USER root
RUN apt-get update && \
    apt-get -y upgrade && \
    apt install -y gcc build-essential make cmake automake autoconf libtool zlib1g-dev maven procps ssh git-core language-pack-en libmysqlclient-dev libssl-dev \
    python python-pip python-virtualenv python2.7-dev libpq-dev vim sudo wget \
    apt-transport-https ntp acl iotop lynx logrotate rsyslog unzip 

RUN /usr/sbin/update-ca-certificates
RUN mkdir -p /edx/var/log && \
    mkdir -p /edx/app && \
    mkdir -p /edx/bin && \
    mkdir -p /edx/etc && \
    mkdir -p /etc/logrotate.d/hourly && \
    # mkdir -p /etc/rsyslog.d/50-default.conf && \
    mkdir -p /etc/cron.hourly && chmod -R 777 /etc/cron.hourly
ADD ./files/ssh_key_forward /etc/sudoers.d/ssh_key_forward
ADD ./templates_common/edx_rsyslog /etc/rsyslog.d/99-edx.conf
ADD ./templates_common/etc/logrotate.d/hourly/edx_logrotate /etc/logrotate.d/hourly/edx-services
ADD ./templates_common/etc/cron.hourly/logrotate /etc/cron.hourly/logrotate
ADD ./templates_common/etc/logrotate.d/hourly/edx_logrotate_tracking_log /etc/logrotate.d/hourly/tracking.log

RUN pip install setuptools==39.0.1 pip==9.0.3 virtualenv==15.2.0 virtualenvwrapper==4.8.2 -i https://pypi.python.org/simple
RUN service rsyslog restart

ADD ./templates_common/log-ntp-alerts.sh /edx/bin/og-ntp-alerts.sh
ADD ./templates_common/etc/logrotate.d/ntp /etc/logrotate.d/ntp

ENV HADOOP_COMMON_USER_HOME /edx/app/hadoop
ENV HADOOP_COMMON_HOME $HADOOP_COMMON_USER_HOME/hadoop
ENV HADOOP_COMMON_CONF_DIR $HADOOP_COMMON_HOME/etc/hadoop

RUN groupadd -f hadoop
RUN mkdir -p $HADOOP_COMMON_USER_HOME/.ssh
RUN mkdir -p ~/.ssh
RUN useradd -rs /bin/bash -d $HADOOP_COMMON_USER_HOME/ hadoop -g hadoop

RUN chmod -R 777 $HADOOP_COMMON_USER_HOME

RUN ssh-keygen -t rsa -P '' -f $HADOOP_COMMON_USER_HOME/.ssh/id_rsa && \
  cat $HADOOP_COMMON_USER_HOME/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys && \
  chmod -R 777 ~/.ssh/authorized_keys
ADD ./configs/ssh_config $HADOOP_COMMON_USER_HOME/.ssh/config
RUN chmod -R 777 $HADOOP_COMMON_USER_HOME/.ssh/config

RUN wget https://archive.apache.org/dist/hadoop/common/hadoop-2.7.2/hadoop-2.7.2.tar.gz && tar -xzf hadoop-2.7.2.tar.gz && \
    mv hadoop-2.7.2 $HADOOP_COMMON_USER_HOME && chmod -R 777 $HADOOP_COMMON_USER_HOME/hadoop-2.7.2

RUN ln -s $HADOOP_COMMON_USER_HOME/hadoop-2.7.2 --directory $HADOOP_COMMON_HOME
RUN echo "$HADOOP_COMMON_CONF_DIR"
ADD ./templates_hadoop/hadoop-env.sh $HADOOP_COMMON_CONF_DIR/hadoop-env.sh
ADD ./templates_hadoop/mapred-site.xml $HADOOP_COMMON_CONF_DIR/mapred-site.xml
ADD ./templates_hadoop/core-site.xml $HADOOP_COMMON_CONF_DIR/core-site.xml
ADD ./templates_hadoop/hdfs-site.xml $HADOOP_COMMON_CONF_DIR/hdfs-site.xml
ADD ./templates_hadoop/yarn-site.xml $HADOOP_COMMON_CONF_DIR/yarn-site.xml
ADD ./templates_hadoop/etc/systemd/system/hdfs-datanode.service /etc/systemd/system/hdfs-datanode.service
ADD ./templates_hadoop/etc/systemd/system/hdfs-namenode.service /etc/systemd/system/hdfs-namenode.service
ADD ./templates_hadoop/etc/systemd/system/mapreduce-historyserver.service /etc/systemd/system/mapreduce-historyserver.service
ADD ./templates_hadoop/etc/systemd/system/yarn-nodemanager.service /etc/systemd/system/yarn-nodemanager.service
ADD ./templates_hadoop/etc/systemd/system/yarn-proxyserver.service /etc/systemd/system/yarn-proxyserver.service
ADD ./templates_hadoop/etc/systemd/system/yarn-resourcemanager.service /etc/systemd/system/yarn-resourcemanager.service

ADD ./files/hadoop_env $HADOOP_COMMON_HOME/hadoop_env
ADD ./files/bashrc $HADOOP_COMMON_USER_HOME/.bashrc

RUN wget https://github.com/google/protobuf/releases/download/v2.5.0/protobuf-2.5.0.tar.gz && tar -xzf protobuf-2.5.0.tar.gz
RUN cd protobuf-2.5.0 && ./configure --prefix=/usr/local && make && make install

RUN mkdir -p /usr/lib/jvm && chmod -R 777 /usr/lib/jvm
RUN wget http://download.oracle.com/otn-pub/java/jdk/8u131-b11/d54c1d3a095b4ff2b6607d096fa80163/jdk-8u131-linux-x64.tar.gz --header='Cookie:oraclelicense=accept-securebackup-cookie' -P /var/tmp && \
    tar -xzf /var/tmp/jdk-8u131-linux-x64.tar.gz -C /usr/lib/jvm
RUN ln -s /usr/lib/jvm/jdk1.8.0_131 /usr/lib/jvm/java-8-oracle

RUN update-alternatives --install /usr/bin/java java /usr/lib/jvm/jdk1.8.0_131/bin/java 20
RUN update-alternatives --install /usr/bin/javac javac /usr/lib/jvm/jdk1.8.0_131/bin/javac 20
RUN update-alternatives --install /usr/bin/javaws javaws /usr/lib/jvm/jdk1.8.0_131/bin/javaws 20
RUN update-alternatives --install /usr/bin/jarsigner jarsigner /usr/lib/jvm/jdk1.8.0_131/bin/jarsigner 20
ADD ./template_oraclejdk/java.sh /etc/profile.d/java.sh

ENV LD_LIBRARY_PATH /usr/local/lib
RUN wget https://archive.apache.org/dist/hadoop/common/hadoop-2.7.2/hadoop-2.7.2-src.tar.gz && tar -xzf hadoop-2.7.2-src.tar.gz
RUN cd hadoop-2.7.2-src/hadoop-common-project && mvn package -X -Pnative -DskipTests

RUN mv $HADOOP_COMMON_HOME/lib/native/libhadoop.a $HADOOP_COMMON_HOME/lib/native/libhadoop32.a && \
    mv $HADOOP_COMMON_HOME/lib/native/libhadoop.so $HADOOP_COMMON_HOME/lib/native/libhadoop32.so && \
    mv $HADOOP_COMMON_HOME/lib/native/libhadoop.so.1.0.0 $HADOOP_COMMON_HOME/lib/native/libhadoop32.so.1.0.0

RUN cd hadoop-2.7.2-src/hadoop-common-project/hadoop-common/target/native/target/usr/local/lib/ && \
    chown hadoop:hadoop libhadoop.a && cp libhadoop.a $HADOOP_COMMON_HOME/lib/native/libhadoop.a && \
    chown hadoop:hadoop libhadoop.so && cp libhadoop.a $HADOOP_COMMON_HOME/lib/native/libhadoop.so && \
    chown hadoop:hadoop libhadoop.so.1.0.0 && cp libhadoop.a $HADOOP_COMMON_HOME/lib/native/libhadoop.so.1.0.0

RUN touch $HADOOP_COMMON_USER_HOME/.native_libs_built && chmod -R 777 $HADOOP_COMMON_USER_HOME/.native_libs_built && \
    mkdir -p $HADOOP_COMMON_USER_HOME/services.d && chmod -R 777 $HADOOP_COMMON_USER_HOME/services.d
