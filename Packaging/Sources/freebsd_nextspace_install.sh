#!/bin/sh -e
# It is a helper script for automated install of NEXTSPACE which has been built
# with scripts. Should be placed next to binary build hierarchy.

. ../install_environment-freebsd.sh
. ./freebsd.deps.sh
clear

#===============================================================================
# Main sequence
#===============================================================================

$ECHO_COLOR $(tput bold) "========================================================================="
$ECHO_COLOR $(tput bold) "This script will install NEXTSPACE release $RELEASE and configure system."
$ECHO_COLOR $(tput bold) "========================================================================="
$ECHO_COLOR $(tput bold) "Do you want to continue? [y/N]: "
read YN
if [ "$YN" != "y" ]; then
    $ECHO "OK, maybe next time. Exiting..."
    exit
fi

#===============================================================================
# Install dependency packages
#===============================================================================
$ECHO_COLOR $(tput bold) "========================================================================="
$ECHO_COLOR $(tput bold) "Installing system packages needed for NextSpace..."
$ECHO_COLOR $(tput bold) "========================================================================="
$PRIV_CMD pkg install ${RUNTIME_RUN_DEPS} ${WRASTER_RUN_DEPS} ${GNUSTEP_BASE_RUN_DEPS} \
              ${GNUSTEP_GUI_RUN_DEPS} ${BACK_ART_RUN_DEPS} ${FRAMEWORKS_RUN_DEPS} \
              ${APPS_RUN_DEPS} 2>&1 > /dev/null
$ECHO_COLOR $GREEN Done!
