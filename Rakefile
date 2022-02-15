require 'rake/testtask'
require 'rdoc/task'
require 'rake/packagetask'
require 'rake'
require 'find'
require_relative "lib/feed2imap/version"

task :default => [:test]

PKG_NAME = 'feed2imap'
PKG_VERSION = Feed2Imap::VERSION
PKG_FILES = [ 'ChangeLog', 'README', 'COPYING', 'setup.rb', 'Rakefile']
Find.find('bin/', 'lib/', 'test/', 'data/') do |f|
  if FileTest.directory?(f) and f =~ /\.svn/
    Find.prune
  else
    PKG_FILES << f
  end
end
Rake::TestTask.new do |t|
  t.verbose = true
  t.libs << "test"
  t.test_files = FileList['test/tc_*.rb'] - ['test/tc_httpfetcher.rb']
end

RDoc::Task.new do |rd|
  rd.main = 'README'
  rd.rdoc_files.include('lib/*.rb', 'lib/feed2imap/*.rb')
  rd.options << '--all'
  rd.options << '--diagram'
  rd.options << '--fileboxes'
  rd.options << '--inline-source'
  rd.options << '--line-numbers'
  rd.rdoc_dir = 'rdoc'
end

Rake::PackageTask.new(PKG_NAME, PKG_VERSION) do |p|
  p.need_tar = true
  p.need_zip = true
  p.package_files = PKG_FILES
end

# "Gem" part of the Rakefile
begin
  require 'rubygems/package_task'

  spec = Gem::Specification.new do |s|
    s.platform = Gem::Platform::RUBY
    s.summary = "RSS/Atom feed aggregator"
    s.name = PKG_NAME
    s.version = PKG_VERSION
    s.add_runtime_dependency 'ruby-feedparser', '>= 0.9'
    s.add_runtime_dependency 'rmail', '>= 1.1.4'
    s.require_path = 'lib'
    s.executables = PKG_FILES.grep(%r{\Abin\/.}).map { |bin|
      bin.gsub(%r{\Abin/}, '')
    }
    s.files = PKG_FILES
    s.description = "RSS/Atom feed aggregator"
    s.authors = ['Lucas Nussbaum']
  end

  Gem::PackageTask.new(spec) do |pkg|
    pkg.need_zip = true
    pkg.need_tar = true
  end
rescue LoadError
  puts "Will not generate gem."
end

desc 'Makes a new release'
task :release => :repackage do
  sh 'git', 'tag', '--sign', 'v' + PKG_VERSION
  sh 'git', 'push'
  sh 'git', 'push', '--tags'
  sh 'gem', 'push', "pkg/#{PKG_NAME}-#{PKG_VERSION}.gem"
end
