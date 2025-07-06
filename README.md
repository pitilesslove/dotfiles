
# 🛠️ 개발 환경 구성 (Dotfiles)

## 🧩 주요 구성 요소

- **쉘 (Shell)**: Zsh with zinit, Powerlevel10k  
- **터미널 멀티플렉서**: Tmux with Catppuccin theme, TPM  
- **에디터 (Modern)**: Neovim with LazyVim  
- **에디터 (Classic)**: Vim with Vundle  

---

## 🚀 설치 방법

### 1. 사전 준비물 설치

이 설정을 사용하기 위해 아래 프로그램들이 먼저 설치되어 있어야 합니다.

- **필수**: `git`, `zsh`, `tmux`, `neovim (nvim)`
- **권장**: `build-essential`, `curl`, `fzf`, `ripgrep`

#### Ubuntu/Debian

```bash
sudo apt update
sudo apt install -y git zsh tmux neovim build-essential curl fzf ripgrep
```

#### macOS (Homebrew)

```bash
brew install git zsh tmux neovim fzf ripgrep
```

---

### 2. 저장소 클론

```bash
git clone <당신의-dotfiles-저장소-URL> ~/dotfiles
```

---

### 3. 심볼릭 링크 생성

> 기존 설정이 있다면 백업 후 진행하세요.

```bash
# Zsh 설정
ln -s ~/dotfiles/.zshrc ~/.zshrc

# Tmux 설정
mkdir -p ~/.config
ln -s ~/dotfiles/tmux/.config/tmux ~/.config/tmux

# Neovim 설정
ln -s ~/dotfiles/nvim/.config/nvim ~/.config/nvim

# Vim 설정
ln -s ~/dotfiles/vim/.vimrc ~/.vimrc
```

---

### 4. 플러그인 설치

#### Zsh (zinit)

- 새로운 Zsh 터미널을 열면 자동 설치됩니다.

#### Tmux (TPM)

```bash
git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm
```

- Tmux 실행 후, `Ctrl+s` → `Shift+I` 입력

#### Neovim (Lazy.nvim)

- `nvim` 실행 시 자동 설치됩니다.

#### Vim (Vundle)

- `vim` 실행 후 `:PluginInstall` 명령 실행

---

### 5. 마무리

```bash
exec zsh
```

---

## 🔧 주요 기능 및 사용법

### Zsh (.zshrc)

- **Powerlevel10k**: Git 상태, 경로 등을 시각적으로 보여주는 프롬프트 (`p10k configure`)
- **자동 완성**: `zsh-autosuggestions`
- **문법 하이라이팅**: `zsh-syntax-highlighting`
- **FZF 탭 완성**: `fzf-tab`

---

### Tmux (.tmux.conf)

- **Prefix 키**: `Ctrl+s`
- **상태바**: Catppuccin 테마, 시스템 상태 정보 표시
- **Neovim 연동**: `vim-tmux-navigator`

#### 주요 단축키

| 키 조합         | 기능            |
|----------------|-----------------|
| `Ctrl+s + |`   | 수직 분할       |
| `Ctrl+s + -`   | 수평 분할       |
| `Ctrl+s + HJKL`| 창 크기 조절    |
| `Ctrl+s + I`   | 플러그인 설치   |

---

### Neovim (nvim/)

- **LazyVim** 기반 구성
- **log-highlight.nvim** 지원
- LSP, 자동완성, 파일탐색기 등 내장
- 플러그인 확장: `lua/plugins/*.lua` 추가

---

### Vim (.vimrc)

- **Vundle** 기반 플러그인 관리
- **단축키**
  - `<F9>`: NERDTree
  - `<F7>`: Tagbar
  - `<F8>`: SrcExpl

> Neovim 사용을 권장합니다.

---

## 📜 라이선스

이 프로젝트는 MIT License를 따릅니다.
