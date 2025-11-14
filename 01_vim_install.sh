#!/usr/bin/env bash
# 01_vim_install.sh
# Vundle 기반 Vim 환경을 자동 구성하는 스크립트 (한글 로그)

if [[ -z "${BASH_VERSION:-}" ]]; then
  printf '%s\n' "[오류] 이 스크립트는 bash 환경에서 실행해야 합니다. 'bash 01_vim_install.sh' 혹은 './01_vim_install.sh' 로 실행해 주세요." >&2
  return 1 2>/dev/null || exit 1
fi

set -Eeuo pipefail

# ----------------------------- 출력 도우미 -----------------------------
RED=$(printf '\033[31m'); GREEN=$(printf '\033[32m'); YELLOW=$(printf '\033[33m'); BLUE=$(printf '\033[34m'); RESET=$(printf '\033[0m')
info() { printf '%s %s\n' "${BLUE}[정보]${RESET}" "$*"; }
ok()   { printf '%s %s\n' "${GREEN}[완료]${RESET}" "$*"; }
warn() { printf '%s %s\n' "${YELLOW}[경고]${RESET}" "$*"; }
err()  { printf '%s %s\n' "${RED}[오류]${RESET}" "$*" >&2; }

on_error() {
  err "예기치 않은 오류가 발생했습니다. (line $1)"
  err "로그를 확인한 뒤 문제를 해결하고 다시 시도하세요."
  exit 1
}
trap 'on_error $LINENO' ERR

need_cmd() { command -v "$1" >/dev/null 2>&1; }

# -------------------------- 환경 변수 기본값 ---------------------------
if [[ -z ${INSTALL_VUNDLE+x} ]]; then INSTALL_VUNDLE=1; fi
if [[ -z ${INSTALL_PLUGINS+x} ]]; then INSTALL_PLUGINS=1; fi
if [[ -z ${LINK_VIMRC+x} ]]; then LINK_VIMRC=1; fi

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

# -------------------------- 경로 설정 -------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"
DOTFILES_DIR="$SCRIPT_DIR"
VIMRC_SOURCE="$DOTFILES_DIR/vim/.vimrc"
VIMRC_TARGET="$HOME/.vimrc"
VUNDLE_DIR="${VUNDLE_DIR:-$HOME/.vim/bundle/Vundle.vim}"
if [[ ! -f "$VIMRC_SOURCE" ]]; then
  err "리포지토리에서 vim/.vimrc 파일을 찾을 수 없습니다. 경로를 확인하세요."
  exit 1
fi

# -------------------------- 패키지 매니저 감지 -------------------------
PKG_MANAGER=""
UPDATE_CMD=""
INSTALL_CMD=""
CTAGS_PKG="ctags"
setup_package_commands() {
  if need_cmd apt-get; then
    PKG_MANAGER="apt"
    UPDATE_CMD="$SUDO apt-get update"
    INSTALL_CMD="$SUDO apt-get install -y"
    CTAGS_PKG="universal-ctags"
  elif need_cmd dnf; then
    PKG_MANAGER="dnf"
    UPDATE_CMD="$SUDO dnf -y makecache"
    INSTALL_CMD="$SUDO dnf -y install"
  elif need_cmd yum; then
    PKG_MANAGER="yum"
    UPDATE_CMD="$SUDO yum -y makecache"
    INSTALL_CMD="$SUDO yum -y install"
  elif need_cmd pacman; then
    PKG_MANAGER="pacman"
    UPDATE_CMD="$SUDO pacman -Sy"
    INSTALL_CMD="$SUDO pacman -S --noconfirm --needed"
  elif need_cmd zypper; then
    PKG_MANAGER="zypper"
    UPDATE_CMD="$SUDO zypper refresh"
    INSTALL_CMD="$SUDO zypper install -y"
  elif need_cmd apk; then
    PKG_MANAGER="apk"
    UPDATE_CMD="$SUDO apk update"
    INSTALL_CMD="$SUDO apk add --no-cache"
  elif need_cmd brew; then
    PKG_MANAGER="brew"
    UPDATE_CMD="brew update"
    INSTALL_CMD="brew install"
  else
    err "지원되지 않는 패키지 매니저입니다. apt/dnf/yum/pacman/zypper/apk/brew 중 하나가 필요합니다."
    exit 1
  fi
}
setup_package_commands
info "패키지 매니저: $PKG_MANAGER"

# -------------------------- 패키지 설치 -------------------------------
install_packages() {
  local packages=(vim git curl fzf ripgrep "$CTAGS_PKG")
  info "패키지 목록 갱신 중..."
  eval "$UPDATE_CMD"
  info "필수 패키지 설치: ${packages[*]}"
  eval "$INSTALL_CMD ${packages[*]}"
  need_cmd vim || { err "vim 설치 확인 실패"; exit 1; }
  need_cmd git || { err "git 설치 확인 실패"; exit 1; }
  need_cmd ctags || warn "ctags 명령을 찾을 수 없습니다. 패키지 이름을 수동으로 확인하세요."
}
install_packages
ok "Vim 및 필수 도구 설치 완료"

# -------------------------- .vimrc 링크 -------------------------------
link_vimrc() {
  if [[ "$LINK_VIMRC" != "1" ]]; then
    warn "환경 변수 LINK_VIMRC=0 으로 인해 ~/.vimrc 링크를 생략합니다."
    return
  fi
  if [[ -L "$VIMRC_TARGET" ]] && [[ $(readlink -f "$VIMRC_TARGET") == $(readlink -f "$VIMRC_SOURCE") ]]; then
    ok "~/.vimrc 가 이미 리포지토리 파일과 연결되어 있습니다."
    return
  fi
  if [[ -e "$VIMRC_TARGET" || -L "$VIMRC_TARGET" ]]; then
    local backup="$VIMRC_TARGET.bak.$(date +%Y%m%d_%H%M%S)"
    info "기존 ~/.vimrc 백업: $backup"
    mv -f "$VIMRC_TARGET" "$backup"
  fi
  ln -s "$VIMRC_SOURCE" "$VIMRC_TARGET"
  ok "~/.vimrc → $VIMRC_SOURCE 심볼릭 링크 생성"
}
link_vimrc

# -------------------------- Vundle 설치 -------------------------------
install_vundle() {
  if [[ "$INSTALL_VUNDLE" != "1" ]]; then
    warn "환경 변수 INSTALL_VUNDLE=0 으로 인해 Vundle 설치를 건너뜁니다."
    return
  fi
  if [[ -d "$VUNDLE_DIR/.git" ]]; then
    info "Vundle 디렉터리가 이미 존재합니다: $VUNDLE_DIR"
    return
  fi
  info "Vundle 설치: $VUNDLE_DIR"
  mkdir -p "$(dirname "$VUNDLE_DIR")"
  git clone https://github.com/VundleVim/Vundle.vim.git "$VUNDLE_DIR"
  ok "Vundle 설치 완료"
}
install_vundle

# -------------------------- 필수 색상 테마 사전 설치 -------------------
preinstall_colorscheme() {
  local solarized_dir="$HOME/.vim/bundle/vim-colors-solarized"
  if [[ -d "$solarized_dir/.git" ]]; then
    return
  fi
  info "Solarized 색상 테마를 미리 내려받습니다."
  mkdir -p "$(dirname "$solarized_dir")"
  git clone https://github.com/altercation/vim-colors-solarized.git "$solarized_dir"
  ok "Solarized 테마 준비 완료"
}
preinstall_colorscheme

# -------------------------- 플러그인 설치 -----------------------------
install_plugins() {
  if [[ "$INSTALL_PLUGINS" != "1" ]]; then
    warn "환경 변수 INSTALL_PLUGINS=0 으로 인해 플러그인 설치를 건너뜁니다."
    return
  fi
  if [[ ! -d "$VUNDLE_DIR" ]]; then
    warn "Vundle 디렉터리가 없어 플러그인 설치를 수행할 수 없습니다."
    return
  fi
  info "Vundle 플러그인 설치 (vim +PluginInstall)"
  if vim +'set nomore' +PluginInstall +qall </dev/null; then
    ok "플러그인 설치를 완료했습니다."
  else
    err "플러그인 설치 중 오류가 발생했습니다. 'vim +PluginInstall +qall' 명령을 직접 실행해 주세요."
    exit 1
  fi
}
install_plugins

# ------------------------------ Summary ------------------------------
PLUGIN_COUNT=$(find "$HOME/.vim/bundle" -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
[ -z "$PLUGIN_COUNT" ] && PLUGIN_COUNT=0

echo
ok "Vim 설정이 완료되었습니다!"
echo "요약"
echo "  - 사용된 패키지 매니저: $PKG_MANAGER"
echo "  - ~/.vimrc 링크: $( [[ -L $VIMRC_TARGET ]] && readlink -f "$VIMRC_TARGET" || echo '미생성')"
echo "  - Vundle 경로: $VUNDLE_DIR"
echo "  - 설치된 플러그인 디렉터리 수(대략): $PLUGIN_COUNT"
echo
info "'vim +PluginInstall +qall' 을 다시 실행하면 플러그인을 재설치할 수 있습니다."
