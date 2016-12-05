dotfilebase=".dotfiles"

HISTFILE=~/.zhistory

# first source oh-my-zsh rc file
source $dotfilebase/zsh/ohmy.zshrc

# source own files
for config (~/$dotfilebase/zsh/*.zsh) source $config

