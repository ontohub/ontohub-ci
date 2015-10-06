FROM ubuntu:14.04
MAINTAINER Eugen Kuksa "eugenk@cs.uni-bremen.de"

# Change this in order to force rebuilding with updated packages.
ENV REFRESHED_AT 2015-10-05

RUN dpkg --add-architecture i386
RUN apt-get update && apt-get clean
RUN apt-get install -y software-properties-common sudo wget ssh

# software installation
RUN wget -qO - http://pkg.jenkins-ci.org/debian/jenkins-ci.org.key | sudo apt-key add -
RUN sh -c 'echo deb http://pkg.jenkins-ci.org/debian binary/ > /etc/apt/sources.list.d/jenkins.list'

RUN wget -qO - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
RUN sh -c 'echo deb http://apt.postgresql.org/pub/repos/apt/ precise-pgdg main > /etc/apt/sources.list.d/pgdg.list'

RUN wget -qO - https://packages.elasticsearch.org/GPG-KEY-elasticsearch | sudo apt-key add -
RUN add-apt-repository "deb http://packages.elasticsearch.org/elasticsearch/1.4/debian stable main"

RUN apt-add-repository ppa:chris-lea/redis-server
RUN apt-add-repository ppa:hets/hets
RUN apt-add-repository -s "deb http://ppa.launchpad.net/hets/hets/ubuntu trusty main"
RUN apt-add-repository -y "deb http://archive.canonical.com/ubuntu precise partner"
RUN apt-add-repository -y "deb http://archive.ubuntu.com/ubuntu precise-updates main restricted universe multiverse"

RUN apt-get update
RUN apt-get install -y xvfb openjdk-7-jre-headless cmake g++ pkg-config libqt4-dev libqtwebkit-dev libsane libgphoto2-l10n libpq-dev libreadline-dev
RUN apt-get install -y git subversion git-svn nodejs postgresql-9.4 redis-server elasticsearch
RUN apt-get install -y udrawgraph hets-core phantomjs libxml2-dev
RUN apt-get clean

# hets update
RUN hets -update
RUN cd /lib/x86_64-linux-gnu/
RUN ln -s libpng12.so.0 libpng14.so.14

# postgres setup
ADD setup_postgres.bash /tmp/
RUN bash /tmp/setup_postgres.bash
RUN rm /tmp/setup_postgres.bash

# elasticsearch setup
RUN mkdir /usr/share/elasticsearch/config/
ADD elasticsearch.yml /usr/share/elasticsearch/config/

# user setup
ADD setup_user_jenkins.bash /tmp/
RUN bash /tmp/setup_user_jenkins.bash
RUN rm /tmp/setup_user_jenkins.bash

USER jenkins
ENV HOME /home/jenkins

# elasticsearch configuration
ENV ES_HOME /usr/share/elasticsearch
ENV ES_USER jenkins
ENV ES_GROUP jenkins
ENV ES_CONF_FILE /usr/share/elasticsearch/config/elasticsearch.yml
ENV MAX_MAP_COUNT 262144

# rbenv setup
ADD setup_rbenv.bash /tmp/
RUN sudo chmod 755 /tmp/setup_rbenv.bash
RUN sudo su - jenkins /tmp/setup_rbenv.bash
RUN sudo rm /tmp/setup_rbenv.bash

RUN sudo locale-gen en_US.UTF-8
RUN sudo dpkg-reconfigure locales

# add entrypoint script
ADD run_jenkins.bash /home/jenkins/
RUN sudo chown jenkins:jenkins /home/jenkins/run_jenkins.bash
RUN sudo chmod 755 /home/jenkins/run_jenkins.bash

ENV JENKINS_HOME /data/jenkins
ENV PATH $ES_HOME/bin:$PATH

VOLUME /home/jenkins
VOLUME /data
RUN sudo chown -R jenkins:jenkins /data

EXPOSE 8080

ENTRYPOINT /bin/bash /home/jenkins/run_jenkins.bash
CMD [""]

ENV JENKINS_REFRESHED_AT="2015-10-06"

# jenkins installation/update
RUN sudo rm -f /opt/jenkins.war   # remove jenkins if it already exists
RUN sudo wget http://mirrors.jenkins-ci.org/war/latest/jenkins.war -O /opt/jenkins.war
RUN sudo chmod 644 /opt/jenkins.war
RUN sudo chown jenkins:jenkins /opt/jenkins.war
