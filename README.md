# 🛠️ Dotfiles 안내서

안녕하세요! 이 저장소는 **00_zsh_install.sh → 01_vim_install.sh → 02_nvim_install.sh** 순서로 실행되는 스크립트를 통해 개발 환경을 안전하게 구성하도록 만들어졌습니다. 각 스크립트는 필요한 패키지 설치, 설정 파일 백업 및 링크, 플러그인 동기화까지 자동으로 처리하므로 안심하고 사용하셔도 됩니다.

---

## 🚀 빠른 시작

```bash
git clone <your-dotfiles-url> ~/dotfiles
cd ~/dotfiles

# 1. Zsh 환경
./00_zsh_install.sh

# 2. Vim 환경
./01_vim_install.sh

# 3. Neovim/LazyVim 환경
./02_nvim_install.sh
```

> **Tip**: 모든 스크립트는 Bash 전용입니다. 오류가 보이면 `bash ./스크립트.sh` 형태로 실행하세요.

---

## 🌀 Zsh 환경 (00_zsh_install.sh)

스크립트는 zinit, Powerlevel10k, 다양한 플러그인을 설치하고 `.zshrc`를 링크합니다. 필요한 패키지가 없으면 자동으로 설치하며, 기존 설정은 `*.bak.YYYYMMDD_HHMMSS`로 백업합니다.

### 주요 플러그인 & 사용법

- **Powerlevel10k** – Pure 스타일 프롬프트를 즉시 사용합니다. 상태바가 이상하면 `p10k configure`로 취향에 맞게 다시 설정하세요.
- **zsh-autosuggestions** – 입력 중인 명령 오른쪽에 흐린 색상으로 추천이 나타납니다. `Ctrl+E`나 `→`로 채택하세요.
- **zsh-syntax-highlighting** – 명령어, 옵션, 경로 등을 색상으로 구분해 오타를 빠르게 발견할 수 있습니다.
- **zsh-completions** – 기본 완성 외에 git, brew, kubectl 등 다수의 추가 완성을 제공합니다.
- **fzf-tab** – `Tab`을 눌렀을 때 FZF 인터페이스가 열립니다. 후보를 미리 보고 선택할 수 있어 긴 디렉터리 목록 탐색에 유용합니다.
- **OMZ snippets (git/sudo/aws/kubectl 등)** – oh-my-zsh의 자주 쓰는 alias와 함수가 추가되어 `gst`, `kctx` 같은 단축 명령을 그대로 사용할 수 있습니다.

### 자주 묻는 질문

- **기본 셸이 바뀌지 않나요?** WSL처럼 `chsh`가 제한된 환경에서는 스크립트가 경고만 출력합니다. `chsh -s $(command -v zsh)`를 수동 실행하세요.
- **설치가 실패했어요** `/tmp/zsh_install.log`(Docker 테스트 시) 또는 터미널 로그에 패키지 설치 실패 원인이 기록됩니다. 부족한 저장 공간이나 DNS 문제인지 확인해 주세요.

---

## ✏️ Vim 환경 (01_vim_install.sh)

이 스크립트는 `~/.vimrc`를 링크하고 Vundle + 플러그인 풀셋을 설치합니다. `Solarized` 테마를 미리 내려받아 `colorscheme solarized`에서 더 이상 오류가 나지 않습니다.

### 플러그인 한눈에 보기

- **vim-airline (+ themes)** – 탭/상태바를 꾸며주며 Git 상태, 현재 모드 등을 표시합니다.
- **gruvbox & Solarized** – `:colorscheme gruvbox` 또는 `:colorscheme solarized`로 쉽게 전환 가능합니다.
- **ctrlp.vim** – `<Ctrl+p>`로 프로젝트 내 파일을 빠르게 검색합니다. `*` 패턴이나 경로 일부만 입력해도 됩니다.
- **vim-fugitive** – `:Gstatus`, `:Gdiffsplit` 등 Vim 안에서 Git 작업을 수행할 수 있습니다.
- **NERDTree** – `<F9>`로 파일 트리를 열고 닫습니다. `m`키로 파일 생성/삭제를 수행할 수 있습니다.
- **Tagbar** – `<F7>`로 현재 파일의 함수/클래스 목록을 우측에 표시합니다. `ctags`가 자동 설치되어 있어 바로 사용할 수 있습니다.
- **BufExplorer** – `<F6>`으로 열려 있는 버퍼 목록을 선택하여 전환합니다.
- **DirDiff** – `:DirDiff` 명령으로 두 디렉터리를 비교할 수 있는 GUI를 제공합니다.
- **SrcExpl** – `<F8>`로 Source Explorer 패널을 띄워 심볼 정의/참조를 빠르게 점프합니다.
- **fzf / fzf.vim** – `:Files`, `:Rg` 등 fzf 기반 검색 명령을 사용할 수 있습니다.
- **vim-tmux-navigator** – `Ctrl+h/j/k/l`로 Vim 창과 tmux pane을 끊김 없이 이동합니다.
- **vim-log-highlighting** – `:LogHighlight` 수행 후 log 파일에서 ERROR/WARN/INFO를 색상으로 구분합니다.

### 추가 단축키 요약

- 버퍼 이동: `,x`(다음), `,z`(이전), `,w`(현재 닫기) 등 `,` 조합.
- TagList: `<F7>`, Source Explorer: `<F8>`, NERDTree: `<F9>`.
- 창 크기 조절: `Shift+H/J/K/L`.

---

## 💤 Neovim & LazyVim (02_nvim_install.sh)

LazyVim이 포함된 `nvim/.config/nvim` 디렉터리를 `~/.config/nvim`에 링크합니다. Neovim, Node.js, Python 등 LazyVim이 의존하는 런타임을 설치하고 `nvim --headless "+Lazy! sync"`로 모든 플러그인을 사전 동기화합니다.

### 포함된 주요 확장

- **LazyVim 기본 구성** – Telescope, Treesitter, LSP, Mason, Auto-complete 전부 기본 포함입니다. `<leader>` 키는 기본으로 `Space`이며 `<leader>s f` 등 단축키를 Lazy 대시보드(`Space` + `l`)에서 확인하세요.
- **log-highlight.nvim** – `:LogHighlight` 실행 후 로그 파일에서 레벨별로 색상이 적용됩니다. 긴 시스템 로그를 분석할 때 매우 유용합니다.
- **vim-tmux-navigator** – Vim과 동일하게 `Ctrl+h/j/k/l`, `Ctrl+\`로 tmux pane을 이동합니다. 일반 모드뿐 아니라 insert/terminal 모드에서도 동작하도록 설정됩니다.

### 사용 팁

- **플러그인 동기화 재실행**: `nvim --headless "+Lazy! sync" +qa` 또는 Neovim 안에서 `:Lazy sync`를 실행하세요.
- **로그 확인**: 동기화가 실패하면 `/tmp/nvim_lazy_sync.log`에서 원인을 확인할 수 있습니다.
- **추가 플러그인**: `nvim/.config/nvim/lua/plugins/`에 Lua 파일을 추가하면 Lazy.nvim이 자동으로 인식합니다.

---

## ⌗ tmux 환경 (03_tmux_install.sh)

`03_tmux_install.sh`는 tmux, xclip, yq 등 필요한 의존성을 설치하고 `~/.tmux.conf`를 링크한 뒤 수동으로 다운로드하기 번거로운 플러그인을 모두 준비해 줍니다. 스크립트 실행 후 `tmux`를 열고 `Prefix(C-s) + r`로 즉시 설정을 재적용할 수 있습니다.

### 상태바 & 테마

- **Catppuccin Frappe 테마** – `catppuccin/tmux` 플러그인을 통해 상단 상태바와 창 이름, pane 경계선이 동일한 컬러 팔레트를 유지합니다. Zoom 모드, 현재 경로, pane 명령어까지 가독성 있게 표시됩니다.
- **CPU/RAM 모니터링** – `tmux-plugins/tmux-cpu`가 주기적으로 시스템 사용량을 계산해 Catppuccin 아이콘(``, ``) 옆에 실시간 퍼센트를 띄웁니다. 경고/주의/안정 상태에 따라 배경색도 변합니다.
- **배터리 & 네트워크** – `tmux-battery`, `tmux-online-status`, `tmux-primary-ip` 플러그인이 배터리 잔량, 온라인 여부, 주요 IP 정보를 상태바 오른쪽에 차례로 보여줍니다.
- **Nerd Font 윈도우 이름** – `tmux-nerd-font-window-name`이 각 창 제목 앞에 직업용 아이콘을 붙여 어떤 작업을 하는 창인지 즉시 알 수 있습니다.

### 사용 중인 플러그인

| 플러그인 | 역할 |
|----------|------|
| `catppuccin/tmux` | 프리셋 컬러·아이콘을 로드해 전체 스타일을 통일합니다. |
| `tmux-plugins/tpm` | Prefix + I 키로 플러그인을 설치/업데이트하는 패키지 매니저입니다. |
| `tmux-plugins/tmux-cpu`, `tmux-battery`, `tmux-online-status`, `tmux-primary-ip` | 시스템 상태(CPU, RAM, 배터리, 네트워크)를 상태바에 노출합니다. |
| `tmux-plugins/tmux-yank` | tmux copy-mode에서 `y`를 누르면 `xclip`을 통해 시스템 클립보드로 바로 복사합니다. |
| `tmux-plugins/tmux-logging` | Prefix + Shift + P 로 현재 세션 로그를 파일로 저장할 수 있습니다. |
| `christoomey/vim-tmux-navigator` | `Ctrl+h/j/k/l`로 Neovim과 tmux pane 사이를 자연스럽게 오갑니다. |
| `tmux-plugins/tmux-sensible` | 합리적인 기본 옵션을 세팅해 각종 edge case를 줄여 줍니다. |

### 단축키 & 팁

- **프리픽스**: 기본 `Ctrl+b` 대신 `Ctrl+s`를 사용합니다. 연달아 두 번 누르면 다른 tmux 세션에게 prefix를 전달할 수 있습니다.
- **창/패널 제어**: `|`, `-`, `\`, `_`로 현재 경로 기준으로 분할하고 `Shift+H/J/K/L`로 5열씩 리사이즈합니다. `<` `>`로 창 순서를 바꾸고, `base-index 1` 덕분에 창과 패널 번호가 1부터 시작합니다.
- **복사 모드**: `v`로 선택을 시작하고 `y`로 복사하면 `xclip`이 X 클립보드에도 내용을 넣어 주므로, tmux 밖에서도 바로 붙여넣기가 가능합니다.
- **상태바 리로드**: `Prefix + r`로 `~/.tmux.conf`를 다시 읽도록 해서 테마 수정을 즉시 확인할 수 있습니다.

Catppuccin + 다양한 시스템 플러그인 덕분에 tmux 창만 열어도 현재 프로젝트, 명령, CPU/RAM 상황, 배터리, 네트워크까지 한눈에 파악할 수 있어 원격 서버에서도 동일한 UX를 유지할 수 있습니다.

---

## 🙋‍♀️ 마무리

1. 세 스크립트를 순서대로 실행합니다.
2. 새 터미널을 열어 Zsh, Vim, Neovim이 모두 원하는 테마와 플러그인으로 실행되는지 확인합니다.
3. 궁금한 점이 있다면 각 스크립트의 주석이나 로그 메시지를 참고하세요. 모두 한국어로 작성되어 있어 쉽게 이해할 수 있습니다.

즐거운 개발 되세요!
