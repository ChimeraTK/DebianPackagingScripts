#!/bin/bash -e

# Update DebianBuildVersions
if [ ! -d "DebianBuildVersions/.git" ]; then
  git clone https://github.com/ChimeraTK/DebianBuildVersions
else
  cd DebianBuildVersions
  git pull
  cd ..
fi

# Find all ChimeraTK github projects
find DebianBuildVersions -name CONFIG -exec grep -l github.com/ChimeraTK \{\} \; | while read line ; do

  project=`echo $line | sed -e 's_^DebianBuildVersions/__' -e 's_/CONFIG$__'`
  echo ==========================================================================================================
  echo   PROJECT: $project
  echo ==========================================================================================================
  echo ./uploadPackageToPPA.sh $project
  ./uploadPackageToPPA.sh $project || ( echo *** FAILED PROJECT $project ; sleep 5 )

done

echo ==========================================================================================================
echo Everything is done.
