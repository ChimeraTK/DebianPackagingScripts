#!/bin/bash

#
# Provide bash completion for the master script. "source" this script in your .bashrc or so.
#

_debian_packaging_master_completions() {
  local suggestions=()
  nargs=$(( ${#COMP_WORDS[@]} - 1 ))

  # first argument: distribution code name
  if [ ${nargs} -eq 1 ]; then
    suggestions+=("focal")
    suggestions+=("noble")
    suggestions+=("bookworm")
  fi

  # even argument: package name
  if [ $(( nargs % 2 )) -eq 0 ]; then
    if [ -d DebianBuildVersions ]; then
      cd DebianBuildVersions
      for p in * ; do
        if [ "$p" != "README.md" ]; then
          suggestions+=("$p")
        fi
      done
      cd ..
    fi
  fi

  # odd argument (but not first): version: just offer "latest" for now
  if [ $nargs -gt 1 -a $(( nargs % 2 )) -eq 1 ]; then
    suggestions+=("latest")
  fi

  # filter non-matching suggestions if something has already been typed
  start=${COMP_WORDS[$((${#COMP_WORDS[@]}-1))]}
  for s in "${suggestions[@]}"; do
    if [[ "$s" == "${start}"* ]]; then
      COMPREPLY+=("$s")
    fi
  done

}

complete -F _debian_packaging_master_completions ./master
