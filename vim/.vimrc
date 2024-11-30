"========= default variables setting =========
set bg=dark
set ruler              "화면 우측 하단에 현재 커서의 위치(줄,칸)를 보여준다.
set number             " 줄 번호 표시
set modifiable
set hlsearch           " Highlight Search
set ts=4               " tab stop - tab 크기
set sw=4               " shift width - shift 크기 조절
set sts=4              " soft tab stop - tab 이동 크기
set incsearch
set ignorecase
set printoptions=portrait:n,wrap:n,duplex:offset
set fileencodings=utf-8,euc-kr

"-----------------------------------------------------------------------
" Vundle 환경설정
"-----------------------------------------------------------------------
filetype off                    " required!
set shell=/bin/bash
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

" Vundle이 Vundle을 관리하게 설정 (필수!)
Plugin 'VundleVim/Vundle.vim'
" 새로운 플러그인 추가
Plugin 'vim-airline/vim-airline'
Plugin 'vim-airline/vim-airline-themes'
Plugin 'morhetz/gruvbox'
Plugin 'ctrlpvim/ctrlp.vim'
Plugin 'tpope/vim-fugitive'
" 이전에 사용하던 플러그인 (Vundle 형식으로 변환)
Plugin 'scrooloose/nerdtree'            " The-NERD-tree
Plugin 'majutsushi/tagbar'              " Taglist.vim 대신 사용 (비슷한 기능 제공)
Plugin 'jlanzarotta/bufexplorer'        " bufexplorer.zip
Plugin 'vim-scripts/DirDiff.vim'        " DirDiff.vim
Plugin 'wesleyche/SrcExpl'              " SrcExpl
Plugin 'altercation/vim-colors-solarized'  " Solarized 색상 테마
" ripgrep 플러그인 
Plugin 'junegunn/fzf'
Plugin 'junegunn/fzf.vim'
" tmux <-> vim 간 창 이동
Plugin 'christoomey/vim-tmux-navigator'
" log-highlight
Plugin 'mtdl9/vim-log-highlighting'

" 플러그인 설치 종료
call vundle#end()
filetype plugin indent on               " 필수!

"========= key mapping ==========
map <F2> v]}zf                         " 코드의 { 부분에서 영역 접기
map <F3> zo                            " 영역 펼치기
map <F6> :BufExplorer<cr>
map <PageUp> <C-U><C-U>
map <PageDown> <C-D><C-D>

" Vim 내의 창 크기 조절
nmap <s-h> <C-W><
nmap <s-j> <C-W>-
nmap <s-k> <C-W>+
nmap <s-l> <C-W>>

" Vim 내에서 창 간 이동
nmap <c-h> <c-w>h
nmap <c-j> <c-w>j
nmap <c-k> <c-w>k
nmap <c-l> <c-w>l

"-----------------------------
" Tag List config
filetype on                           " vim filetype on
nmap <F7> :TlistToggle<CR>
let Tlist_Ctags_Cmd="/usr/bin/ctags"
let Tlist_Inc_Winwidth=0
let Tlist_Exit_OnlyWindow=0           " window close=off
let Tlist_Auto_Open=0
let Tlist_Use_Right_Window=1

"-----------------------------
" Source Explorer config
" The switch of the Source Explorer
nmap <F8> :SrcExplToggle<CR>

" Set the height of Source Explorer window
let g:SrcExpl_winHeight = 8

" Set 100 ms for refreshing the Source Explorer
let g:SrcExpl_refreshTime = 100

" Set "Enter" key to jump into the exact definition context
let g:SrcExpl_jumpKey = "<ENTER>"

" Set "Space" key for back from the definition context
let g:SrcExpl_gobackKey = "<SPACE>"

" In order to Avoid conflicts, the Source Explorer should know what plugins
" are using buffers. And you need add their bufname into the list below
" according to the command ":buffers!"
let g:SrcExpl_pluginList = [
      \ "__Tag_List__",
      \ "_NERD_tree_",
      \ "Source_Explorer"
      \ ]

" Enable/Disable the local definition searching, and note that this is not
" guaranteed to work, the Source Explorer doesn't check the syntax for now.
" It only searches for a match with the keyword according to command 'gd'
let g:SrcExpl_searchLocalDef = 1

" Do not let the Source Explorer update the tags file when opening
let g:SrcExpl_isUpdateTags = 0

" Use 'Exuberant Ctags' with '--sort=foldcase -R .' or '-L cscope.files' to
" create/update a tags file
let g:SrcExpl_updateTagsCmd = "ctags --sort=foldcase -R ."

" Set "<F12>" key for updating the tags file artificially
let g:SrcExpl_updateTagsKey = "<F12>"

"-----------------------------
" NERD Tree config
let NERDTreeWinPos="left"
let g:NERDTreeDirArrows=0
nmap <F9> :NERDTreeToggle<CR>

"========= switch between file buffers ========
map ,x :bn!<CR>           " Switch to Next File Buffer
map ,z :bp!<CR>           " Switch to Previous File Buffer
map ,w :bw<CR>            " Close Current File Buffer
map ,1 :b!1<CR>           " Switch to File Buffer #1
map ,2 :b!2<CR>           " Switch to File Buffer #2
map ,3 :b!3<CR>           " Switch to File Buffer #3
map ,4 :b!4<CR>           " Switch to File Buffer #4
map ,5 :b!5<CR>           " Switch to File Buffer #5
map ,6 :b!6<CR>           " Switch to File Buffer #6
map ,7 :b!7<CR>           " Switch to File Buffer #7
map ,8 :b!8<CR>           " Switch to File Buffer #8
map ,9 :b!9<CR>           " Switch to File Buffer #9
map ,0 :b!0<CR>           " Switch to File Buffer #0

"============ project specific settings =============
if filereadable(".project.vimrc")
    source .project.vimrc
endif

"========= solarized scheme =======
syntax enable
set t_Co=256
let g:solarized_termcolors=256
colorscheme solarized
"==================================

"========= yank to clipboard =================
" 비주얼 모드에서 y를 누르면 클립보드와 일반 레지스터에 복사
vnoremap y y:call setreg('+', getreg('"'))<CR>
