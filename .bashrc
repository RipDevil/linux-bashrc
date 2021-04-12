## show git branch ##

parse_git_branch() {
        git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
}

if [ "$color_prompt" = yes ]; then
 PS1='\[\033[01;33m\]\w\[\033[1;49;36m\] $(parse_git_branch)\[\033[00m\]\$ -> '
else
 PS1='\w$(parse_git_branch)\$ -> '
fi
# unset color_prompt force_color_prompt

## aliases ##

alias grb='gradle clean build'
alias grr='gradle bootRun'
alias gra='gradle clean build && gradle bootRun'
alias npi='npm install'
alias nps='npm start'
alias npt='npm test'
