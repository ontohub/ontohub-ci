#!/bin/bash

# This script prepares and actually runs the test suite in jenkins.
# It is not loaded anywhere, but pasted in the project configuration.

source ~/.bashrc
echo "# begin hets update"
sudo hets -update
echo "# end hets update"
echo "# begin bundler"
bundle install -j4
echo "# end bundler"
echo "# begin redis cleanup"
redis-cli flushdb
echo "# end redis cleanup"
echo "# begin migration"
RAILS_ENV=test bundle exec rake db:migrate:reset || true
echo "# end migration"
SPEC_OPTS="--color" CUCUMBER_OPTS="--color" ELASTIC_TEST_PORT=9200 DISPLAY=localhost:1.0 xvfb-run bundle exec rake
