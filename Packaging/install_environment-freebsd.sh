#!/bin/sh

# Determine color support

ECHO="printf %s\n "
ECHO_N="printf %s "

if [ -t 1 ] && command -v tput >/dev/null && tput colors >/dev/null 2>&1; then
    _NEXTSPACE_INSTALL_HAS_COLOR=1
    RED=$(tput setaf 1)
    GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 3)
    RESET=$(tput sgr0)
else
    RED="" GREEN="" YELLOW="" RESET=""
fi

ECHO_COLOR="printf %s%s${RESET}\n"
ECHO_N_COLOR="printf %s%s${RESET}"

# Prefer doas(1) to sudo(1)
#
if [ -e "/usr/local/etc/doas.conf" ]; then
	PRIV_CMD="doas"
else
	PRIV_CMD="sudo"
fi

MKDIR_CMD="$PRIV_CMD mkdir -p"
RM_CMD="$PRIV_CMD rm"
LN_CMD="$PRIV_CMD ln -sf"
MV_CMD="$PRIV_CMD mv -v"
CP_CMD="$PRIV_CMD cp -R"

RELEASE=0.95

setup_hosts()
{
    $ECHO_N "Checking /etc/hosts..."
    HOSTNAME="`hostname -s`"
    grep "$HOSTNAME" /etc/hosts 2>&1 > /dev/null
    if [ $? -eq 1 ];then
        if [ $HOSTNAME != `hostname` ];then
            HOSTNAME="$HOSTNAME `hostname`"
        fi
				$ECHO_COLOR $YELLOW yellow "configuring needed"
        $ECHO "Configuring hostname ($HOSTNAME)..."
        sed -i '' "/localhost.*domain/s/$/ $HOSTNAME/" /etc/hosts
    else
				$ECHO_COLOR $YELLOW green "good"
    fi
}

add_user()
{
		$ECHO_COLOR $YELLOW "Do you want to add user? [y/N]: "
    read YN
    if [ "$YN" = "y" ]; then
        $ECHO_N "Please enter username: "
        read USERNAME
        $ECHO "Adding username $USERNAME"
        $PRIV_CMD pw useradd $USERNAME  -G audio,wheel
        $ECHO "Setting up password..."
        $PRIV_CMD passwd $USERNAME
    else
        HAS_AUDIO=`groups | grep audio`
        if [ "$HAS_AUDIO" = "" ]; then
            $ECHO "WARNING: The user you're running this script as is not member of 'audio' group - sound will not work."
            $ECHO "         Consider adding $USER to group \"audio\" with command:"
            $ECHO "         $ $PRIV_CMD pw groupmod audio -m $USER"
        fi
    fi
}

setup_loginwindow()
{
  $ECHO_N_COLOR $YELLOW "Warning: "
  $ECHO_COLOR $RED "Configuration of login manager is unimplemented"
  $ECHO ""
  $ECHO "The author of this method doesn't use a display manager and doesn't know how to implement it."
  $ECHO ""
  $ECHO "Please write an implementation OR start Xorg manually with startx(1)"
}

