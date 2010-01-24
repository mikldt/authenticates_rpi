require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

desc 'Default: run unit tests.'
task :default => :test

desc 'Test the authenticates_rpi plugin.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.libs << 'test'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end

desc 'Generate documentation for the authenticates_rpi plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'AuthenticatesRpi'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "authenticates_rpi"
    gemspec.summary = "CAS Authentication and Authorization on Rails!"
    gemspec.description = "Rails plugin to manage CAS, Authentication, and LDAP name info"
    gemspec.email = "mikldt@gmail.com"
    gemspec.homepage = "http://github.com/mikldt/authenticates_rpi"
    gemspec.authors = ["Michael DiTore"]
  end
rescue LoadError
  puts "Jeweler not available. Install it with: gem install jeweler"
end

