# Package configuration

The package configuration is defined in the `CONFIG` file of the packages'
subdirectory in the DebianBuildVersions repository. The DebianPackagingScripts
generate the control file of the debian package based on this information.

A space-separated list of package types to be released is specified in the `Has-packages` field. For libraries, it typically contains `dev` and `lib`. For the individual package types, the fields of the resulting package control file have to be defined in the form `<fieldname>-<type>`, e.g. `Dependencies-dev`.
