# Add to path
# -----------
# Bin dir
export PATH=/Users/drholdaw/bin:$PATH
# Homebrew
export PATH=/Users/drholdaw/opt/homebrew/bin:$PATH

## Modules
## -------
source /Users/drholdaw/opt/homebrew/Cellar/lmod/8.7.4/init/zsh
export OPT=/Users/drholdaw/opt/
export MODULEPATH=$OPT/modulefiles

# History
# -------
export HISTFILESIZE=1000000
export HISTSIZE=1000000

# Python (Miniconda)
# ------------------
export PYTHONVER=3.9
export PYTHONMODPATHVER=python${PYTHONVER}
module load core/miniconda/${PYTHONVER}

# JEDI
# ----
cdir=`pwd`
cd /Users/drholdaw/OneDrive-NASA/
for f in Jedi*; do
  if [ -d "$f" ]; then
    export $f=/Users/drholdaw/OneDrive-NASA/$f
  fi
done
cd $cdir

module use -a /Users/drholdaw/Library/CloudStorage/OneDrive-NASA/JediOpt/modulefiles/core

# Better color in ls
# ------------------
export CLICOLOR=1

# Handy aliases
# -------------
alias gvi=/Users/drholdaw/Applications/MacVim.app/Contents/bin/mvim
alias duu='du -h --max-depth=1'
alias lss='ls -lhtr'
alias lsize='ls -lSh'
alias numfiles='find ./ -type f | wc -l'
alias hist='history -500'

# Discover
# --------
alias discover='ssh -XY discover'
alias ctunneldisc='python3 /Users/drholdaw/bin/tcluster.py -m discover'
alias ktunneldisc='python3 /Users/drholdaw/bin/tcluster.py -m discover -k'
alias ltunneldisc='python3 /Users/drholdaw/bin/tcluster.py -m discover -l'

alias mountnobackup='sshfs discover:/gpfsm/dnb31/drholdaw $HOME/Volumes/nobackup'
alias umountnobackup='umount $HOME/Volumes/nobackup'
alias forceumountnobackup='diskutil unmountDisk force $HOME/Volumes/nobackup'

alias mountdhome='sshfs discover:/gpfsm/dhome/drholdaw $HOME/Volumes/dhome'
alias umountdhome='umount $HOME/Volumes/dhome'
alias forceumountdhome='diskutil unmountDisk force $HOME/Volumes/dhome'

# NOAA Orion
# ----------
alias orion='ssh -XY orion'
alias ctunnelorion='python3 /Users/drholdaw/bin/tcluster.py -m orion'
alias ktunnelorion='python3 /Users/drholdaw/bin/tcluster.py -m orion -k'
alias ltunnelorion='python3 /Users/drholdaw/bin/tcluster.py -m orion -l'

alias mountorion='sshfs orion:/work/noaa/da/dholdawa/ $HOME/Volumes/orion'
alias umountorion='umount $HOME/Volumes/orion'
alias forceumountorion='diskutil unmountDisk force $HOME/Volumes/orion'
