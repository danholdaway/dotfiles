# Add to path
# -----------
# Bin dir
export PATH=$HOME/bin:$PATH
# Homebrew
export PATH=/opt/homebrew/bin:$PATH
# Meld
export PATH=/Applications/Meld.app/Contents/MacOS:$PATH
# MacVim
export PATH=/Applications/MacVim.app/Contents/bin/:$PATH

# History
# -------
export HISTFILESIZE=1000000
export HISTSIZE=1000000

# Python (miniconda)
export PATH=$HOME/opt/core/miniconda/latest/bin:$PATH
export PYTHONPATH=$HOME/opt/core/miniconda/latest/lib/python3.11:$PYTHONPATH

# Ready to use modules
source /opt/homebrew/opt/lmod/init/zsh
export MODULEPATH=$HOME/opt/modulefiles/core

# One Drive link
export ONE=$HOME/OneDrive-NASA

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

# NOAA Hera
# ---------
alias hera='ssh -XYq heraLocal'
alias ctunnelhera='ssh -XYqL 65445:localhost:65445 hera'

# NOAA Orion
# ----------
#alias orion='ssh -XY orion'
alias ctunnelorion='ssh -YMNfq orion'
alias ktunnelorion='python $HOME/bin/tunnel_cluster.py -m orion -k'
alias ltunnelorion='python $HOME/bin/tunnel_cluster.py -m orion -l'

alias mountorion='sshfs orion:/work/noaa/da/dholdawa/ $HOME/Volumes/orion'
alias umountorion='diskutil unmountDisk force $HOME/Volumes/orion'
