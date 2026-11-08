alias ls="ls -G"

# [ -f "$HOME/.zsh/ai.zsh" ] && source "$HOME/.zsh/ai.zsh"

alias ll="ls -la"
alias hh="cd ~ && clear && pwd"
alias cfg="vim ~/.zshrc"
alias raiff="cd ~/projects/raiff && clear && pwd && ls -la"
alias apply="source ~/.zshrc"
alias n="nvim"
alias vim="nvim"
alias personal="cd ~/projects/personal && clear && pwd && ls -la"
alias l="less"
alias setpgit="~/projects/personal/scripts/set_git_config.sh"
alias ir="~/projects/personal/auto-rebase/auto-rebase.zsh"

aliases() {
  if [[ -f "$HOME/.zshrc" ]]; then
    echo "\n"
    grep -nE '^[[:space:]]*(alias[[:space:]]|function[[:space:]]|[[:alnum:]_-]+[[:space:]]*\([[:space:]]*\))' ~/.zshrc
    echo "\n"
  fi
}

ssh-config() {
  if [[ -f "$HOME/.ssh/config" ]]; then
    echo "\n"
    cat "$HOME/.ssh/config"    
    echo "\n"
  fi
}

autoload -U colors && colors
PS1='%F{green}%n@%m%f:%F{blue}%~%f %# '
eval "$(starship init zsh)"

