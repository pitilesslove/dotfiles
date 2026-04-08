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

# -------------------- 중복 설치 정리 --------------------
# brew cask는 /Applications/에 설치 — ~/Applications/는 수동 설치 중복
if [[ -d "$HOME/Applications/iTerm.app" && -d "/Applications/iTerm.app" ]]; then
  warn "~/Applications/iTerm.app 중복 감지 — 제거 중..."
  rm -rf "$HOME/Applications/iTerm.app"
  ok "중복 제거 완료"
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

# -------------------- 기본 프로파일에 컬러 직접 적용 --------------------
PLIST="$HOME/Library/Preferences/com.googlecode.iterm2.plist"

apply_colors() {
  local plist="$1"
  local colors_file="$2"

  # iTerm2 실행 중이면 종료 후 적용 (설정이 덮어써지는 것 방지)
  if pgrep -x iTerm2 >/dev/null 2>&1; then
    info "iTerm2 종료 후 컬러 적용 중..."
    osascript -e 'tell application "iTerm2" to quit' 2>/dev/null || true
    sleep 2
  fi

  info "Catppuccin Frappe 컬러를 기본 프로파일에 직접 적용 중..."
  python3 - "$plist" "$colors_file" <<'PYEOF'
import sys, plistlib, subprocess

plist_path, colors_path = sys.argv[1], sys.argv[2]

with open(colors_path, 'rb') as f:
    colors = plistlib.load(f)

PB = '/usr/libexec/PlistBuddy'

def pb(*cmds):
    subprocess.run([PB, '-c', *cmds, plist_path], capture_output=True)

def pb_ok(*cmds):
    return subprocess.run([PB, '-c', *cmds, plist_path], capture_output=True).returncode == 0

for key, value in colors.items():
    if not isinstance(value, dict):
        continue
    profile_key = f":New Bookmarks:0:{key}"
    # 기존 키 삭제 후 재생성 (Add 실패 방지)
    pb(f"Delete '{profile_key}'")
    pb(f"Add '{profile_key}' dict")
    for comp, val in value.items():
        if isinstance(val, float):
            pb(f"Add '{profile_key}:{comp}' real {val}")
        elif isinstance(val, int):
            pb(f"Add '{profile_key}:{comp}' integer {val}")
        else:
            pb(f"Add '{profile_key}:{comp}' string {val}")

print("컬러 적용 완료")
PYEOF

  # 폰트 설정
  /usr/libexec/PlistBuddy -c "Set ':New Bookmarks':0:'Normal Font' MesloLGS-NF-Regular 13" "$plist" 2>/dev/null || true
  ok "Catppuccin Frappe 컬러 및 폰트 적용 완료"
}

if [[ -f "$PLIST" ]]; then
  apply_colors "$PLIST" "$COLORS_FILE"
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
ok "iTerm2 설정 완료! iTerm2를 실행하면 Catppuccin Frappe 테마가 적용됩니다."
echo "  SSH 접속 후 tmux에서 y 복사 → Cmd+V로 붙여넣기 확인"
