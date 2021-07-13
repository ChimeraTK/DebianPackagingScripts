#!/bin/bash

#
# Little helper to produce nicer and more readable screen output in scripts: Only display the last line of the
# output of another script and constantly overwrite it. Only in case of an error the full output is dumped to screen.
#

if [ -z "$*" ]; then
  echo "Usage: ./helper_compress_output <command>"
  echo "Will execute the specified command and 'compress' the output into a single line which is constantly overwritten. Only in case of an error (non-zero exit status) the full output is dumped to the screen."
  exit 1
fi

TMPFILE=`mktemp`
NLINES=5

trap ctrl_c INT

function ctrl_c() {
  tput csr 0 $LINES
  tput cup $((LAST_LINE-1)) 0
}

getCPos () { 
    local v=() t=$(stty -g)
    stty -echo
    tput u7
    IFS='[;' read -rd R -a v
    stty $t
    CPos=(${v[@]:1})
}

# insert blank space where to place the output
for (( i = 0; i < NLINES ; i++)); do
  echo ""
done

# get cursor position of last line in blank space
getCPos
LAST_LINE=$(( CPos[0] ))
FIRST_LINE=$(( LAST_LINE - NLINES ))

# set scroll area
tput csr $((FIRST_LINE-1)) $((LAST_LINE-1))

# move cursor to first line in scroll area
tput cup $FIRST_LINE 0

# execute command
"$@" 2>&1 | tee "${TMPFILE}"
STATUS=${PIPESTATUS[0]}

# check if command failed
if [ ${STATUS} -ne 0 ]; then
  # failed: output full log replacing the scroll area
  tput csr 0 $LINES
  tput cup $FIRST_LINE 0
  cat "${TMPFILE}"
else
  # succeeded: just keep last line of scroll area and continue with output below that line
  for (( i = 0; i < NLINES-1 ; i++)); do
    echo ""
  done
  tput csr 0 $((LINES-1))
  tput cup $FIRST_LINE 0
fi

rm -f "${TMPFILE}"

exit $STATUS
