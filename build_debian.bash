#!/bin/bash

VERSION=0.5

rm -rf pkg
rake package
cd pkg
mv feed2imap-$VERSION.tgz feed2imap_$VERSION.orig.tar.gz
cd feed2imap-$VERSION
cp -r ../../debian .
rm -rf debian/.svn
dpkg-buildpackage -rfakeroot
cd ..

dpkg-scanpackages . /dev/null >Packages
dpkg-scansources . /dev/null >Sources
gzip Packages
gzip Sources
rm -rf feed2imap-$VERSION
