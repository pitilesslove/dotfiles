#!/usr/bin/env bash
# 00_zsh_install.sh
# 다양한 리눅스 배포판에서 zsh 환경을 안전하게 세팅하는 스크립트

set -Eeuo pipefail

# ----------------------------- 출력 도우미 -----------------------------
RED=$(printf '\033[31m'); GREEN=$(printf '\033[32m'); YELLOW=$(printf '\033[33m'); BLUE=$(printf '\033[34m'); RESET=$(printf '\033[0m')
info() { printf '%s %s\n' "${BLUE}[정보]${RESET}" "$*"; }
ok()   { printf '%s %s\n' "${GREEN}[완료]${RESET}" "$*"; }
warn() { printf '%s %s\n' "${YELLOW}[경고]${RESET}" "$*"; }
err()  { printf '%s %s\n' "${RED}[오류]${RESET}" "$*" >&2; }

on_error() {
  err "예기치 않은 오류가 발생했습니다. (line $1)"
  err "출력된 메시지를 확인하고 문제를 해결한 뒤 다시 실행하세요."
  exit 1
}
trap 'on_error $LINENO' ERR

need_cmd() { command -v "$1" >/dev/null 2>&1; }

# -------------------------- 환경 변수 기본값 ---------------------------
if [[ -z ${INSTALL_ZINIT+x} ]]; then INSTALL_ZINIT=1; fi    # zinit 설치 여부
if [[ -z ${INSTALL_PLUGINS+x} ]]; then INSTALL_PLUGINS=1; fi  # 플러그인 프리패치 여부
if [[ -z ${LINK_RC+x} ]]; then LINK_RC=1; fi              # .zshrc 심볼릭 링크 여부
if [[ -z ${WRITE_P10K+x} ]]; then WRITE_P10K=1; fi        # .p10k.zsh 생성 여부
_DO_CHSH_WAS_SET=0
if [[ -z ${DO_CHSH+x} ]]; then
  DO_CHSH=1
  _DO_CHSH_WAS_SET=0
else
  _DO_CHSH_WAS_SET=1
fi

# -------------------------- SUDO / 권한 확인 ---------------------------
SUDO=""
if [[ $(id -u) -ne 0 ]]; then
  if need_cmd sudo; then
    SUDO="sudo"
  else
    err "루트 권한이 아니므로 sudo 가 필요합니다."
    exit 1
  fi
fi

# -------------------------- 저장소 경로 탐지 --------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if need_cmd git && git -C "$SCRIPT_DIR" rev-parse --show-toplevel >/dev/null 2>&1; then
  REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
else
  REPO_ROOT="$SCRIPT_DIR"
fi
SRC_ZSHRC="$REPO_ROOT/.zshrc"
DEST_ZSHRC="$HOME/.zshrc"
if [[ ! -f "$SRC_ZSHRC" ]]; then
  err "리포지토리에서 .zshrc 파일을 찾을 수 없습니다: $SRC_ZSHRC"
  exit 1
fi

# -------------------------- 패키지 매니저 감지 -------------------------
PM=""
UPDATE_CMD=""
INSTALL_CMD=""
if need_cmd apt-get; then
  PM="apt"
  UPDATE_CMD="$SUDO apt-get update"
  INSTALL_CMD="$SUDO apt-get install -y"
elif need_cmd dnf; then
  PM="dnf"
  UPDATE_CMD="$SUDO dnf -y makecache"
  INSTALL_CMD="$SUDO dnf -y install"
elif need_cmd yum; then
  PM="yum"
  UPDATE_CMD="$SUDO yum -y makecache"
  INSTALL_CMD="$SUDO yum -y install"
elif need_cmd pacman; then
  PM="pacman"
  UPDATE_CMD="$SUDO pacman -Sy"
  INSTALL_CMD="$SUDO pacman -S --noconfirm --needed"
elif need_cmd zypper; then
  PM="zypper"
  UPDATE_CMD="$SUDO zypper refresh"
  INSTALL_CMD="$SUDO zypper install -y"
elif need_cmd apk; then
  PM="apk"
  UPDATE_CMD="$SUDO apk update"
  INSTALL_CMD="$SUDO apk add --no-cache"
else
  err "지원되지 않는 패키지 매니저입니다. apt/dnf/yum/pacman/zypper/apk 중 하나가 필요합니다."
  exit 1
fi
info "패키지 매니저: $PM"

# -------------------------- WSL 감지 후 chsh --------------------------
IS_WSL=0
if grep -qiE 'microsoft|wsl' /proc/version 2>/dev/null; then
  IS_WSL=1
fi
if [[ $IS_WSL -eq 1 && $_DO_CHSH_WAS_SET -eq 0 ]]; then
  warn "WSL 환경을 감지하여 chsh 기본 실행을 비활성화합니다. 필요 시 DO_CHSH=1 로 강제 실행하세요."
  DO_CHSH=0
fi

# ------------------------- 패키지 설치 -------------------------------
PKGS=(zsh git curl fzf ripgrep zoxide)
info "패키지 목록 갱신 중..."
eval "$UPDATE_CMD"
info "필수 패키지 설치: ${PKGS[*]}"
eval "$INSTALL_CMD ${PKGS[*]}"
if ! need_cmd zsh; then
  err "zsh 설치를 확인할 수 없습니다. 패키지 매니저 로그를 확인하세요."
  exit 1
fi
ok "zsh 설치 완료: $(zsh --version | head -n1)"

# ------------------------- zinit 설치 -----------------------------
ZINIT_HOME_DEFAULT="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
ZINIT_HOME="${ZINIT_HOME:-$ZINIT_HOME_DEFAULT}"
install_zinit() {
  if [[ "$INSTALL_ZINIT" != "1" ]]; then
    warn "환경 변수 INSTALL_ZINIT=0 으로 인해 zinit 설치를 건너뜁니다."
    return
  fi
  if [[ -d "$ZINIT_HOME/.git" ]]; then
    info "zinit 저장소가 이미 존재합니다: $ZINIT_HOME"
    return
  fi
  info "zinit 설치: $ZINIT_HOME"
  mkdir -p "$(dirname "$ZINIT_HOME")"
  git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
  ok "zinit 설치 완료"
}
install_zinit

# ------------------------- 플러그인 사전 설치 -----------------------------
PLUGIN_SUMMARY=()
preload_plugins() {
  if [[ "$INSTALL_PLUGINS" != "1" ]]; then
    warn "환경 변수 INSTALL_PLUGINS=0 으로 인해 플러그인 사전 설치를 생략합니다."
    return
  fi
  if [[ ! -d "$ZINIT_HOME" ]]; then
    warn "zinit 이 아직 설치되지 않아 플러그인을 직접 설치하지 않습니다. 다음 zsh 실행 시 자동으로 받아집니다."
    return
  fi
  local plugin_root="${ZINIT_HOME%/zinit.git}/plugins"
  declare -A PLUGIN_REPOS=(
    [zsh-users---zsh-autosuggestions]="https://github.com/zsh-users/zsh-autosuggestions.git"
    [zsh-users---zsh-syntax-highlighting]="https://github.com/zsh-users/zsh-syntax-highlighting.git"
    [zsh-users---zsh-completions]="https://github.com/zsh-users/zsh-completions.git"
    [romkatv---powerlevel10k]="https://github.com/romkatv/powerlevel10k.git"
  )
  declare -A PLUGIN_DESCS=(
    [zsh-users---zsh-autosuggestions]="명령 히스토리를 이용해 자동으로 추천합니다."
    [zsh-users---zsh-syntax-highlighting]="입력 중인 명령을 색상으로 하이라이트합니다."
    [zsh-users---zsh-completions]="추가 자동 완성 스크립트를 제공합니다."
    [romkatv---powerlevel10k]="Powerlevel10k 테마 엔진입니다."
  )
  mkdir -p "$plugin_root"
  for key in "${!PLUGIN_REPOS[@]}"; do
    local dest="$plugin_root/$key"
    if [[ -d "$dest/.git" ]]; then
      info "플러그인 업데이트: $key"
      git -C "$dest" pull --ff-only || warn "$key 저장소 업데이트 실패"
    else
      info "플러그인 설치: $key"
      git clone --depth=1 "${PLUGIN_REPOS[$key]}" "$dest"
    fi
    PLUGIN_SUMMARY+=("${key#*---}: ${PLUGIN_DESCS[$key]}")
  done
  ok "주요 zinit 플러그인을 미리 내려받았습니다."
}
preload_plugins

# ------------------------- Powerlevel10k 설정 -----------------------------
P10K_FILE="${P10K_FILE:-$HOME/.p10k.zsh}"
generate_p10k() {
  if [[ "$WRITE_P10K" != "1" ]]; then
    warn "환경 변수 WRITE_P10K=0 으로 인해 Powerlevel10k 설정 생성을 건너뜁니다."
    return
  fi
  local target="$P10K_FILE"
  local backup
  if [[ -f "$target" ]]; then
    backup="$target.bak.$(date +%Y%m%d_%H%M%S)"
    info "기존 Powerlevel10k 설정 백업: $backup"
    mv "$target" "$backup"
  fi
  cat <<'EOF' >"$target"
# Powerlevel10k 기본 설정 (Pure 스타일 기반)
# - 프롬프트 스타일: Pure
# - 임시 정보 위치: 오른쪽 프롬프트
# - 현재 시간 비표시
# - 2줄 프롬프트 & Sparse 간격
# - Transient Prompt 활성화

'builtin' 'local' '-a' 'p10k_config_opts'
[[ ! -o 'aliases'         ]] || p10k_config_opts+=('aliases')
[[ ! -o 'sh_glob'         ]] || p10k_config_opts+=('sh_glob')
[[ ! -o 'no_brace_expand' ]] || p10k_config_opts+=('no_brace_expand')
'builtin' 'setopt' 'no_aliases' 'no_sh_glob' 'brace_expand'

() {
  emulate -L zsh -o extended_glob

  unset -m '(POWERLEVEL9K_*|DEFAULT_USER)~POWERLEVEL9K_GITSTATUS_DIR'
  [[ $ZSH_VERSION == (5.<1->*|<6->.*) ]] || return

  local grey=242 red=1 yellow=3 blue=4 magenta=5 cyan=6 white=7

  typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(
    context
    dir
    vcs
    newline
    virtualenv
    prompt_char
  )

  typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(
    command_execution_time
    newline
  )

  typeset -g POWERLEVEL9K_BACKGROUND=
  typeset -g POWERLEVEL9K_{LEFT,RIGHT}_{LEFT,RIGHT}_WHITESPACE=
  typeset -g POWERLEVEL9K_{LEFT,RIGHT}_SUBSEGMENT_SEPARATOR=' '
  typeset -g POWERLEVEL9K_{LEFT,RIGHT}_SEGMENT_SEPARATOR=
  typeset -g POWERLEVEL9K_VISUAL_IDENTIFIER_EXPANSION=
  typeset -g POWERLEVEL9K_PROMPT_ADD_NEWLINE=true

  typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_{VIINS,VICMD,VIVIS}_FOREGROUND=$magenta
  typeset -g POWERLEVEL9K_PROMPT_CHAR_ERROR_{VIINS,VICMD,VIVIS}_FOREGROUND=$red
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VIINS_CONTENT_EXPANSION='❯'
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VICMD_CONTENT_EXPANSION='❮'
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VIVIS_CONTENT_EXPANSION='❮'
  typeset -g POWERLEVEL9K_PROMPT_CHAR_OVERWRITE_STATE=false

  typeset -g POWERLEVEL9K_VIRTUALENV_FOREGROUND=$grey
  typeset -g POWERLEVEL9K_VIRTUALENV_SHOW_PYTHON_VERSION=false
  typeset -g POWERLEVEL9K_VIRTUALENV_{LEFT,RIGHT}_DELIMITER=

  typeset -g POWERLEVEL9K_DIR_FOREGROUND=$blue
  typeset -g POWERLEVEL9K_CONTEXT_ROOT_TEMPLATE="%F{$white}%n%f%F{$grey}@%m%f"
  typeset -g POWERLEVEL9K_CONTEXT_TEMPLATE="%F{$grey}%n@%m%f"
  typeset -g POWERLEVEL9K_CONTEXT_{DEFAULT,SUDO}_CONTENT_EXPANSION=

  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_THRESHOLD=5
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_PRECISION=0
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_FORMAT='d h m s'
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_FOREGROUND=$yellow

  typeset -g POWERLEVEL9K_VCS_FOREGROUND=$grey
  typeset -g POWERLEVEL9K_VCS_LOADING_TEXT=
  typeset -g POWERLEVEL9K_VCS_MAX_SYNC_LATENCY_SECONDS=0
  typeset -g POWERLEVEL9K_VCS_{INCOMING,OUTGOING}_CHANGESFORMAT_FOREGROUND=$cyan
  typeset -g POWERLEVEL9K_VCS_GIT_HOOKS=(vcs-detect-changes git-untracked git-aheadbehind)
  typeset -g POWERLEVEL9K_VCS_BRANCH_ICON=
  typeset -g POWERLEVEL9K_VCS_COMMIT_ICON='@'
  typeset -g POWERLEVEL9K_VCS_{STAGED,UNSTAGED,UNTRACKED}_ICON=
  typeset -g POWERLEVEL9K_VCS_DIRTY_ICON='*'
  typeset -g POWERLEVEL9K_VCS_INCOMING_CHANGES_ICON=':⇣'
  typeset -g POWERLEVEL9K_VCS_OUTGOING_CHANGES_ICON=':⇡'
  typeset -g POWERLEVEL9K_VCS_{COMMITS_AHEAD,COMMITS_BEHIND}_MAX_NUM=1
  typeset -g POWERLEVEL9K_VCS_CONTENT_EXPANSION='${${${P9K_CONTENT/⇣* :⇡/⇣⇡}// }//:/ }'

  typeset -g POWERLEVEL9K_TIME_FOREGROUND=$grey
  typeset -g POWERLEVEL9K_TIME_FORMAT='%D{%H:%M:%S}'
  typeset -g POWERLEVEL9K_TIME_UPDATE_ON_COMMAND=false

  typeset -g POWERLEVEL9K_TRANSIENT_PROMPT=always
  typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet
  typeset -g POWERLEVEL9K_DISABLE_HOT_RELOAD=true

  (( ! $+functions[p10k] )) || p10k reload
}

typeset -g POWERLEVEL9K_CONFIG_FILE=${${(%):-%x}:a}

(( ${#p10k_config_opts} )) && setopt ${p10k_config_opts[@]}
'builtin' 'unset' 'p10k_config_opts'
EOF
  ok "Powerlevel10k 설정 생성: $target"
}
generate_p10k

# ------------------------- .zshrc 심볼릭 링크 ------------------------
link_zshrc() {
  if [[ "$LINK_RC" != "1" ]]; then
    warn "환경 변수 LINK_RC=0 으로 인해 .zshrc 링크를 건너뜁니다."
    return
  fi
  local src="$SRC_ZSHRC"
  local dest="$DEST_ZSHRC"
  if [[ -L "$dest" ]] && [[ $(readlink -f "$dest") == $(readlink -f "$src") ]]; then
    ok "~/.zshrc 가 이미 리포지토리 파일과 연결되어 있습니다."
    return
  fi
  if [[ -e "$dest" || -L "$dest" ]]; then
    local backup="$dest.bak.$(date +%Y%m%d_%H%M%S)"
    info "기존 ~/.zshrc 백업: $backup"
    mv -f "$dest" "$backup"
  fi
  ln -s "$src" "$dest"
  ok "~/.zshrc → $src 심볼릭 링크 생성"
}
link_zshrc

# ------------------------- 기본 셸 변경 ------------------------------
set_default_shell() {
  local target_shell
  target_shell="$(command -v zsh)"
  if [[ -z "$target_shell" ]]; then
    warn "zsh 바이너리를 찾을 수 없어 기본 셸을 변경하지 않습니다."
    return
  fi
  if [[ "$DO_CHSH" != "1" ]]; then
    warn "환경 변수 DO_CHSH=0 으로 인해 기본 셸 변경을 건너뜁니다."
    return
  fi
  local current_shell="${SHELL:-}"
  if [[ "$current_shell" == "$target_shell" ]]; then
    ok "이미 기본 셸이 zsh 입니다."
    return
  fi
  if ! need_cmd chsh; then
    warn "chsh 명령을 찾을 수 없습니다. 'chsh -s $target_shell' 를 수동으로 실행하세요."
    return
  fi
  info "기본 셸을 zsh로 변경합니다. (사용자: ${SUDO_USER:-$USER})"
  if [[ -n "$SUDO" && -n "${SUDO_USER:-}" ]]; then
    $SUDO chsh -s "$target_shell" "$SUDO_USER"
  else
    chsh -s "$target_shell" "$USER"
  fi
  ok "기본 셸 변경이 완료되었습니다."
}
set_default_shell

# ------------------------------ Summary ------------------------------
echo
ok "설치가 완료되었습니다!"
echo "요약"
echo "  - zsh 버전: $(zsh --version | head -n1)"
echo "  - zinit 경로: $ZINIT_HOME"
if [[ -f "$DEST_ZSHRC" ]]; then
  echo "  - ~/.zshrc 링크 대상: $(readlink -f "$DEST_ZSHRC")"
fi
if [[ -f "$P10K_FILE" ]]; then
  echo "  - Powerlevel10k 설정: $P10K_FILE"
fi
if [[ ${#PLUGIN_SUMMARY[@]} -gt 0 ]]; then
  echo "  - 사전 설치된 플러그인:"
  for desc in "${PLUGIN_SUMMARY[@]}"; do
    echo "      * $desc"
  done
fi
echo
info "새 터미널을 열거나 'exec zsh' 를 입력하면 변경 사항이 적용됩니다."
