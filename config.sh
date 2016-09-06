########################################################################################################################
#
# Configuration for the DebianPackagingScripts
#
# Default values are suitable for use at DESY
#
########################################################################################################################

# URI of the DebianBuildVersions git repository
DebianBuildVersionsURI=git@github.com:ChimeraTK/DebianBuildVersions.git

########################################################################################################################
# Variables used to control the installation process

# Host name where to publish the Debian packages on. You will need ssh access to that machine and rights to execute
# reprepro with sudo as root.
#InstallHost=doocspkgs
InstallHost=localhost

# Debian package archive directory. This is where the new packages will be copied. Packages to be replaced will
# be first moved into ../old relativ to that directory.
PackageArchive='/home/debian/${distribution}/stable'  # evalulate later

# Priviledges to set the copied files to. Your account on the InstallHost needs to be in the PackageFileGroup.
PackageFileGroup=flash
PackagePriviledges=664

# map of repository names (as used in the CONFIG files of the projects) to target directories on the InstallHost
declare -A RepositoryDirectories
RepositoryDirectories["intern"]=/export/reprepro/intern/doocs
RepositoryDirectories["pub"]=/export/reprepro/pub/doocs

