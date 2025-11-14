#!/usr/bin/env bash
# 03_tmux_install.sh
# TPM + Catppuccin 테마 + 주요 플러그인을 포함한 tmux 환경 자동 구성 스크립트

if [[ -z "${BASH_VERSION:-}" ]]; then
  printf '%s\n' "[오류] 이 스크립트는 bash 환경에서 실행해야 합니다. 'bash 03_tmux_install.sh' 형태로 실행해 주세요." >&2
  return 1 2>/dev/null || exit 1
fi

set -Eeuo pipefail

# ----------------------------- 출력 도우미 -----------------------------
RED=$(printf '\033[31m'); GREEN=$(printf '\033[32m'); YELLOW=$(printf '\033[33m'); BLUE=$(printf '\033[34m'); RESET=$(printf '\033[0m')
info() { printf '%s %s\n' "${BLUE}[정보]${RESET}" "$*"; }
ok()   { printf '%s %s\n' "${GREEN}[완료]${RESET}" "$*"; }
warn() { printf '%s %s\n' "${YELLOW}[경고]${RESET}" "$*"; }
err()  { printf '%s %s\n' "${RED}[오류]${RESET}" "$*" >&2; }

trap 'err "예기치 않은 오류가 발생했습니다. (line $LINENO)"; err "로그를 확인한 뒤 문제를 해결하고 다시 시도하세요."; exit 1' ERR

need_cmd() { command -v "$1" >/dev/null 2>&1; }

# -------------------------- 환경 변수 기본값 ---------------------------
if [[ -z ${INSTALL_TMUX_PACKAGES+x} ]]; then INSTALL_TMUX_PACKAGES=1; fi
if [[ -z ${LINK_TMUX_CONF+x} ]]; then LINK_TMUX_CONF=1; fi
if [[ -z ${INSTALL_TMUX_PLUGINS+x} ]]; then INSTALL_TMUX_PLUGINS=1; fi

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
TMUX_CONF_SOURCE="$DOTFILES_DIR/tmux/.tmux.conf"
TMUX_CONF_TARGET="$HOME/.tmux.conf"
TMUX_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/tmux"
TMUX_PLUGIN_DIR="$TMUX_CONFIG_DIR/plugins"

if [[ ! -f "$TMUX_CONF_SOURCE" ]]; then
  err "tmux/.tmux.conf 파일을 찾을 수 없습니다."
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

# -------------------------- 필수 패키지 설치 ---------------------------
install_packages() {
  if [[ "$INSTALL_TMUX_PACKAGES" != "1" ]]; then
    warn "INSTALL_TMUX_PACKAGES=0 으로 인해 패키지 설치를 건너뜁니다."
    return
  fi
  local packages=(tmux git curl xclip yq)
  info "패키지 목록 갱신 중..."
  eval "$UPDATE_CMD"
  info "필수 패키지 설치: ${packages[*]}"
  eval "$INSTALL_CMD ${packages[*]}"
  need_cmd tmux || { err "tmux 설치 확인 실패"; exit 1; }
  need_cmd yq || warn "yq 명령을 찾을 수 없습니다. Catppuccin 테마에서 일부 기능이 비활성화될 수 있습니다."
}
install_packages
ok "tmux 관련 패키지 설치 완료"

if ! need_cmd zsh; then
  warn "zsh 바이너리를 찾을 수 없습니다. ~/.tmux.conf 는 /usr/bin/zsh 를 기본 셸로 지정하므로 zsh 설치 후 다시 실행해 주세요."
fi

# -------------------------- .tmux.conf 연결 ---------------------------
link_tmux_conf() {
  if [[ "$LINK_TMUX_CONF" != "1" ]]; then
    warn "LINK_TMUX_CONF=0 으로 인해 ~/.tmux.conf 링크를 건너뜁니다."
    return
  fi
  if [[ -L "$TMUX_CONF_TARGET" ]] && [[ $(readlink -f "$TMUX_CONF_TARGET") == $(readlink -f "$TMUX_CONF_SOURCE") ]]; then
    ok "~/.tmux.conf 가 이미 리포지토리 파일과 연결되어 있습니다."
    return
  fi
  if [[ -e "$TMUX_CONF_TARGET" || -L "$TMUX_CONF_TARGET" ]]; then
    local backup="$TMUX_CONF_TARGET.bak.$(date +%Y%m%d_%H%M%S)"
    info "기존 ~/.tmux.conf 백업: $backup"
    mv -f "$TMUX_CONF_TARGET" "$backup"
  fi
  ln -s "$TMUX_CONF_SOURCE" "$TMUX_CONF_TARGET"
  ok "~/.tmux.conf → $TMUX_CONF_SOURCE 심볼릭 링크 생성"
}
link_tmux_conf

# -------------------------- 플러그인 설치 -----------------------------
deploy_plugin() {
  local name="$1"
  local repo="$2"
  local dest="$TMUX_PLUGIN_DIR/$name"
  local local_src="$DOTFILES_DIR/tmux/.config/tmux/plugins/$name"

  if [[ -d "$local_src" ]]; then
    if [[ -n $(find "$local_src" -mindepth 1 -print -quit 2>/dev/null) ]]; then
      info "플러그인 복사(로컬): $name"
      rm -rf "$dest"
      mkdir -p "$TMUX_PLUGIN_DIR"
      cp -a "$local_src" "$dest"
      return
    fi
  fi

  if [[ -d "$dest/.git" ]]; then
    info "플러그인 업데이트: $name"
    if ! git -C "$dest" pull --ff-only; then
      warn "$name 저장소 업데이트 실패. 수동으로 확인하세요."
    fi
  else
    rm -rf "$dest"
    info "플러그인 설치: $name"
    git clone --depth 1 "https://github.com/$repo.git" "$dest"
  fi
}

install_tmux_plugins() {
  if [[ "$INSTALL_TMUX_PLUGINS" != "1" ]]; then
    warn "INSTALL_TMUX_PLUGINS=0 으로 인해 플러그인 설치를 건너뜁니다."
    return
  fi
  mkdir -p "$TMUX_PLUGIN_DIR"
  declare -A PLUGINS=(
    [catppuccin]="catppuccin/tmux"
    [tmux-cpu]="tmux-plugins/tmux-cpu"
    [tmux-nerd-font-window-name]="joshmedeski/tmux-nerd-font-window-name"
    [tmux-online-status]="tmux-plugins/tmux-online-status"
    [tmux-battery]="tmux-plugins/tmux-battery"
    [tmux-primary-ip]="dreknix/tmux-primary-ip"
    [tpm]="tmux-plugins/tpm"
    [tmux-sensible]="tmux-plugins/tmux-sensible"
    [vim-tmux-navigator]="christoomey/vim-tmux-navigator"
    [tmux-yank]="tmux-plugins/tmux-yank"
    [tmux-logging]="tmux-plugins/tmux-logging"
  )
  for name in "${!PLUGINS[@]}"; do
    deploy_plugin "$name" "${PLUGINS[$name]}"
  done
  ok "tmux 플러그인 설치/업데이트 완료"
}
install_tmux_plugins

# ------------------------------ Summary ------------------------------
PLUGIN_COUNT=$(find "$TMUX_PLUGIN_DIR" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
[ -z "$PLUGIN_COUNT" ] && PLUGIN_COUNT=0

echo
ok "tmux 설정이 완료되었습니다!"
echo "요약"
echo "  - ~/.tmux.conf 링크: $( [[ -L $TMUX_CONF_TARGET ]] && readlink -f "$TMUX_CONF_TARGET" || echo '미생성')"
echo "  - 플러그인 디렉터리: $TMUX_PLUGIN_DIR"
echo "  - 설치된 플러그인 수: $PLUGIN_COUNT"
echo
info "tmux 를 실행한 뒤 Prefix(C-s) + r 로 설정을 리로드하고, Prefix + I(TPM 기본 단축키)로 플러그인을 재설치할 수 있습니다."
