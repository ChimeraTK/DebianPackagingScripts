#!/bin/bash -e

echo "NOT YET TESTED!!!!!!!!!!!!!!!!!!!"

echo "Building in $(pwd). Press Ctrl+C to abort within 5 seconds..."
sleep 5

if [ -f "/var/cache/pbuilder/result/*" ]; then
  echo "/var/cache/pbuilder/result/ is not empty"
  exit 1
fi
if [ ! -f "~/software/debian-packages/pbuilder-base/base-bookworm.tgz" ]; then
  echo "~/software/debian-packages/pbuilder-base/base-bookworm.tgz does not exist"
  exit 1
fi

git clone https://salsa.debian.org/toolchain-team/gcc.git gcc-13_13.1.0
cd gcc-13_13.1.0

wget https://ftp.mpi-inf.mpg.de/mirrors/gnu/mirror/gcc.gnu.org/pub/gcc/releases/gcc-13.1.0/gcc-13.1.0.tar.xz
wget ftp://sourceware.org/pub/newlib/newlib-4.3.0.20230120.tar.gz

cd ..
tar zcf gcc-13_13.1.0.orig.tar.gz gcc-13_13.1.0/gcc-13.1.0.tar.xz gcc-13_13.1.0/newlib-4.3.0.20230120.tar.gz

echo Content of tar ball:
tar tf gcc-13_13.1.0.orig.tar.gz
sleep 2


echo Patching to disable tests...
cd gcc-13_13.1.0
patch -p1 <<EOF
diff --git i/debian/rules.defs w/debian/rules.defs
index fdf383c2..2921ef18 100644
--- i/debian/rules.defs
+++ w/debian/rules.defs
@@ -1671,7 +1671,7 @@ endif
 # run testsuite ---------------
 with_check := yes
 # if you don't want to run the gcc testsuite, uncomment the next line
-#with_check := disabled by hand
+with_check := disabled by hand
 ifeq ($(with_base_only),yes)
   with_check := no
 endif
EOF

pdebuild -- --distribution bookworm --basetgz ~/software/debian-packages/pbuilder-base/base-bookworm.tgz
rsync -av /var/cache/pbuilder/result/ result/