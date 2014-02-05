require 'test/unit'
require 'fileutils'
require 'tmpdir'
require 'mocha/setup'

require 'feed2imap/maildir'

class TestMaildir < Test::Unit::TestCase

  def setup
    @tmpdirs = []
  end

  def teardown
    @tmpdirs.each do |dir|
      FileUtils.rm_rf(dir)
    end
  end

  def test_cleanup
    folder = create_maildir
    msgs = message_count(folder)

    maildir_account.cleanup(folder)

    assert_equal msgs - 1, message_count(folder)
  end

  def test_putmail
    folder = create_maildir
    msgs = message_count(folder)

    mail = RMail::Message.new
    mail.header['Subject'] = 'a message I just created'
    mail.body = 'to test maildir'
    maildir_account.putmail(folder, mail)

    assert_equal msgs + 1, message_count(folder)
  end

  def test_updatemail
    folder = create_maildir
    path = maildir_account.send(
      :find_mails,
      folder,
      'regular-message-id@debian.org'
    ).first
    assert_not_nil path
    mail = RMail::Message.new
    mail.header['Subject'] = 'a different subject'
    mail.header['Message-ID'] = 'regular-message-id@debian.org'
    mail.body = 'This is the body of the message'
    maildir_account.updatemail(folder, mail, 'regular-message-id@debian.org')

    updated_path = maildir_account.send(
      :find_mails,
      folder,
      'regular-message-id@debian.org'
    ).first
    updated_mail = RMail::Parser.read(File.open(File.join(folder, updated_path)))

    assert_equal 'a different subject', updated_mail.header['Subject']
  end

  def test_find_mails
    folder = create_maildir
    assert_equal 0, maildir_account.send(:find_mails, folder, 'SomeRandomMessageID').size
  end

  private

  def create_maildir
    parent = Dir.mktmpdir
    @tmpdirs << parent
    FileUtils.cp_r('test/maildir', parent)
    return File.join(parent, 'maildir')
  end

  def message_count(folder)
    Dir.glob(File.join(folder, '**', '*')).reject { |f| File.directory?(f) }.size
  end

  def maildir_account
    @maildir_account ||=
      begin
        MaildirAccount.new.tap do |account|
          account.stubs(:puts)
        end
      end
  end

end

