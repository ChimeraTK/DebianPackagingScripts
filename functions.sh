# SPDX-FileCopyrightText: Deutsches Elektronen-Synchrotron DESY, MSK, ChimeraTK Project <chimeratk-support@desy.de>
# SPDX-License-Identifier: LGPL-3.0-or-later

# Miscellaneous helper functions used across multiple scripts

# Get a config value from either the distribution-specific config override, if exists
# or the base config
# $1: base-path of the package config
# $2: current distribution codename
# $3: configuration key to get
getConfigValue() {
  _CONFIG="${1}/CONFIG"

  value=`sed -n "s/^${3}\s*:\s*//p" ${_CONFIG}.${2} 2>/dev/null`

  if [ -n "${value}" ]; then 
    echo ${value}
    return 0
  fi

  sed -n "s/^${3}\s*:\s*//p" ${_CONFIG}
}
