$LOAD_PATH.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "pg_advisory_locker/version"

Gem::Specification.new do |s|
 s.name        = 'pg_advisory_locker'
 s.version     = PgAdvisoryLocker::VERSION
 s.license     = 'New BSD License'
 s.date        = '2013-04-26'
 s.summary     = "Helper for calling PostgreSQL pg_advisory_lock, pg_advisory_try_lock, and pg_advisory_unlock."
 s.description = "This gem provides a module that, when included in your ActiveRecord model, provides methods to acquire and release advisory locks for PostgreSQL connections."
 s.authors     = ["Keith Gabryelski"]
 s.email       = 'keith@fiksu.com'
 s.files       = `git ls-files`.split("\n")
 s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
 s.require_path = 'lib'
 s.homepage    = 'http://github.com/fiksu/pg_advisory_locker'
 s.add_dependency "pg"
 s.add_dependency "rails", '~> 4.0'
 s.add_development_dependency 'rspec-rails', '~> 3.2'
end
