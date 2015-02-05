#!/bin/sh

cd spec/dummy/

/bin/cp config/database-sample.yml config/database.yml

bundle exec rake db:create
bundle exec rake db:migrate
bundle exec rake db:structure:dump
bundle exec rake db:test:clone_structure
