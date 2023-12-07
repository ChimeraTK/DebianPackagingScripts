# Debian Packaging Scripts

## Introduction

The debian packaging system is designed for stable libraries which are not upgraded to a newer version in the lifetime
of a debian distribution. Hence it is not foreseen to have more than one development package, and if it is upated, the dependent debian packages are not affected due to binary compatibility.

The ChimeraTK libraries, however, are developing much faster and new debian packages are provided when a new version is available. The libraries are not binary compatible. Hence the development packages of all libraries which use the library which has changed have to be recompiled.

The debian packaging scripts resolve the reverse dependencies and recursively determine which other development packages depend on a particular library development package. All of these dependencies are automatically rebuilt.
The scripts also automatically determine the build number and count it up if a package is built with new dependencies.

The packages are published to the repositories on `doocs.desy.de` and `doocspkgs.desy.de`; the repository urls are as below:
```
http://doocs.desy.de/pub/doocs 
http://doocspkgs.desy.de/pub/doocs
```

### Dependencies

To work, the script requries:
```
sudo apt install pbuilder dh-make python-debian debhelper
```
### Recommendations

#### Linux Distribution

It is recommended to run this script on a standard Ubuntu installation. Non-standard distributions (such as the "yellow Linux" used on some DESY PCs) may break `pbuilder` / `debootstrap` by using apt sources / GPG keys different from the original.

#### Kerberos
Get valid kerberos tickets to `doocs.desy.de` and `doocspkgs.desy.de` before running the script. This avoids consecutive password prompts during the publishing step. The sequential password prompts give an impression of entered passwords being rejected and needing reentry (besides being inconvenient). Having a valid kerberos ticket sidesteps this issue. For a kerberos ticket:
```
kinit <user_name>@DESY.DE
```

#### Performance optimization

Set the environment variable N_PBUILDER_THREADS to allow pbuilder to use more than one core.

```
$ export N_PBUILDER_THREADS=5
```
## Usage

Run the master script with the distribution you want to build for, and the (debian) package name and the version you want to build for.

Currently available and tested Ubuntu releases are

* `xenial` = Ubuntu 16.04
* `focal` = Ubuntu 20.04

The system uses pbuilder, which allows you to build packages also for other Ubuntu releases. Currently, the host system has to be Ubuntu 18.04 or newer, if you want to build for focal. You need root privileges to run pbuilder and you need write permissions to the ChimeraTK DebianBuildVersions repository and the doocspkgs host.

Syntax:

```
./master <distribution_codename> <package_name1> <package_version1> [<package_name2> <package_version2>] [...]
```
Example:
You want to build version 00.16.00 of the DeviceAccess library (debian package base name mtca4u-deviceaccess),
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

**Overriding the default configuration**

The default configuration, e.g. for the used source and package repositories,
is defined in `config.sh`. It can be overridden by adding an additional
`config.sh` in a subdirectory `override_config` to the top level of the working
copy of this repository. The additional file will be sourced at the end of the
default one.

### Preseeding

In rare conditions, it might be necessary to build against an older set of development packages than what is available in the official repositories.
In that case, it is possible to put the relevant packages into a repository structure below the `preseed` folder.

The `master` script has to be called with the parameter `--preseed` for the packaging scripts to pack them up

### DKMS

It is possible to use the debian packaging scripts to build DKMS packages. To do that, the Makefile in the kernel module must provide a 
`packaging_install` target. The Makefile will have the four variables `PACKAGING_INSTALL`, `DESTDIR`, `DKMS_PKG_NAME` and `DKMS_PKG_VERSION` set.

You can use `PACKAGING_INSTALL` to provide different install targets depending on whether it is called inside packaging or not, for example

```
ifeq ($(PACKAGING_INSTALL),1)
install: packaging_install
else
install: kernel_install
endif

kernel_install:
	$(MAKE) -C $(KERNEL_SRC) M=$(SRC) install

packaging_install:
	install -m 644 -D *.c Makefile -t $(DESTDIR)/usr/src/$(DKMS_PKG_NAME)-$(DKMS_PKG_VERSION)/
	install -m 644 -D uio-dummy.rules -t $(DESTDIR)/lib/udev/rules.d/
```

### Additional tweaks
During package development, it might be that you have a high turn-around in calling the master script. To accommodate this, it is possible to skip or speed up certain parts of the process:

#### Skipping the initial pbuilder update

If you do not want the pbuilder to be updated on script start, you can use the environment variable `SKIP_PBUILDER_UPDATE`. This will skip running update on the pbuilder image. which might be helpful if you have just done that minutes ago

#### Throwing away everything

The script tries to help you with not accidentally forgetting any changes you made to the Debian package lists or configs. Again, with a high turn-around of `master` calls, this might be a bit hindering.

Setting the `AUTOCLEAN` environment variable will:
* remove any intermediate data that was left from a previous build
* reset the DebianBuildVersions directory

#### Example

To build against DOOCS 20.10, on focal with amd64 as the CPU architecture, the required packages are `dev-doocs-clientlib_20.10.1-focal1_amd64.deb`, `dev-doocs-serverlib_20.10.1-focal1_amd64.deb` and
`dev-doocs-libgul14_20.10.1-focal1_amd64.deb`. Those have to be put into `preseed/dists/focal/main/binary-amd64`, the scripts will take care of the rest.

To build, run `master --preseed focal doocs-legacy-server 01.00.03`


**FIXME**

Describe which questions the master script might ask, under which conditions it allows or block publishing of the results.

### Custom copyright information

By default, the scripts derive the package's copyright information from the given license and attribute it to DESY & MSK. This can be overriden by placing a custom file called copyright next to the CONFIG file
in DebianBuildVersions

### Blacklisting broken packages

Normally, the scripts will rebuild all reverse-dependencies of library dev packages, because those packages would be broken otherwise when a library package is released, due to the exact version dependency. If one of those reverse-dependencies is broken and cannot be built, the entire tree cannot be rebuilt until this is fixed. In case of emergencies, the script hence allows to blacklist packages to prevent them from being built. For this purpose, just create a file named `blacklist` containing one package name per line (without version). Blacklisted packages which are skipped are still shown (marked as blacklisted) when listing all packages to be built, to raise awareness that these packages will be broken after the new packages are published.


## DOOCS and other dependencies

In case a library is updated which is not packaged with these scripts, you can trigger all dependent libraries
to be built using the `runMasterForDependencies` script. The input is a REGEX pattern describing the packages which have changed, and all dependent libraries which can be built with the ChimeraTK debian packaging scripts are updated.

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

The package `dev-doocswrappers` is a reverse depenency of DOOCS, but it cannot be built using the ChimeraTK packaging scripts. This package would have to be updated manually (if it wasn't an obsolete, leftover library).

