MANDIR := ../data/man

all: $(MANDIR)/man1/feed2imap.1 $(MANDIR)/man1/feed2imap-cleaner.1 $(MANDIR)/man1/feed2imap-dumpconfig.1 $(MANDIR)/man1/feed2imap-opmlimport.1 $(MANDIR)/man5/feed2imaprc.5

$(MANDIR)/man1/feed2imap.1: feed2imap.xml
	docbook2x-man $<
	cp $$(basename $@) $@

$(MANDIR)/man1/feed2imap-cleaner.1: feed2imap-cleaner.xml
	docbook2x-man $<
	cp $$(basename $@) $@

$(MANDIR)/man1/feed2imap-dumpconfig.1: feed2imap-dumpconfig.xml
	docbook2x-man $<
	cp $$(basename $@) $@

$(MANDIR)/man1/feed2imap-opmlimport.1: feed2imap-opmlimport.xml
	docbook2x-man $<
	cp $$(basename $@) $@

$(MANDIR)/man5/feed2imaprc.5: feed2imaprc.xml
	docbook2x-man $<
	cp $$(basename $@) $@
