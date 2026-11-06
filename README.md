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

To work, the script requires:

```
sudo apt install pbuilder dh-make python-debian debhelper
```

If you want to also build packages for debian distributions, the package `debian-archive-keyring` is also required on Ubuntu.

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
export N_PBUILDER_THREADS=5
```

## Usage

Run the master script with the distribution you want to build for, and the (debian) package name and the version you want to build for.

Currently available and tested Ubuntu releases are

* `focal` = Ubuntu 20.04
* `noble` = Ubuntu 24.04

The system uses pbuilder, which allows you to build packages also for other Ubuntu releases. Currently, the host system has to be Ubuntu 18.04 or newer, if you want to build for focal. You need root privileges to run pbuilder and you need write permissions to the ChimeraTK DebianBuildVersions repository and the doocspkgs host.

Syntax:

```
./master <distribution_codename> <package_name1> <package_version1> [<package_name2> <package_version2>] [...]
```

Example:
You want to build version 03.31.00 of the DeviceAccess library (debian package base name chimeratk-deviceaccess),
and also recompile the QtHardMon application in version 01.09.00 against this new DeviceAccess version for
Ubuntu 24.04 (noble)

```
~/DebianPackagingScripts$ ./master noble chimeratk-deviceaccess 03.31.00 qthardmon 01.09.00
The following packages will be built (in that order):
chimeratk-deviceaccess 03.31.00
qthardmon 01.09.00
chimeratk-controlsystemadapter 02.13.03
chimeratk-applicationcore 04.09.00
[...]

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
against those packages. Internally, `master` passes `--use-preseed` to the `configureRelease` script, which
can also be called directly with that parameter.

### Build number

Each package is built with a build number, which is part of the Debian package version. The build number is not
derived from the source version of the package and cannot be set directly. It is stored in the
`DebianBuildVersions` repository, in the directory of the source major and minor version (the `epoch`), the
distribution codename and the architecture, below a subdirectory which encodes the versions of all dependencies of
the package, e.g. `chimeratk-deviceaccess/03.31/noble-amd64/libchimeratk-cppext-dev-01.07noble2.02-0/<build number>`.

A build number is reused if a build with exactly the same dependency versions already exists in that directory:
building with dependencies A, then B, and then A again reuses the build number of the first build with A. A new
build number, one higher than the number of the last build in that version, is allocated only for a dependency set
which has not been built before.

If a package has to be released again with completely unchanged dependencies (e.g. because the packaging scripts
or a file inside the `DebianBuildVersions` repository have changed), the increment of the build number can be
forced by passing the parameter `--force-new-buildnumber` to the `master` script:

```
~/DebianPackagingScripts$ ./master --force-new-buildnumber noble chimeratk-deviceaccess 03.31.00
```

Note that the parameter applies to all packages which are being built in that run, not only to the packages
named on the command line. The parameter can also be passed to the `configureRelease` script directly.

### Publication of the packages

When all packages have been built and validated, the `master` script commits the build versions to the
`DebianBuildVersions` repository and copies the packages to the DESY Debian repositories. This is done by the
`commitDebianBuildVersions` and `publishDebianPackages` scripts, which are called at the end of a successful run.

On the way, the scripts can ask the following questions. Some of them let you choose between different actions,
the others are plain confirmations:

* whether missing prerequisites should be installed (confirmation, `y` or `Y`). Only asked if a prerequisite is
  missing.
* whether to remove the leftovers of a previous run (`y` or `Y`), continue the previous build (`c` or `C`), or abort
  with anything else. Only asked if leftovers are detected.
* whether to continue although the `DebianBuildVersions` repository is not in a publishable state (`y` or `Y`),
  reset that repository (`r` or `R`), or abort with anything else. Only asked if the repository is not publishable.
* whether the reset of the `DebianBuildVersions` repository is really wanted (confirmation). Only asked after
  answering `r` to the previous question, and suppressed by `AUTOCLEAN`.
* whether to continue although packages cannot be published (confirmation). Only asked if the publication is
  forbidden already.
* whether to proceed with configuring and building the packages (confirmation). Suppressed by the environment
  variable `AUTOSTART`.
* whether to publish the results (confirmation). Only asked if the publication is allowed, and suppressed by the
  environment variable `AUTOPUBLISH`.
* whether to continue although a package is built in a version which is already in the Debian repositories, or in
  an older source version than the one found there (confirmation, asked by `configureRelease`; only the lowercase
  `y` continues).

The multi-choice questions abort the script for every answer which is not listed. The confirmations abort it unless
the answer is the one which continues, so a negative or missing answer terminates the run without publishing the
packages.

Publication is blocked in the following cases:

* The `DebianBuildVersions` working copy has uncommitted changes, has commits which have not been pushed, or was
  cloned from an origin different from `DebianBuildVersionsURI`. If the build is continued in this situation, the
  packages are built but not published. Answering `r` runs `git reset --hard` and `git clean -f -d` in the working
  copy, which discards uncommitted changes and untracked files (irreversibly) and lifts the block if it was caused
  by local modifications only. Unpushed commits and a wrong origin are not repaired by this, so the publication
  stays blocked in those cases and has to be resolved separately, by pushing the commits or by using a working
  copy which was cloned from the correct URL.
* A package which is being built is already in the Debian repositories in the same version. In this case
  `configureRelease` writes `do_not_publish=1` into the `master-control` file, which is evaluated by
  `commitDebianBuildVersions`.
* The validation of the packages found a problem, for instance a package which does not match its `CONFIG` file or an
  unexpected number of `.deb` files. The script terminates at this point, so the publication is not even attempted.
* One of the built packages is already in the repository when the publication is started, e.g. because someone else
  published packages in parallel. `publishDebianPackages` refuses to publish then.

If the packages are not published, they remain in `pbuilder-result/dists/<codename>/main/binary-amd64`. Whether the
build versions have been committed to git in addition depends on how far the run got:

* If the publication was forbidden from the start, neither `commitDebianBuildVersions` nor `publishDebianPackages`
  is called, so the build versions are not committed.
* Otherwise `commitDebianBuildVersions` runs before the first file is uploaded. It marks every built project with a
  `NOT_PUBLISHED` file, commits the build versions and pushes them, so a failed publication can leave committed
  metadata behind even if no package reached the repository.

`publishDebianPackages` skips every project whose `NOT_PUBLISHED` file is gone, so this script alone can be called
again after a failed or interrupted publication; it retries the projects which are not published yet. Do not call
`commitDebianBuildVersions` again for a run which was partly published: it recreates the `NOT_PUBLISHED` files of
the projects which are already published, and `publishDebianPackages` would then remove those packages from the
repository and fail to copy their local files, which have been deleted after the successful publication.

A project whose packages were installed but whose local files are gone while its `NOT_PUBLISHED` file still exists
(the publication was interrupted between those two steps) cannot be published again: the publication would first
remove the installed packages from the repository and then fail to copy the missing files. Such a project has to be
built again, or its `NOT_PUBLISHED` file has to be removed by hand after checking the repository.

A successful publication commits the build versions with the message
`automated commit: successfully published <package>/<version>/<codename>-<arch>/<build number>`, removes the
`NOT_PUBLISHED` marker files from the `DebianBuildVersions` repository, and finally removes the `pbuilder-result`
directory and the `master-control` file.

### Additional tweaks

During package development, it might be that you have a high turn-around in calling the master script. To accommodate this, it is possible to skip or speed up certain parts of the process:

#### Skipping the initial pbuilder update

If you do not want the pbuilder to be updated on script start, you can use the environment variable `SKIP_PBUILDER_UPDATE`. This will skip running update on the pbuilder image. which might be helpful if you have just done that minutes ago

#### Throwing away everything

The script tries to help you with not accidentally forgetting any changes you made to the Debian package lists or configs. Again, with a high turn-around of `master` calls, this might be a bit hindering.

Setting the `AUTOCLEAN` environment variable will:

* remove any intermediate data that was left from a previous build
* reset the DebianBuildVersions directory

#### Unattended builds

By default the `master` script asks for confirmation before the build starts and once more before the results are
published. Setting the environment variable `AUTOSTART` suppresses the first question, setting the environment
variable `AUTOPUBLISH` suppresses the second one:

```
export AUTOSTART=1
export AUTOPUBLISH=1
./master noble chimeratk-deviceaccess 03.31.00
```

These two variables suppress only those two confirmations. The run needs no interaction only if it also starts from
a clean and prepared state: no leftovers of a previous run (which includes an existing `master-control` file), a
publishable `DebianBuildVersions` repository, all prerequisites installed, a valid authentication for the
`InstallHost` which does not ask for a password, and no package which is already in the repository in the same or
in a newer version. Otherwise one of the other questions listed above is still asked, and an unanswered or negative
answer aborts the run. Setting `AUTOCLEAN` in addition answers the leftovers question with `y` and the repository
question with `r`, and skips the reset confirmation, so leftovers and local changes are discarded without asking.

Take care with `AUTOPUBLISH`: the build versions are then committed to git and the packages are copied to the
DESY Debian repositories without any further confirmation. Note that setting these variables does not change
whether publishing is allowed at all; uncommitted changes in the `DebianBuildVersions` directory still prevent it.

#### Example

To build against DOOCS 20.10, on focal with amd64 as the CPU architecture, the required packages are `dev-doocs-clientlib_20.10.1-focal1_amd64.deb`, `dev-doocs-serverlib_20.10.1-focal1_amd64.deb` and
`dev-doocs-libgul14_20.10.1-focal1_amd64.deb`. Those have to be put into `preseed/dists/focal/main/binary-amd64`, the scripts will take care of the rest.

To build, run `master --preseed focal doocs-legacy-server 01.00.03`

### Custom copyright information

By default, the scripts derive the package's copyright information from the given license and attribute it to DESY & MSK. This can be overriden by placing a custom file called copyright next to the CONFIG file
in DebianBuildVersions

### Blacklisting broken packages

Normally, the scripts will rebuild all reverse-dependencies of library dev packages, because those packages would be broken otherwise when a library package is released, due to the exact version dependency. If one of those reverse-dependencies is broken and cannot be built, the entire tree cannot be rebuilt until this is fixed. In case of emergencies, the script hence allows to blacklist packages to prevent them from being built. For this purpose, just create a file named `blacklist` containing one package name per line (without version). Blacklisted packages which are skipped are still shown (marked as blacklisted) when listing all packages to be built, to raise awareness that these packages will be broken after the new packages are published.

## CONFIG file syntax

Each project needs a file called CONFIG in the project's subdirectory inside the DebianBuildVersions repository. This file describes how the packages are built.

TODO: Add documentation!

### Distribution-specific overrides

It is possible to override settings for a specific distribution by adding a file 
`CONFIG.codename` next to the `CONFIG` file. Settings made in that file take precedence 
over `CONFIG`.

### Multi-line values

Variables can be set to a value containing newlines by using a `heredoc` syntax as follows:

```
variable-name: <<<EOF
some text
which has multiple lines
EOF
```

The terminator token `EOF` is arbitrary, any string can be used as long as it is the same in both occurrences.

### Pre-pdebuild hook

The variable `additional-bind-mounts` can optionally be set to a one or more bash commands which are being executed right before the actual Debian package building is started (i.e. the `pdebuild` command is run by the `makeDebianPackage` script). The commands are launched in a sub-shell by piping them to bash as stdin. Multi-line shell scripts are supported as well (see Section "Multi-line values" above).

## DOOCS and other dependencies

In case a library is updated which is not packaged with these scripts, you can trigger all dependent libraries
to be built using the `runMasterForDependencies` script. The input is a REGEX pattern describing the packages which have changed, and all dependent libraries which can be built with the ChimeraTK debian packaging scripts are updated.

**FIXME**

Currently there is a filter to lib.*-dev in the package name. Is this too restrictive (for instance for python bindings)?

### Finding reverse dependencies

The `findReverseDependencies` script performs the search on which `runMasterForDependencies` is based and can also
be called directly:

```
./findReverseDependencies <package_name> <distribution_codename> <debian_repository> [<architecture>] [no_recurse]
```

It downloads the `Packages` file of the given distribution from the given Debian repository and prints all packages
which depend on the specified package, together with the source version derived from their package versions. The
package name is interpreted as a regular expression, so `dev-doocs.*` for instance finds all packages whose name
starts with `dev-doocs`. The architecture is optional and defaults to `amd64`.

By default the search is repeated recursively, so packages depending on the found packages are listed as well. If
the keyword `no_recurse` is given as the last argument, only the packages which depend directly on the specified
package are printed. The arguments are read by position, so the architecture has to be given in this case;
otherwise the keyword is taken as the architecture and the script tries to read a `binary-no_recurse/Packages`
file with the recursion still enabled. Direct-only searching is hence only possible for amd64:

```
./findReverseDependencies libchimeratk-deviceaccess-dev noble http://doocspkgs.desy.de/ amd64 no_recurse
```

The script needs access to the Debian repository, so it has to be run in the DESY network.

### Example: The DOOCS libraries

DOOCS consists of several library packages, their names start with 'dev-doocs', hence we use the wildcard 'dev-doocs.*'.

Example:

```
~/DebianPackagingScripts$ ./runMasterForDependencies noble "dev-doocs.*" http://doocspkgs.desy.de/
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
