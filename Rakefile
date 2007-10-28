require 'rake/testtask'
require 'rake/rdoctask'
require 'rake/packagetask'
require 'rake'
require 'find'

task :default => [:package]

PKG_NAME = 'feed2imap'
PKG_VERSION = '0.9.2'
PKG_FILES = [ 'ChangeLog', 'README', 'COPYING', 'setup.rb', 'Rakefile']
Find.find('bin/', 'lib/', 'test/', 'data/') do |f|
	if FileTest.directory?(f) and f =~ /\.svn/
		Find.prune
	else
		PKG_FILES << f
	end
end
Rake::TestTask.new do |t|
  t.libs << "libs/feed2imap"
	t.libs << "test"
	t.test_files = FileList['test/tc_*.rb']
end

Rake::RDocTask.new do |rd|
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
	require 'rake/gempackagetask'

	spec = Gem::Specification.new do |s|
		s.platform = Gem::Platform::RUBY
		s.summary = "RSS/Atom feed aggregator"
		s.name = PKG_NAME
		s.version = PKG_VERSION
		s.requirements << 'feedparser'
		s.require_path = 'lib'
		s.files = PKG_FILES
		s.description = "RSS/Atom feed aggregator"
	end

	Rake::GemPackageTask.new(spec) do |pkg|
		pkg.need_zip = true
		pkg.need_tar = true
	end
rescue LoadError
  puts "Will not generate gem."
end
