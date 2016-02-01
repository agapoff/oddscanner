#!/bin/sh
PKG_NAME=`basename $(pwd)`
tar cvzf ../${PKG_NAME}.tar.gz --exclude=*/.git ../${PKG_NAME}/ ; rpmbuild -ta ../${PKG_NAME}.tar.gz; rm -f ../${PKG_NAME}.tar.gz
