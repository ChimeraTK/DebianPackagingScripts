#!/bin/bash -e

export distribution="$1"
debfile_name="$2"

if [ -z "${debfile_name}" ]; then
  echo "Usage: removeDebianPackage <distribution> <debfile_name>"
  exit 1
fi

# load configuration
source config.sh

  TEMPFILE=`mktemp -p .`
  echo "#!/bin/bash -e" > $TEMPFILE
  echo "cd /home/debian/${distribution}/stable" >> $TEMPFILE
  echo "if [ ! -f \"${debfile_name}\" ]; then" >> $TEMPFILE
  echo "  echo File ${debfile_name} not found. Exiting." >> $TEMPFILE
  echo "  exit 1" >> $TEMPFILE
  echo "fi" >> $TEMPFILE
  echo "packname=\`dpkg-deb -f ${debfile_name} Package\`" >> $TEMPFILE
  echo "echo mv ${debfile_name} ../old" >> $TEMPFILE
  echo "mv ${debfile_name} ../old" >> $TEMPFILE
  for REPO in intern pub; do #just remove everywhere if it's not even in there so what
    echo "  echo sudo -H reprepro --waitforlock 2 -Vb ${RepositoryDirectories[${REPO}]} remove ${distribution} \"\$packname\"" >> $TEMPFILE
    echo "  sudo -H reprepro --waitforlock 2 -Vb ${RepositoryDirectories[${REPO}]} remove ${distribution} \"\$packname\"" >> $TEMPFILE
  done
  echo " " >> $TEMPFILE
  echo "Done. Don't forget to move the 'changes' file."  >> $TEMPFILE
  echo "rm \$HOME/$TEMPFILE" >> $TEMPFILE
  chmod +x $TEMPFILE
  scp $TEMPFILE ${InstallHost}:$TEMPFILE
  ssh ${InstallHost} $TEMPFILE
  rm $TEMPFILE
