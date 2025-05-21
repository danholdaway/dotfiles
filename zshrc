# oh-my-zsh
# ---------
export ZSH="$HOME/opt/src/ohmyzsh/fork"
ZSH_THEME="robbyrussell-dan"
plugins=(git)
source $ZSH/oh-my-zsh.sh


# Homebrew (done here to make sure path is first)
# --------
export HOMEBREW_ROOT=/opt/homebrew
export PATH=$HOMEBREW_ROOT/bin:$PATH
