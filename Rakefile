require 'rake/testtask'
require 'rake/rdoctask'
require 'rake/packagetask'

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

Rake::PackageTask.new('feed2imap', '0.1') do |p|
	p.need_tar = true
	p.package_files.include('ChangeLog', 'README', 'TODO', 'COPYING', 'setup.rb', 'Rakefile', 'feed2imaprc-example', 'bin/feed2imap*', 'test/*.rb', 'lib/*.rb', 'lib/feed2imap/*.rb')
end

