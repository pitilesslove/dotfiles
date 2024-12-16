# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ~/.zshrc: Zsh configuration
# Set the directory we want to store zinit and plugins
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download Zinit, if it's not there yet
if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname $ZINIT_HOME)"
   git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Source/Load zinit
source "${ZINIT_HOME}/zinit.zsh"

# Add in Powerlevel10k
zinit ice depth=1; zinit light romkatv/powerlevel10k

# Add in zsh plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab

# Add in snippets
zinit snippet OMZL::git.zsh
zinit snippet OMZP::git
zinit snippet OMZP::sudo
zinit snippet OMZP::archlinux
zinit snippet OMZP::aws
zinit snippet OMZP::kubectl
zinit snippet OMZP::kubectx
zinit snippet OMZP::command-not-found

#Load completions
autoload -U compinit && compinit

zinit cdreplay -q

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# keybinding
bindkey -e
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward

# History settings
HISTCONTROL="ignoreboth"                   # 중복 및 공백으로 시작하는 명령어 무시 (Bash와 다르게 zsh에서는 무시됨)
HISTSIZE=5000                              # 히스토리 크기
SAVEHIST=$HISTSIZE                         # 히스토리 파일 크기
HISTFILE=~/.zsh_history
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# Check window size after each command
preexec() { eval $(resize > /dev/null 2>&1) }

# Enable "**" for recursive globbing
setopt EXTENDED_GLOB

# Make less more friendly for non-text input files
if [ -x /usr/bin/lesspipe ]; then
    eval "$(SHELL=/bin/sh lesspipe)"
fi

# Set the debian_chroot variable (if applicable)
if [[ -z "${debian_chroot:-}" && -r /etc/debian_chroot ]]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# Check if terminal supports colors
if [[ -x /usr/bin/tput ]] && tput setaf 1 &>/dev/null; then
    color_prompt=yes
else
    color_prompt=no
fi

# Set the prompt
if [[ "$color_prompt" == yes ]]; then
    PROMPT='%F{green}%n@%m%f:%F{blue}%~%f$ '
else
    PROMPT='%n@%m:%~$ '
fi

# Unset temporary variables
unset color_prompt


# Set a fancy prompt with colors
#autoload -Uz promptinit
#promptinit
#prompt theme robbyrussell

# Enable color support of ls and handy aliases
if [ -x /usr/bin/dircolors ]; then
    eval "$(dircolors -b ~/.dircolors 2>/dev/null || dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# Some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias c='clear'

# Add an "alert" alias for long running commands
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history | tail -n1 | sed -e "s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//")"'

# Load additional aliases from ~/.bash_aliases if it exists
if [ -f ~/.bash_aliases ]; then
#    source ~/.bash_aliases
fi

# Enable fzf completion features
if [ -f /usr/share/doc/fzf/examples/completion.zsh ]; then
    source /usr/share/doc/fzf/examples/completion.zsh
fi

export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border"
export FZF_COMPLETION_TRIGGER='**'
export FZF_DEFAULT_COMMAND='find . -type f'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='find . -type d'

# Custom aliases
alias selectJava="sudo update-alternatives --config java"
alias bd=". bd -si"
alias intellij="/opt/idea-IC-242.23726.103/bin/idea.sh"
export JASYPT_ENCRYPTOR_PASSWORD="Io9f7Ua8ua5A4fa3aFa33ACf211cc9e9"
alias datamodeler="/opt/datamodeler/datamodeler.sh"
alias k="kubectl"

alias note="eval \$(cat ~/note.txt | fzf --height 100%)"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

eval "$(zoxide init zsh)"
