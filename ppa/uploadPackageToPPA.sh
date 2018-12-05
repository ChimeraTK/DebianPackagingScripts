#!/bin/bash -e

PACKAGE="$1"
if [ -z "${PACKAGE}" ]; then
  echo "Usage: ./uplodatePackageToPPA.sh <packageName>"
  exit 1
fi

WD=`dirname $0`
cd "$WD"

# Use the currently by-default used codename when building packages with the master script. We will extract the build information from there.
REFERENCE_CODENAME=xenial

# Update DebianBuildVersions
if [ ! -d "DebianBuildVersions/.git" ]; then
  git clone https://github.com/ChimeraTK/DebianBuildVersions
else
  cd DebianBuildVersions
  git pull
  cd ..
fi

# Check if package is known
if [ ! -f "DebianBuildVersions/${PACKAGE}/CONFIG" ]; then
  echo "'DebianBuildVersions/${PACKAGE}/CONFIG' not found. Is '${PACKAGE}' a valid package name?"
  exit 1
fi

echo "Working on package '${PACKAGE}'..."

# Obtain source URI and dirname
SourceURI=`grep "^SourceURI:" "DebianBuildVersions/${PACKAGE}/CONFIG" | sed -e 's/SourceURI: *//'`
SourceBaseName="`basename "${SourceURI}"`"

# Find latest build in DebianBuildVersions
LAST_BUILD_FILE=`find "DebianBuildVersions/${PACKAGE}" -name LAST_BUILD | sort | tail -n1`
LAST_BUILD_PATH=`cat "${LAST_BUILD_FILE}"`
LAST_BUILD_NUMBER=`cat "DebianBuildVersions/${LAST_BUILD_PATH}/BUILD_NUMBER"`
LAST_BUILD_DIR="`dirname ${LAST_BUILD_FILE}`/${LAST_BUILD_NUMBER}"
SOURCE_PACKAGE=`grep "^Source:" "${LAST_BUILD_DIR}/control" | sed -e 's/^Source: *//'`

# initialise bazaar working copy if not yet done
mkdir -p "${SourceBaseName}"
cd "${SourceBaseName}"
if [ ! -d .bzr ]; then
  bzr branch lp:~chimeratk/chimeratk/${SOURCE_PACKAGE}-package . --use-existing-dir || bzr init
else
  bzr merge lp:~chimeratk/chimeratk/${SOURCE_PACKAGE}-package
fi
cd ..

# Update source tree
if [ ! -d "${SourceBaseName}/.git" ]; then
  echo "Downloading new source tree from git..."
  cd "${SourceBaseName}"
  git init .
  git remote add origin "${SourceURI}"
  git fetch
  cd ..
else
  echo "Updating source tree from git..."
  cd "${SourceBaseName}"
  git fetch
  cd ..
fi

# Determine the tag and check it out
SOURCE_VERSION_NOPATCH=`echo "${LAST_BUILD_FILE}" | sed -e "s_^DebianBuildVersions/${PACKAGE}/__" -e 's_/.*$__'`
cd "${SourceBaseName}"
SOURCE_VERSION=`git tag | grep "^${SOURCE_VERSION_NOPATCH}" | sort | tail -n1`
echo "Using source version $SOURCE_VERSION"
git reset ${SOURCE_VERSION}
git checkout ${SOURCE_VERSION}
cd ..

# Copy Debian control files from the build
mkdir -p "${SourceBaseName}/debian"
cp -r "${LAST_BUILD_DIR}"/* "${SourceBaseName}/debian"

# Hack the control file to be independent of the Ubuntu version and the exact build: remove all build-dependency version numbers
rm -f "${SourceBaseName}/debian/control-new"
touch "${SourceBaseName}/debian/control-new"
while read line; do
  line_new=""
  IFS=','
  # tokenise the line to handle dependency versions properly
  for token in $line ; do
    IFS=' '
    # does the token contain a ChimeraTK build version (i.e. contain 'xenial')? -> replace 'xenial' with 'ubuntu'
    # otherwise remove everything within parenthesis
    if [[ "$token" == *"${REFERENCE_CODENAME}"* ]]; then
      token="`echo "$token" | sed -e 's/'${REFERENCE_CODENAME}'/ubuntu/'`"
      # exact version match? losen the match a bit, since the PPA adds a suffix to the version
      if [[ "$token" == *"(="* ]]; then
        dependency=`echo $token | sed -e 's/(=.*$//'`
        version=`echo $token | sed -e 's/.*(=//' -e 's/)//'`
        token="${dependency} (> ${version}-0~0), ${dependency} (< ${version}-999~999)"
      fi
    else
      token="`echo "$token" | sed -e 's/ ([^)]*)//'`"
    fi
    if [ -z "${line_new}" ]; then
      line_new="${token}"
    else
      line_new="${line_new},${token}"
    fi
  done
  # replace lines "Architecture: amd64" with "Architecture: any"
  if [ "$line" == "Architecture: amd64" ]; then
    line_new="Architecture: any"
  fi
  echo ${line_new} >> "${SourceBaseName}/debian/control-new"
done < "${SourceBaseName}/debian/control"
mv "${SourceBaseName}/debian/control-new" "${SourceBaseName}/debian/control"

# rename install files, replace 'xenial' in the filenames with 'ubuntu'
rm -f ${SourceBaseName}/debian/*ubuntu*.install
rename s/${REFERENCE_CODENAME}/ubuntu/ ${SourceBaseName}/debian/*.install

# Hack the rules file to set the build version
sed -i "${SourceBaseName}/debian/rules" -e 's,^#!/usr/bin/make -f$,#!/usr/bin/make -f\nexport PROJECT_BUILDVERSION=ubuntu'${LAST_BUILD_NUMBER}','

# check if anything modified. if not, we are done
cd "${SourceBaseName}"
if [ `bzr status | grep -v ".git" | grep -v "^modified:$" | grep -v "^unknown:$" | wc -l` -eq 0 ]; then
  echo "*** No changes, nothing to commit."
  exit 0
fi

# form the Debian version
DEBIAN_VERSION=`echo ${SOURCE_VERSION} | sed -e 's/\(..\...\)/\1ubuntu'${LAST_BUILD_NUMBER}'/'`

# generate changelog file
rm -f debian/changelog
debchange --create --package ${SOURCE_PACKAGE} -v ${DEBIAN_VERSION} "Automated preparation for the PPA"

# Commit everything to launchpad
bzr add .
bzr commit -m "Automated commit"
bzr push lp:~chimeratk/chimeratk/${SOURCE_PACKAGE}-package
