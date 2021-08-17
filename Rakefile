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
    gem.homepage = "https://github.com/postageapp/redns"
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

task default: :test
