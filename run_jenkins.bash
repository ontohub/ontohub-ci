#!/bin/bash

function terminate_jobs_and_services() {
  for proc in `jobs -p`
  do
    kill -s SIGTERM $proc
  done

  sudo service elasticsearch stop
  sudo service redis-server stop
  sudo service postgresql stop
}

function start_services() {
  sudo service postgresql start
  sudo service redis-server start
  sudo service elasticsearch start

  # run jenkins
  java -jar /opt/jenkins.war &
}


# load rbenv
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"

start_services

trap terminate_jobs_and_services TERM
wait
