" set nu
" "set term=xterm-256color
" "color northland
" set tabstop=2
" set shiftwidth=2
" "set autoindent
" "set cindent
" set ignorecase
" "set smartcase
" "set smartindent
" set sol
" set showmatch
" set mps+=<:>
" set wmnu
" set hls
" set laststatus=2
" set statusline=%f
" set mouse=nicr
"
set fileencoding=utf-8
set fileencodings=utf-8,cp949,euc-kr
set termencoding=utf-8
set encoding=utf-8
set autoindent
set autowrite
set backspace=indent,eol,start
set cindent
set cinoptions=:0,g0,0,l1,t0
set history=1000
set hlsearch
set incsearch
set laststatus=2
set magic
set mouse=a
set nomousehide
set nobackup
set noerrorbells
set expandtab
"set nowrap
set number!
set report=0
set ruler
set scrolloff=5
set selection=exclusive
set shiftwidth=2
set tabstop=2
set showmatch
set showcmd
set showmode
set sidescrolloff=5
set smartcase
set smartindent
set startofline
set softtabstop=0
set title
set ttyfast
set wildmenu
set cursorline
"set whichwrap=h,l,[,]
set wildmode=longest:full,full
set ignorecase

syntax on
set hls
set km=startsel,stopsel
set tags+=/usr/sys/tags
set tags+=/usr/include/tags
set tags+=/home/jangjaeyoung/tags
set tags+=./tags,tags,../tags,../../tags,../../../tags,../../../../tags,../../../../../tags

let Tlist_Sort_type = "name"
let Tlist_WinWidth = 20

au BufReadPost *
\ if line("'\"") > 0 && line("'\"") <= line("$") |
\   exe "norm g`\"" |
\ endif

" Conque-shell related

" let g:ConqueTerm_InsertOnEnter = 1
" let g:ConqueTerm_CWInsert = 1
" let g:ConqueTerm_ClosedOnEnd = 1

filetype on
"filetype plugin on

map <F2>		:E<CR>
map <F3>		gt
map <F4>		gT
map <F5>		:tabnew<CR>
map <F6>		:sts<CR>

map <F7>		:tlist<CR>
map <F8>		:tb<CR>
map <F9>		:tn<CR>

set nocompatible 
filetype off
set rtp+=~/.vim/bundle/vundle/
call vundle#rc()

" 필수 Bundle
Bundle 'gmarik/vundle'
Bundle 'Yggdroot/indentLine'

Plugin 'The-NERD-tree'
Plugin 'Conque-shell'
Plugin 'taglist.vim'

filetype plugin indent on

let g:indentLine_char = '|'
let g:indentLine_color_term = 0
