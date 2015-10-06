#!/bin/bash

RUBY_21_VERSION=2.1.7
RUBY_22_VERSION=2.2.0

git clone https://github.com/sstephenson/rbenv.git $HOME/.rbenv
git clone https://github.com/sstephenson/ruby-build.git $HOME/.rbenv/plugins/ruby-build
git clone git://github.com/tpope/rbenv-aliases.git $HOME/.rbenv/plugins/rbenv-aliases

echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> $HOME/.bashrc
echo 'eval "$(rbenv init -)"' >> $HOME/.bashrc

export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"

rbenv install $RUBY_21_VERSION
#rbenv install $RUBY_22_VERSION

rbenv alias --auto
rbenv alias 2.1 $RUBY_21_VERSION
#rbenv alias 2.2 $RUBY_22_VERSION
rbenv global $RUBY_21_VERSION

gem install bundler
