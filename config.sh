########################################################################################################################
#
# Configuration for the DebianPackagingScripts
#
# Default values are suitable for use at DESY
#
########################################################################################################################

# URI of the DebianBuildVersions git repository
DebianBuildVersionsURI=git@github.com:ChimeraTK/DebianBuildVersions.git

# URI of the repository to connect to
# a) DESY internal repository
DebianRepository=http://doocspkgs.desy.de/
# b) DESY public repository
#DebianRepository=http://doocs.desy.de/
########################################################################################################################
# Variables used to control the installation process

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

