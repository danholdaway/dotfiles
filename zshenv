# Add to path
# -----------
# Bin dir
export PATH=$HOME/bin:$PATH
# Homebrew
export PATH=$HOME/opt/core/homebrew/bin:$PATH
# Meld
export PATH=/Applications/Meld.app/Contents/MacOS:$PATH

# History
# -------
export HISTFILESIZE=1000000
export HISTSIZE=1000000

# Python (Miniconda)
# ------------------
export PATH=$HOME/opt/core/miniconda/py39/bin:$PATH
export PYTHONPATH=$HOME/opt/core/miniconda/py39/lib/python3.9:$PYTHONPATH

# Laptop stuff
# ------------
if [ "$HOST" = "gs6101-Exoniensis" ]; then
    # Ready to use modules
    source /Users/drholdaw/opt/core/homebrew/main/opt/lmod/init/zsh
    export MODULEPATH=$HOME/opt/modulefiles/core

    export OPT=/Users/drholdaw/opt/
fi



# Better color in ls
# ------------------
export CLICOLOR=1

# Handy aliases
# -------------
alias gvi=$HOME/Applications/MacVim.app/Contents/bin/mvim
alias duu='du -h --max-depth=1'
alias lss='ls -lhtr'
alias lsize='ls -lSh'
alias numfiles='find ./ -type f | wc -l'
alias hist='history -500'

# Discover
# --------
alias discover='ssh -XY discover'
alias ctunneldisc='python $HOME/bin/tunnel_cluster.py -m discover'
alias ktunneldisc='python $HOME/bin/tunnel_cluster.py -m discover -k'
alias ltunneldisc='python $HOME/bin/tunnel_cluster.py -m discover -l'

alias mountnobackup='sshfs discover:/discover/nobackup/drholdaw/ $HOME/Volumes/nobackup'
alias umountnobackup='diskutil unmountDisk force $HOME/Volumes/nobackup'

alias mountdhome='sshfs discover:/discover/home/drholdaw/ $HOME/Volumes/dhome'
alias umountdhome='diskutil unmountDisk force $HOME/Volumes/dhome'

# NOAA Orion
# ----------
alias orion='ssh -XY orion'
alias ctunnelorion='python $HOME/bin/tunnel_cluster.py -m orion'
alias ktunnelorion='python $HOME/bin/tunnel_cluster.py -m orion -k'
alias ltunnelorion='python $HOME/bin/tunnel_cluster.py -m orion -l'

alias mountorion='sshfs orion:/work/noaa/da/dholdawa/ $HOME/Volumes/orion'
alias umountorion='diskutil unmountDisk force $HOME/Volumes/orion'
