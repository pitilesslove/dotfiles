#!/usr/bin/env bash
# 02_nvim_install.sh
# LazyVim 기반 Neovim 환경을 자동 구성하는 스크립트 (한글 로그)
# - LazyVim: 기본 단축키(<leader>sf/sg 등)와 LSP/디버깅을 미리 구성한 스타터 템플릿입니다.
# - log-highlight.nvim: :LogHighlight 명령으로 로그 레벨/타임스탬프를 색상으로 구분해 가독성을 높입니다.
# - vim-tmux-navigator: <C-h/j/k/l>과 <C-\> 단축키로 tmux 창과 Neovim 분할창을 끊김 없이 이동합니다.

if [[ -z "${BASH_VERSION:-}" ]]; then
  printf '%s\n' "[오류] 이 스크립트는 bash 환경에서 실행해야 합니다. 'bash 02_nvim_install.sh' 형태로 실행해 주세요." >&2
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
if [[ -z ${INSTALL_NVIM_PACKAGES+x} ]]; then INSTALL_NVIM_PACKAGES=1; fi
if [[ -z ${LINK_NVIM+x} ]]; then LINK_NVIM=1; fi
if [[ -z ${SYNC_NVIM+x} ]]; then SYNC_NVIM=1; fi
if [[ -z ${NEOVIM_VERSION+x} ]]; then NEOVIM_VERSION="nightly"; fi

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
NVIM_SOURCE="$DOTFILES_DIR/nvim/.config/nvim"
NVIM_TARGET="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
if [[ ! -d "$NVIM_SOURCE" ]]; then
  err "리포지토리에서 nvim/.config/nvim 디렉터리를 찾을 수 없습니다."
  exit 1
fi

# -------------------------- 패키지 매니저 감지 -------------------------
PKG_MANAGER=""
UPDATE_CMD=""
INSTALL_CMD=""
setup_package_commands() {
  if need_cmd apt-get; then
    PKG_MANAGER="apt"
    UPDATE_CMD="$SUDO apt-get update"
    INSTALL_CMD="$SUDO apt-get install -y"
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
  if [[ "$INSTALL_NVIM_PACKAGES" != "1" ]]; then
    warn "환경 변수 INSTALL_NVIM_PACKAGES=0 으로 인해 Neovim 패키지 설치를 건너뜁니다."
    return
  fi
  local packages=(git curl ripgrep fzf unzip python3 python3-pip nodejs npm)
  case "$PKG_MANAGER" in
    apt)
      packages+=(fd-find)
      ;;
    dnf|yum|zypper)
      packages+=(fd-find)
      ;;
    pacman)
      packages+=(fd)
      ;;
    apk)
      packages+=(fd)
      ;;
    brew)
      packages+=(fd)
      ;;
  esac
  info "패키지 목록 갱신 중..."
  eval "$UPDATE_CMD"
  info "필수 패키지 설치: ${packages[*]}"
  eval "$INSTALL_CMD ${packages[*]}"
}
install_packages
ok "Neovim 의존 패키지 설치 완료"

# -------------------------- Neovim 최신 버전 설치 ----------------------
install_neovim_binary() {
  local version="$NEOVIM_VERSION"
  local tag
  local asset="nvim-linux64"
  if [[ "$version" == "nightly" ]]; then
    tag="nightly"
    asset="nvim-linux-x86_64"
  else
    tag="v${version}"
  fi
  local tarball="${asset}.tar.gz"
  local url="https://github.com/neovim/neovim/releases/download/${tag}/${tarball}"
  local tmpdir
  tmpdir="$(mktemp -d)"
  info "Neovim v${version} 바이너리를 다운로드합니다."
  if ! curl -fsSL "$url" -o "$tmpdir/nvim.tar.gz"; then
    err "Neovim v${version} 아카이브를 다운로드하지 못했습니다. URL을 확인하거나 NEOVIM_VERSION 값을 변경하세요."
    exit 1
  fi
  tar -xzf "$tmpdir/nvim.tar.gz" -C "$tmpdir"
  local extracted
  extracted="$(find "$tmpdir" -maxdepth 1 -type d -name 'nvim-*' -print | head -n1)"
  if [[ -z "$extracted" ]]; then
    err "다운로드한 Neovim 아카이브에서 디렉터리를 찾지 못했습니다."
    exit 1
  fi
  local install_dir="/usr/local/nvim"
  $SUDO rm -rf "$install_dir"
  $SUDO mv "$extracted" "$install_dir"
  $SUDO ln -sf "$install_dir/bin/nvim" /usr/local/bin/nvim
  rm -rf "$tmpdir"
  need_cmd nvim || { err "Neovim 명령을 찾을 수 없습니다."; exit 1; }
  local installed
  installed="$(nvim --version | head -n 1)"
  info "설치된 버전: $installed"
}
install_neovim_binary
ok "Neovim 본체 설치 완료"

# -------------------------- 설정 링크 -------------------------------
link_nvim_config() {
  if [[ "$LINK_NVIM" != "1" ]]; then
    warn "환경 변수 LINK_NVIM=0 으로 인해 Neovim 설정 링크를 건너뜁니다."
    return
  fi
  local target_dir="$NVIM_TARGET"
  local parent_dir="$(dirname "$target_dir")"
  mkdir -p "$parent_dir"
  if [[ -L "$target_dir" ]] && [[ $(readlink -f "$target_dir") == $(readlink -f "$NVIM_SOURCE") ]]; then
    ok "~/.config/nvim 이 이미 리포지토리 디렉터리와 연결되어 있습니다."
    return
  fi
  if [[ -e "$target_dir" || -L "$target_dir" ]]; then
    local backup="$target_dir.bak.$(date +%Y%m%d_%H%M%S)"
    info "기존 Neovim 설정 백업: $backup"
    mv "$target_dir" "$backup"
  fi
  ln -s "$NVIM_SOURCE" "$target_dir"
  ok "~/.config/nvim → $NVIM_SOURCE 심볼릭 링크 생성"
}
link_nvim_config

# -------------------------- Lazy.nvim 플러그인 동기화 ---------------
sync_lazy() {
  if [[ "$SYNC_NVIM" != "1" ]]; then
    warn "환경 변수 SYNC_NVIM=0 으로 인해 플러그인 동기화를 건너뜁니다."
    return
  fi
  if ! need_cmd nvim; then
    warn "nvim 명령을 찾을 수 없습니다. 패키지 설치 단계를 다시 확인하세요."
    return
  fi
  info "Lazy.nvim 플러그인 동기화 중... (nvim --headless +"Lazy! sync")"
  if nvim --headless "+Lazy! sync" +qa >/tmp/nvim_lazy_sync.log 2>&1; then
    ok "플러그인 동기화를 완료했습니다."
  else
    warn "플러그인 동기화 중 문제가 발생했습니다. /tmp/nvim_lazy_sync.log 파일을 확인하세요."
  fi
}
sync_lazy

# ------------------------------ Summary ------------------------------
PLUGIN_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/nvim"
PLUGIN_STATE="$(du -sh "$PLUGIN_DIR" 2>/dev/null | awk '{print $1" "$2}' || echo '미설치')"

echo
ok "Neovim 설정이 완료되었습니다!"
echo "요약"
echo "  - 사용된 패키지 매니저: $PKG_MANAGER"
echo "  - ~/.config/nvim 링크: $( [[ -L $NVIM_TARGET ]] && readlink -f "$NVIM_TARGET" || echo '미생성')"
echo "  - Lazy 상태 디렉터리 확인: $PLUGIN_STATE"
echo "  - 플러그인 로그: /tmp/nvim_lazy_sync.log (동기화 시 생성)"
echo
info "Neovim을 실행하고 <leader>l 로 Lazy 대시보드를 열어 상태를 확인할 수 있습니다."
