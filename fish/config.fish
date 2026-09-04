# ----- interactive-only config -----
if status is-interactive
    # Prompt
    starship init fish | source
    zoxide init fish | source
    fzf --fish | source
end

# Better pager
set -gx LESS "-R --use-color -Dd+r -Du+b"

# Editors
set -gx EDITOR nvim
set -gx VISUAL code

# ---- Aliases ----

# Git
alias gs="git status"
alias gl="git log --oneline --graph --decorate"
alias gpu="git pull"
alias gp="git push"
alias gpf="git push --force-with-lease"
alias ga="git add"
alias gc="git commit"

# Go
alias gom="go mod tidy"
alias got="go test ./..."
alias gor="go run ."
alias gof="go fmt ./..."
alias gob="go build ./..."

# System (Fedora-specific; kept as reference for this Arch system)
alias upg="sudo dnf upgrade -y"
alias upgr="sudo dnf upgrade --refresh -y"
alias upgc="sudo dnf upgrade --assumeno"
alias dsync="sudo dnf dsync --refresh && sudo dnf autoremove"
alias hist="sudo dnf history"
alias histi="sudo dnf history info"
alias dnfundo="sudo dnf history undo last"
alias dnfclean="sudo dnf clean all"

#System Arch
#alias upgr="sudo pacman -Syu"

alias duh="du -h --max-depth=1"
alias cls="clear"
alias cat="bat -P"
alias grep="rg"
alias find="fd"
alias f="fd | fzf"
alias fe="fd | fzf | xargs nvim"
alias se="rg --line-number . | fzf | cut -d: -f1,2 | sed 's/:/ +/' | xargs nvim"

function ls
    if test (count $argv) -eq 0
        eza --group-directories-first .
    else
        eza --group-directories-first $argv
    end
end

function tree
    if test (count $argv) -eq 0
        eza --tree .
    else
        eza --tree $argv
    end
end

# Functions
function mkcd
    mkdir -p $argv
    cd $argv
end

function cheatsheet
    cat /home/root-0/.config/fish/config.fish
end
