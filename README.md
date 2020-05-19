# Debian Packaging Scripts

## Introduction

The denian packaging system is designed for stable libraries which are not upgraded to a newer version in the lifetime
of a debian distribution. Hence it is not foreseen to have more than one development package, and if it is upated, the dependent debian packages are not affected due to binary compatibility.

The ChimeraTK libraries, however, are developing much faster and new debian packages are provided when a new version is available. The libraries are not binary compatible. Hence the development packages of all libraries which use
he library which has changed have to be recompiled.

The debian packaging scripts resolve the reverse dependencies and recursively determine which other development packages depend on a particular library development package. All of these dependencies are automatically rebuild.
The scripts also automatically determine the build number and count it up if a package is build with new dependencies.

The packages are published to the repositories on `doocs.desy.de` and `doocspkgs.desy.de`.

## Usage

### Dependencies

To work, the script requries `pbuilder` and `dh-make` packages. Install these with:
```
sudo apt install pbuilder dh-make
```

Run the master script with the distibution you want to build for, and the (debian) package name and the version you want to build for.

Currently available Ubuntu releases are

* `precice` = Ubuntu 12.04 (until April 2017)
* `trusty` = Ubuntu 14.04
* `xenial` = Ubuntu 16.04

The system uses pbuilder, which allows you to build packages also for other Ubuntu releases. Currently **the host system has to be Ubuntu 16.04** or newer. For the older versions pbuilder still has too many bugs. You need root privileges to run pbuilder and you need write permissions to the ChimeraTK DebianBuildVersions repository and
the doocspkgs host.

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
The script will not only build those two packages but also all other libraries which have development packages that depend on the DeviceAccess library. Note that it will not update any applications automatically. If you wanted also the ChimeraTK command line tools to be recompiled with the new DeviceAccess version, you would have to specify this in the call to the master script.

**FIXME**

Describe which questions the master script might ask, under which conditions it allows or block publishing of the results.

## DOOCS and other dependencies

In case a library is updated which is not packaged with these scripts, you can trigger all dependent libraries
to be build using the `runMasterForDependencies` script. The input is a REGEX pattern describing the packages which have changed, and all dependent libraries which can be build with the ChimeraTK debian packaging scripts are updated.

**FIXME**

Currently there is a filter to lib.*-dev in the package name. Is this too restrictive (for instance for python bindings)?

### Example: The DOOCS libraries

DOOCS consists of several library packages, their names start with 'dev-doocs', hence we use the wildcard 'dev-doocs.*'.

Example:

```
~/DebianPackagingScripts$ ./runMasterForDependencies xenial "dev-doocs.*" http://doocspkgs.desy.de/
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

## Performance optimisation

Set the environment variable N_PBUILDER_THREADS to allow pbuilder to use more than one core.

```
$ export N_PBUILDER_THREADS=5
```
