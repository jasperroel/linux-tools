# Add the following line to your ~/.bash_profile
# source ~/linux-tools/bashrc

# Gids defaults
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

#Normal aliasses
alias ls="ls --color -St"
alias ll="ls -l"

#Nice aliasses
alias ns="netstat -aneep | grep -E '(LISTEN |udp )'"

# Jasper's i alias
[ -d "/var/www/htdocs" ] && IDIR="/var/www/htdocs"
[ -d "/var/www/websites" ] && IDIR="/var/www/websites"
[ -d "/etc/asterisk" ] && IDIR="/etc/asterisk"

alias i="cd $IDIR"

# Editors
export VISUAL="/usr/bin/vim"
export EDITOR="/usr/bin/vim"

# Apache dir discovery
[ -d "/etc/apache" ] && ADIR="/etc/apache"
[ -d "/etc/apache2" ] && ADIR="/etc/apache2"
[ -d "/etc/httpd" ] && ADIR="/etc/httpd"

[ -d "$ADIR/vhosts" ] && VDIR="$ADIR/vhosts"
[ -d "$ADIR/vhosts.d" ] && VDIR="$ADIR/vhosts.d"

# Apache configs
alias a="cd $ADIR"
alias ah="cd $VDIR"
alias av="vim $VDIR/virtualhosts.conf"

alias ac="vim $ADIR/httpd.conf"

# Bash history control
HISTCONTROL=ignoreboth

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize
