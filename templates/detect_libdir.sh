#!/bin/bash
BUILDDIR=debian/tmp
INSTFILEDIR=debian

echo "detect_libdir: build dir contents"
find ${BUILDDIR}

# detect libdir used by package's build;install command.
# It should be either /usr/lib or /usr/lib/x86_64-linux-gnu.
# For non-lib packages, where neither is used in output, result variable LIBDIR will be empty
LIBDIR=
c=`find ${BUILDDIR} -wholename '*/usr/lib/x86_64-linux-gnu/*' -print -quit | wc -l`
if [ $c -gt 0 ]; then
    LIBDIR=/usr/lib/x86_64-linux-gnu
else
    c=`find ${BUILDDIR} -wholename '*/usr/lib/*' -print -quit | wc -l`
    if [ $c -gt 0 ]; then
        LIBDIR=/usr/lib
    fi
fi

# replace @LIBDIR@ in install-lists
for f in ${INSTFILEDIR}/*.install; do
    tf=`tempfile`
    cat $f | sed "s|@LIBDIR@|${LIBDIR}|g" > ${tf}
    mv ${tf} $f
done


