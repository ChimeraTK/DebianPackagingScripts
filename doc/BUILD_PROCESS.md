# Library build process and versioning

This page describes the versioning of the ChimeraTK libraries and the build
process performed by the DebianPackagingScripts.

## Versioning

The libraries' source code is versioned by a version number in the format
MAJOR.MINOR.PATCH. Binary compatibility is not guaranteed between versions that
differ in MAJOR and MINOR numbers. As an effect, downstream development packages need to be
rebuild against their changed dependencies.

A library or application may be rebuild
against changed dependencies. In order to reflect the exact versions of the dependenies of a
particular package release, a build number is assigned in addition to the
source code version number.

## Build process

The DebianPackagingScripts have been developed with focus on the above scenario
of also updating the reverse dependencies of a library. For each development
package, the scripts recursively determine which other development packages
need to be rebuild. Application packages are not updated automatically and need
to be specified explicitly by the user.

The packages are then configured and build by pbuilder in an appropriate order.  
The package configuration is defined in the `CONFIG` file of the packages'
subdirectory in the DebianBuildVersions repository.
