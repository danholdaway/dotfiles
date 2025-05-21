# Standard Path Items
# -------------------
# Other Path Items
export PATH=$HOME/bin:$PATH
export PATH=/Applications/MacVim.app/Contents/bin/:$PATH

# History
# -------
export HISTFILESIZE=1000000
export HISTSIZE=1000000

# Ready to use modules
source /opt/homebrew/opt/lmod/init/zsh
export MODULEPATH=$HOME/opt/modulefiles/core

# One Drive link
export ONE=$HOME/OneDrive-NASA

# JAVA
# ----
export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"

# HOMEBREW
# --------
export HOMEBREW_ROOT=/opt/homebrew
export PATH=$HOMEBREW_ROOT/bin:$PATH

# Better color in ls
# ------------------
export CLICOLOR=1

# Handy aliases
# -------------
alias duu='du -h --max-depth=1'
alias lss='ls -lhtr'
alias lsize='ls -lSh'
alias numfiles='find ./ -type f | wc -l'
alias hist='history -500'

# JCSDA Docker
# ------------
alias jedi_docker='docker run -u nonroot --rm -it -v /Users/noaa/Docker/shared_drive:/home/nonroot/shared jcsda/docker-clang-mpich-dev:latest'

# Meld
# ----
alias meld="open -W -a Meld $@"

# NOAA Hera
# ---------
grep -v '\[localhost\]:65445' $HOME/.ssh/known_hosts > $HOME/.ssh/known_hosts_nolh
mv $HOME/.ssh/known_hosts_nolh $HOME/.ssh/known_hosts

alias hera='ssh -vXYq heraLocal'
alias ctunnelhera='ssh -XYqL 65445:localhost:65445 hera'
alias ctunnelheraBoulder='ssh -XYqL 65445:localhost:65445 heraBoulder'


# NOAA Orion
# ----------
alias orion='ssh -XY orion'
alias ctunnelorion='ssh -YMNfq orion'
alias ktunnelorion='python $HOME/bin/tunnel_cluster.py -m orion -k'
alias ltunnelorion='python $HOME/bin/tunnel_cluster.py -m orion -l'

alias mountorion='sshfs orion:/work/noaa/da/dholdawa/ $HOME/Volumes/orion'
alias umountorion='diskutil unmountDisk force $HOME/Volumes/orion'

# NOAA Hercules
# -------------
alias hercules='ssh -XY hercules'
alias ctunnelhercules='ssh -YMNfq hercules'
alias ktunnelhercules='python $HOME/bin/tunnel_cluster.py -m hercules -k'
alias ltunnelhercules='python $HOME/bin/tunnel_cluster.py -m hercules -l'

alias mounthercules='sshfs hercules:/work/noaa/da/dholdawa/ $HOME/Volumes/hercules'
alias umounthercules='diskutil unmountDisk force $HOME/Volumes/hercules'
