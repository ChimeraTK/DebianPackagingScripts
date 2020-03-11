########################################################################################################################
#
# Configuration for the DebianPackagingScripts
#
# Default values are suitable for use at DESY
#
########################################################################################################################
WD=`realpath $(dirname "$0")`

# URI of the DebianBuildVersions git repository
DebianBuildVersionsURI=git@github.com:ChimeraTK/DebianBuildVersions.git

# URI of the repository to connect to
# a) DESY internal repository
DebianRepository=http://doocspkgs.desy.de/
# b) DESY public repository
#DebianRepository=http://doocs.desy.de/
########################################################################################################################
# Variables used to control the installation process
DesyNimsRepo=http://nims.desy.de/
# Host name where to publish the Debian packages on. You will need ssh access to that machine and rights to execute
# reprepro with sudo as root.
InstallHost=doocspkgs
if [ -z ${DISTRIBUTION+x} ]; then 
DISTRIBUTION=${distribution}; 
else distribution=${DISTRIBUTION}
fi

# Debian package archive directory. This is where the new packages will be copied. Packages to be replaced will
# be first moved into ../old relativ to that directory.
PackageArchive='/home/debian/${distribution}/stable'  # evalulate later

# map of repository names (as used in the CONFIG files of the projects) to target directories on the InstallHost
declare -A RepositoryDirectories
RepositoryDirectories["intern"]=/export/reprepro/intern/doocs
RepositoryDirectories["pub"]=/export/reprepro/pub/doocs

# Path to the local Debian "repository"
LOCAL_REPOS=${WD}/pbuilder-result

DEBIANREPOSITORY="${DebianRepository}"

# List of mirrors / package repositories used inside the pbuilder environment by apt
MIRRORLIST="deb [trusted=yes] file://${LOCAL_REPOS} ${distribution} main|deb [trusted=yes] ${DEBIANREPOSITORY}/pub/doocs ${distribution} main|deb http://de.archive.ubuntu.com/ubuntu/ ${distribution}-updates main universe|deb http://de.archive.ubuntu.com/ubuntu/ ${distribution}-security main universe"
ADDITIONALREPO="universe"
if [ "${distribution}" == "buster" ] || [ "${distribution}" == "stretch"  ]; then
	MIRRORLIST="deb [trusted=yes] file://${LOCAL_REPOS} ${distribution} main|deb [trusted=yes] ${DEBIANREPOSITORY}/pub/doocs ${distribution} main|deb [trusted=yes] ${DesyNimsRepo}/debian ${distribution}-backports main contrib non-free|deb [trusted=yes] ${DesyNimsRepo}/debian ${distribution} main contrib non-free|deb [trusted=yes] ${DesyNimsRepo}/debian-security ${distribution}/updates main contrib non-free|deb [trusted=yes] ${DesyNimsRepo}/debian ${distribution}-updates main contrib non-free|deb [trusted=yes] ${DesyNimsRepo}/extra/desy ${distribution} desy|deb [trusted=yes] ${DesyNimsRepo}/extra/hasylab.debian ${distribution} main non-free contrib"
	ADDITIONALREPO="contrib"
fi
