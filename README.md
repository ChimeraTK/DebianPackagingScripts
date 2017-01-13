#Debian Packaging Scripts

##Introduction

The denian packaging system is designed for stable libraries which are not upgraded to a newer version in the lifetime
of a debian distribution. Hence it is not foreseen to have more than one development package, and if it is upated, the dependent debian packages are not affected due to binary compatibility.

The ChimeraTK libraries, however, are developing much faster and new debian packages are provided when a new version is available. The libraries are not binary compatible. Hence the development packages of all libraries which use
he library which has changed have to be recompiled.

The debian packaging scripts resolve the reverse dependencies and recursively determine which other development packages depend on a particular library development package. All of these dependencies are automatically rebuild.
The scripts also automatically determine the build number and count it up if a package is build with new dependencies.

The packages are published to the repositories on `doocs.desy.de` and `doocspkgs.desy.de`.

##Usage

Run the master script with the distriction you want to build for, and the (debian) package name and the version you want to build for.

Currently available distributions are

* `precice` = Ubuntu 12.04 (until April 2017)
* `trusty` = Ubuntu 14.04
* `xenial` = Ubuntu 16.04

Syntax:
```
./master <distribution_codename> <package_name1> <package_version1> [<package_name2> <package_version2>] [...]
```
Example:
You want do build version 00.16.00 of the DeviceAccess library (debian package base name mtca4u-deviceaccess),
and also recompile the QtHardMon application in version 00.17.07  against this new DeviceAccess version for
Ubuntu 16.06 (xenial)
```
~/DebianPackagingScripts$ ./master xenial mtca4u-deviceaccess 00.16.00 qthardmon 00.17.07
The following packages will be build (in that order):
mtca4u-deviceaccess 00.16.00
mtca4u-motordrivercard 00.12.03
bam 01.00.02
daction 02.05.00
qthardmon 00.17.07
doocsllrfwrapper 00.06.01
mtca4u-virtuallab 00.04.01
beam-arrival-time-monitor 01.01.00

Do you want to proceed with configuring and building the packages in the given versions (y/N)? 
```
The script will not only build those two packages but also all other libraries which have development packages that depend on the DeviceAccess library. Not that it will not update any applications automatically. If you wanted also the ChimeraTK command line tools to be recompiled with the new DeviceAccess version, you would have to specify this in the call to the master script.

##DOOCS and other dependencies

In case a library is updated which is not packages with these scripts, you can trigger all dependent libraries
to be build using the `runMasterForDependencies` script. The input is a REGEX pattern describing the packages which have changed, and all dependent packages which can be build with the ChimeraTK debian packaging scripts are updated.

###Example: The DOOCS libraries

DOOCS consists of several library packages, their names start with 'dev-doocs', hence we use the wildcard 'dev-doocs.*'.

Example:
```
~/DebianPackagingScripts$ ./runMasterForDependencies xenial "dev-doocs.*"
No config for 'dev-doocswrappers' found. No packages for this project will be build.
The following packages will be build (in that order):
bam 01.00.02
daction 02.05.00
doocs-server-test-helper 00.03.00
doocsllrfwrapper 00.06.01
beam-arrival-time-monitor 01.01.00

Do you want to proceed with configuring and building the packages in the given versions (y/N)?
```
The package `dev-doocswrappers` is a reverse depenency of DOOCS, but it cannot be build using the ChimeraTK packaging scripts. This package would have to be updated manually (if it wasn't an obsolete, leftover library).