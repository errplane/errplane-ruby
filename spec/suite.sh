#!/bin/bash

set -e

if [[ -s "$HOME/.rvm/scripts/rvm" ]] ; then
  source "$HOME/.rvm/scripts/rvm"
elif [[ -s "/usr/local/rvm/scripts/rvm" ]] ; then
  source "/usr/local/rvm/scripts/rvm"
else
  printf "ERROR: An RVM installation was not found.\n"
fi

function build_version() {
  echo "Bundling for Rails $1..."
  BUNDLE_GEMFILE=gemfiles/Gemfile.rails-$1 bundle install --quiet
  BUNDLE_GEMFILE=gemfiles/Gemfile.rails-$1 bundle exec rake -t spec
}

function versions() {
  build_version "3.2.x"
  build_version "3.1.x"
  build_version "3.0.x"
  # build_version "2.3.x"
}

function use_ruby() {
  rvm use ruby-$1@errplane_gem --create
  versions
}

function run() {
  use_ruby "1.9.3-p194"
  use_ruby "1.9.2-p290"
  use_ruby "1.8.7-p357"
}

function clean() {
  rvm gemset empty errplane_gem --force
}

run
