require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'
load 'protobuf/tasks/compile.rake'

RSpec::Core::RakeTask.new(:spec)

RuboCop::RakeTask.new(:rubocop)

task default: %i[rubocop spec]
