# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rake/testtask'
require "net/http"

Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/**/*_test.rb']
end

require 'rubocop/rake_task'

RuboCop::RakeTask.new

task default: %i[test rubocop]

desc 'Generate signatures'
task :gensig do
  sh 'typeprof', '-o', 'sig/yaparc.gen.rbs', 'sig/yaparc.rbs', *Dir['lib/**/*.rb']
end

file "test/abc.html" do |t|
  doc = Net::HTTP.get("web.archive.org", "/web/20120814155205/http://www.norbeck.nu:80/abc/bnf/abc20bnf.htm")
  File.write(t.name, doc)
end
