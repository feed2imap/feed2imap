require 'rake/testtask'
require 'rake/rdoctask'
require 'rake/packagetask'

task :default => [:package]

Rake::TestTask.new do |t|
	t.libs << "test"
	t.test_files = FileList['test/tc_*.rb']
end

Rake::RDocTask.new do |rd|
	rd.main = 'README'
	rd.rdoc_files.include('lib/*.rb', 'lib/feed2imap/*.rb')
	rd.options << '--all'
	rd.rdoc_dir = 'rdoc'
end

Rake::PackageTask.new('feed2imap', '0.8') do |p|
	p.need_tar = true
	p.package_files.include('ChangeLog', 'README', 'COPYING', 'setup.rb',
	'Rakefile', 'data/doc/feed2imap/*/*', 'data/man/*/*', 'bin/feed2imap*',
	'test/*.rb', 'test/parserdata/*.xml', 'test/parserdata/*.output',
	'lib/*.rb', 'lib/feed2imap/*.rb')
end

