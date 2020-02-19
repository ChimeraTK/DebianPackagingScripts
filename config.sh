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
MIRRORLIST="deb [trusted=yes] file://${LOCAL_REPOS} ${DISTRIBUTION} main|deb [trusted=yes] ${DEBIANREPOSITORY}/pub/doocs ${DISTRIBUTION} main|deb http://de.archive.ubuntu.com/ubuntu/ ${DISTRIBUTION}-updates main universe|deb http://de.archive.ubuntu.com/ubuntu/ ${DISTRIBUTION}-security main universe"
if [ "${DISTRIBUTION}" == "buster" ]; then
	MIRRORLIST="deb [trusted=yes] file://${LOCAL_REPOS} ${DISTRIBUTION} main|deb [trusted=yes] ${DEBIANREPOSITORY}/pub/doocs ${DISTRIBUTION} main|deb [trusted=yes] ${DesyNimsRepo}/debian ${DISTRIBUTION}-backports main contrib non-free|deb [trusted=yes] ${DesyNimsRepo}/debian ${DISTRIBUTION} main contrib non-free|deb [trusted=yes] ${DesyNimsRepo}/debian-security ${DISTRIBUTION}/updates main contrib non-free|deb [trusted=yes] ${DesyNimsRepo}/debian ${DISTRIBUTION}-updates main contrib non-free|deb [trusted=yes] ${DesyNimsRepo}/extra/desy ${DISTRIBUTION} desy|deb [trusted=yes] ${DesyNimsRepo}/extra/hasylab.debian ${DISTRIBUTION} main non-free contrib"
fi


