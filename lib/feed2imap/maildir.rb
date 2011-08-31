=begin
Feed2Imap - RSS/Atom Aggregator uploading to an IMAP Server, or local Maildir
Copyright (c) 2009 Andreas Rottmann

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
=end

require 'uri'
require 'fileutils'
require 'fcntl'

class MaildirAccount
  MYHOSTNAME = Socket.gethostname

  attr_reader :uri

  def initialize
    @seq_num = 0
  end

  def putmail(folder, mail, date = Time::now)
    store_message(folder_dir(folder), date, nil) do |f|
      f.puts(mail)
    end
  end

  def updatemail(folder, mail, idx, date = Time::now, reupload_if_updated = true)
    dir = folder_dir(folder)
    guarantee_maildir(dir)
    mail_files = find_mails(dir, idx)
    flags = nil
    if mail_files.length > 0
      # get the info from the first result and delete everything
      info = maildir_file_info(mail_files[0])
      mail_files.each { |f| File.delete(File.join(dir, f)) }
    elsif not reupload_if_updated
      # mail not present, and we don't want to re-upload it
      return
    end
    store_message(dir, date, info) { |f| f.puts(mail) }
  end

  def to_s
    uri.to_s
  end

  def cleanup(folder, dryrun = false)
    dir = folder_dir(folder)
    puts "-- Considering #{dir}:"
    guarantee_maildir(dir)

    del_count = 0
    recent_time = Time.now() -- (3 * 24 * 60 * 60) # 3 days
    Dir[File.join(dir, 'cur', '*')].each do |fn|
      flags = maildir_file_info_flags(fn)
      # don't consider not-seen, flagged, or recent messages
      mtime = File.mtime(fn)
      next if (not flags.index('S') or
               flags.index('F') or
               mtime > recent_time)
      File.open(fn) do |f|
        mail = RMail::Parser.read(f)
      end
      if dryrun
        puts "To remove: #{subject} #{mtime}"
      else
        puts "Removing: #{subject} #{mtime}"
        File.delete(fn)
      end
      del_count += 1
    end
    puts "-- Deleted #{del_count} messages"
    return del_count
  end

  private

  def folder_dir(folder)
    return File.join('/', folder)
  end

  def store_message(dir, date, info, &block)

    guarantee_maildir(dir)

    stored = false
    Dir.chdir(dir) do |d|
      timer = 30
      fd = nil
      while timer >= 0
        new_fn = new_maildir_basefn(date)
        tmp_path = File.join(dir, 'tmp', new_fn)
        new_path = File.join(dir, 'new', new_fn)
        begin
          fd = IO::sysopen(tmp_path,
                           Fcntl::O_WRONLY | Fcntl::O_EXCL | Fcntl::O_CREAT)
          break
        rescue Errno::EEXIST
          sleep 2
          timer -= 2
          next
        end
      end

      if fd
        begin
          f = IO.open(fd)
          # provide a writable interface for the caller
          yield f
          f.fsync
          File.link tmp_path, new_path
          stored = true
        ensure
          File.unlink tmp_path if File.exists? tmp_path
        end
      end

      if stored and info
        cur_path = File.join(dir, 'cur', new_fn + ':' + info)
        File.rename(new_path, cur_path)
      end
    end # Dir.chdir

    return stored
  end

  def find_mails(dir, idx)
    dir_paths = []
    ['cur', 'new'].each do |d|
      subdir = File.join(dir, d)
      raise "#{subdir} not a directory" unless File.directory? subdir
      Dir[File.join(subdir, '*')].each do |fn|
        File.open(fn) do |f|
          mail = RMail::Parser.read(f)
          cache_index = mail.header['Message-Id']
          next if not (cache_index and cache_index == idx)
          dir_paths.push(File.join(d, File.basename(fn)))
        end
      end
    end
    return dir_paths
  end

  def guarantee_maildir(dir)
    # Ensure maildir-folderness
    ['new', 'cur', 'tmp'].each do |d|
      FileUtils.mkdir_p(File.join(dir, d))
    end
  end

  def maildir_file_info(file)
    basename = File.basename(file)
    colon = basename.rindex(':')

    return (colon and basename[colon + 1 .. -1])
  end

  # Re-written and no longer shamelessly taken from
  # http://gitorious.org/sup/mainline/blobs/master/lib/sup/maildir.rb
  def new_maildir_basefn(date)
    fn = "#{date.to_i.to_s}.#{@seq_num.to_s}.#{MYHOSTNAME}"
    @seq_num = @seq_num + 1
    fn
  end
end

