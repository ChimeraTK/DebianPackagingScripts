#!/bin/bash -e

echo "IMPORTANT: Must run on amd64 Debian Bookworm (e.g. devcontainer)!"

echo "Building in $(pwd). Press Ctrl+C to abort within 5 seconds..."
sleep 5

sudo apt-get install -y lsb-release
if [ "$(lsb_release -c -s | tail -n1)" != "bookworm" ]; then
  echo "This script must be run inside Debian Bookworm!"
  exit 1
fi

# Note: Extracted and cleaned Build-Depends from debian control file, may be done slightly incorrect...
sudo apt-get install debhelper dpkg-dev g++-multilib m4 libtool autoconf2.69 dwz gawk lzma xz-utils patchutils libzstd-dev zlib1g-dev systemtap-sdt-dev binutils gperf bison flex gettext gdb nvptx-tools amdgcn-tools texinfo locales-all sharutils procps gnat-12:native g++-12 netbase gdc-12 python3 libisl-dev libmpc-dev libmpfr-dev libgmp-dev lib32z1-dev  unzip dejagnu coreutils chrpath quilt time pkg-config libgc-dev doxygen graphviz ghostscript texlive-latex-base xsltproc libxml2-utils docbook-xsl-ns


git clone -b 13.3.0-12 https://salsa.debian.org/toolchain-team/gcc.git gcc-13_13.3.0
cd gcc-13_13.3.0

# revert commit which disables building certain packages which would come from gcc-14 on true Debian...
git revert 68461ac22716c8587ab3137cd7b3cddf34fc853a --no-edit

wget https://ftp.mpi-inf.mpg.de/mirrors/gnu/mirror/gcc.gnu.org/pub/gcc/releases/gcc-13.3.0/gcc-13.3.0.tar.xz
wget ftp://sourceware.org/pub/newlib/newlib-4.4.0.20231231.tar.gz

cd ..
tar zcf gcc-13_13.3.0.orig.tar.gz gcc-13_13.3.0/*.tar.*

echo Content of tar ball:
tar tf gcc-13_13.3.0.orig.tar.gz
sleep 2


echo Patching to disable tests...
cd gcc-13_13.3.0
patch -p1 <<EOF
diff --git i/debian/rules.defs w/debian/rules.defs
index fdf383c2..2921ef18 100644
--- i/debian/rules.defs
+++ w/debian/rules.defs
@@ -1733,7 +1733,7 @@ endif
 # run testsuite ---------------
 with_check := yes
 # if you don't want to run the gcc testsuite, uncomment the next line
-#with_check := disabled by hand
+with_check := disabled by hand
 ifeq (\$(with_base_only),yes)
   with_check := no
 endif
EOF

debuild -d --no-sign -b
