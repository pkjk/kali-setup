#!/bin/bash

# Error handling
set -o nounset
die() { echo "$@" 1>&2; exit 1; }

# Figure out our environment
ARCH=`uname -m`
KALI=`grep -ci kali /etc/debian_version`
X=`/usr/bin/dpkg-query -l xorg | grep -c '^ii'`

if [[ `id -u` -ne 0 ]] ; then
  die 'Must be executed as root.'
fi

# CD to current dir
if [[ $0 != "bash" ]] ; then
  cd `dirname $0`
fi

# Allow bootstrapping from just the script
if [[ ! -f packages ]] ; then
  echo "Packages not found, bootstrapping from GitHub."
  if [[ "/bin/which git" == "" ]] ; then
    echo "Git not found, trying to install."
    /usr/bin/apt-get --yes install git
  fi
  /usr/bin/git clone https://github.com/Matir/kali-setup
  if [[ $? -ne 0 ]] ; then die "Unable to clone repo." ; fi
  echo "Cloned, jumping to next bin."
  cd kali-setup
  exec ./kali-setup.sh
fi

PACKAGES=`cat packages`

# Add architecture-specific packages
if [[ -f "packages.${ARCH}" ]] ; then
  PACKAGES="${PACKAGES} `cat packages.${ARCH}`"
  if [[ $? -ne 0 ]] ; then die "Unable to source packages.${ARCH}." ; fi
fi

# Add packages only installed if we have an X server
if [[ "$X" -eq 1 && -f "packages.X" ]] ; then
  PACKAGES="${PACKAGES} `cat packages.X`"
  if [[ $? -ne 0 ]] ; then die "Unable to source packages.X." ; fi
fi

# If not Kali, make it Kali.
if [[ "$KALI" -ne 1 ]] ; then
  cp kali.list /etc/apt/sources.list.d/kali.list || \
    die "Could not copy kali.list"
  /usr/bin/apt-key add kali-repo.key || \
    die "Could not add kali-repo.key"
  PACKAGES="${PACKAGES} kali-linux-full"
fi

# Allow multiarch
if [[ "$ARCH" == "x86_64" ]] ; then
  /usr/bin/dpkg --add-architecture i386 || \
    die "Unable to add i386 architecture."
fi

# Update & install packages
/usr/bin/apt-get --yes update || \
  die "Could not apt-get update."
/usr/bin/apt-get --yes install ${PACKAGES} || \
  die "Could not install packages."
