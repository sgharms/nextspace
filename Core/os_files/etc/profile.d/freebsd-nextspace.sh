### **FreeBSD** NextSpace additions to /etc/profile

#
# Paths
#
NS_PATH="/usr/local/NextSpace/bin:/usr/local/Library/bin:/usr/local/NextSpace/sbin:/usr/local/Library/sbin"
export PATH=$NS_PATH:$PATH
export MANPATH=:/usr/local/Library/Documentation/man:/usr/local/NextSpace/Documentation/man
# Only user home lib dir here. Others in /etc/ld.so.conf.d/nextspace.conf
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$HOME/Library/Libraries"
export GNUSTEP_PATHLIST="$HOME:/:/usr/local/NextSpace:/usr/local/Network"
export INFOPATH="$HOME/Library/Documentation/info:/usr/local/Library/Documentation/info:/usr/local/NextSpace/Documentation/info"

#
# Localization
#
# Initialize time zone to system time zone, but only if not yet set.
if [ -x /usr/local/Library/bin/defautls ];then
    defaults read NSGlobalDomain "Local Time Zone" 2>&1 > /dev/null
    if [ $? -ne 0 ]; then
        echo "Updating 'Local Time Zone' preference..."
        TZ=`/usr/bin/env -i stat --printf "%N\n" /etc/localtime |sed "s,.*-> '.*/zoneinfo/\([^']*\)',\1,"`
        defaults write NSGlobalDomain "Local Time Zone" $TZ
    fi
fi
export LC_CTYPE=$LANG

# Has been used in ~/,xinitrc - remove it?
export NS_SYSTEM="/usr/local/NextSpace"

#
# Log file
#
export USER=`whoami`
if [ ! -n "$UID" ];then
    export UID=`id -u`
fi
GS_SECURE="/tmp/GNUstepSecure"$UID
export LOGFILE="$GS_SECURE/console.log"
if [ ! -d $GS_SECURE ];then
    mkdir $GS_SECURE
    chmod 700 $GS_SECURE
fi
 
#
# ZSH: replace ~/.zshrc with NextSpace supplied version
#
if [ -n "$SHELL" -a "$SHELL" = "/bin/zsh" ]; then
    if [ -f ~/.zshrc.nextspace ]; then
        echo "Replacing .zshrc with .zshrc.nextspace"
        mv -f ~/.zshrc.nextspace ~/.zshrc
    fi
fi
