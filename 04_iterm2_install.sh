#!/usr/bin/env bash
# 04_iterm2_install.sh
# iTerm2 설치 + Catppuccin Frappe 테마 자동 적용 (macOS 전용)

set -Eeuo pipefail

RED=$(printf '\033[31m'); GREEN=$(printf '\033[32m'); YELLOW=$(printf '\033[33m'); BLUE=$(printf '\033[34m'); RESET=$(printf '\033[0m')
info() { printf '%s %s\n' "${BLUE}[정보]${RESET}" "$*"; }
ok()   { printf '%s %s\n' "${GREEN}[완료]${RESET}" "$*"; }
warn() { printf '%s %s\n' "${YELLOW}[경고]${RESET}" "$*"; }
err()  { printf '%s %s\n' "${RED}[오류]${RESET}" "$*" >&2; }

if [[ "$(uname)" != "Darwin" ]]; then
  err "이 스크립트는 macOS에서만 실행할 수 있습니다."
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COLORS_FILE="$SCRIPT_DIR/iterm2/catppuccin-frappe.itermcolors"

if [[ ! -f "$COLORS_FILE" ]]; then
  err "컬러 프로파일을 찾을 수 없습니다: $COLORS_FILE"
  exit 1
fi

# -------------------- iTerm2 설치 --------------------
if [[ -d "/Applications/iTerm.app" ]]; then
  ok "iTerm2가 이미 설치되어 있습니다."
else
  if command -v brew >/dev/null 2>&1; then
    info "Homebrew로 iTerm2 설치 중..."
    brew install --cask iterm2
    ok "iTerm2 설치 완료"
  else
    err "Homebrew가 필요합니다. https://brew.sh 에서 설치 후 다시 실행하세요."
    exit 1
  fi
fi

# -------------------- 컬러 프로파일 임포트 --------------------
info "Catppuccin Frappe 컬러 프로파일 임포트 중..."
open "$COLORS_FILE"
sleep 2

# -------------------- 기본 프로파일에 테마 적용 --------------------
PLIST="$HOME/Library/Preferences/com.googlecode.iterm2.plist"

if [[ -f "$PLIST" ]]; then
  # 기본 프로파일의 컬러 프리셋을 Catppuccin Frappe로 설정
  /usr/libexec/PlistBuddy -c "Set ':New Bookmarks':0:'Normal Font' MesloLGS-NF-Regular 13" "$PLIST" 2>/dev/null || true

  info "iTerm2를 재시작하면 컬러 프로파일이 임포트됩니다."
  info "적용 방법: iTerm2 → Settings → Profiles → Colors → Color Presets → catppuccin-frappe 선택"
else
  warn "iTerm2 설정 파일이 없습니다. iTerm2를 한 번 실행한 후 다시 시도하세요."
fi

# -------------------- clipboard-provider 설치 --------------------
CLIP_SRC="$SCRIPT_DIR/iterm2/clipboard-provider"
CLIP_DST="$HOME/.local/bin/clipboard-provider"

if [[ -f "$CLIP_SRC" ]]; then
  mkdir -p "$HOME/.local/bin"
  cp "$CLIP_SRC" "$CLIP_DST"
  chmod +x "$CLIP_DST"
  ok "clipboard-provider 설치 완료: $CLIP_DST"

  # PATH에 ~/.local/bin 추가 확인
  if ! echo "$PATH" | tr ':' '\n' | grep -qx "$HOME/.local/bin"; then
    warn "~/.local/bin이 PATH에 없습니다. ~/.zshrc에 다음을 추가하세요:"
    echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
  fi
else
  warn "clipboard-provider 파일이 없습니다. 우분투에서만 필요하므로 무시해도 됩니다."
fi

echo
ok "iTerm2 설정 완료!"
echo "다음 단계:"
echo "  1. iTerm2 실행"
echo "  2. Settings(Cmd+,) → Profiles → Colors → Color Presets"
echo "  3. 'catppuccin-frappe' 선택"
echo "  4. SSH 접속 후 tmux에서 y 복사 → Cmd+V로 붙여넣기 확인"
