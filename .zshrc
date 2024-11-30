# ~/.zshrc: Zsh configuration

[[ $- != *i* ]] && return

# History settings
HISTCONTROL="ignoreboth"                   # 중복 및 공백으로 시작하는 명령어 무시 (Bash와 다르게 zsh에서는 무시됨)
setopt APPEND_HISTORY                      # 히스토리 덮어쓰지 않고 추가
setopt INC_APPEND_HISTORY                  # 명령어를 실행 즉시 히스토리에 추가
setopt SHARE_HISTORY                       # 세션 간 히스토리 공유
HISTSIZE=1000                              # 히스토리 크기
SAVEHIST=2000                              # 히스토리 파일 크기

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
