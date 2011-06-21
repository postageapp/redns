require 'rubygems'
require 'rake'

require 'eventmachine'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "redns"
    gem.summary = %Q{Ruby Reactor-Ready DNS Library}
    gem.description = %Q{ReDNS is a pure Ruby DNS library with drivers for reactor-model engines such as EventMachine}
    gem.email = "github@tadman.ca"
    gem.homepage = "http://github.com/tadman/redns"
    gem.authors = %w[ tadman ]
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

task :test => :check_dependencies

task :default => :test

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "redns #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
