alias ls="ls -G"

# [ -f "$HOME/.zsh/ai.zsh" ] && source "$HOME/.zsh/ai.zsh"

alias ll="ls -la"
alias hh="cd ~ && clear && pwd"
alias cfg="vim ~/.zshrc"
alias aliases="cat ~/.zshrc | grep alias"
alias raiff="cd ~/projects/raiff && clear && pwd && ls -la"
alias apply="source ~/.zshrc"
alias n="nvim"
alias vim="nvim"
alias personal="cd ~/projects/personal && clear && pwd && ls -la"
alias l="less"
alias setpgit="~/projects/personal/scripts/set_git_config.sh"
alias ir="~/projects/personal/auto-rebase/auto-rebase.zsh"

autoload -U colors && colors
PS1='%F{green}%n@%m%f:%F{blue}%~%f %# '
