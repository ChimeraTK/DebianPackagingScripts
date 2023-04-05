#!/bin/bash

# dh_auto_install: default for DESTDIR is debian/tmp (multi-package case) or debian/<package> (single-package case)
# -> auto-detect the case.
# in the single-package case, nothing needs to be done, no need to sort files into different packages, in fact even *.install files are not there.
INSTALLDIR=debian/tmp
if [ ! -d ${INSTALLDIR} ]; then
    echo "detect_libdir: nothing to do"
    exit 0
fi

# directory with *.install lists
INSTFILEDIR=debian

echo "detect_libdir: install dir contents:"
find ${INSTALLDIR}

# detect libdir used by package's build;install command.
# It should be either /usr/lib or /usr/lib/x86_64-linux-gnu.
# For non-lib packages, where neither is used in output, result variable LIBDIR will be empty
LIBDIR=
c=`find ${INSTALLDIR} -wholename '*/usr/lib/x86_64-linux-gnu/*' -print -quit | wc -l`
if [ $c -gt 0 ]; then
    LIBDIR=/usr/lib/x86_64-linux-gnu
else
    c=`find ${INSTALLDIR} -wholename '*/usr/lib/*' -print -quit | wc -l`
    if [ $c -gt 0 ]; then
        LIBDIR=/usr/lib
    fi
fi

# replace @LIBDIR@ in install-lists
for f in ${INSTFILEDIR}/*.install; do
    sed -e "s|@LIBDIR@|${LIBDIR}|g" -i $f
done


