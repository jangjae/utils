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
"set expandtab
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
set showcmd
set title
set mouse=a

syntax on
set hls
set km=startsel,stopsel
set tags=tags;/
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

if version >= 500
func! Sts()
	let st = expand("<cword>")
	exe "sts ".st
	endfunc
	nmap ,st :call Sts()<CR>

func! Tj()
	let st = expand("<cword>")
	exe "tj ".st
	endfunc
	nmap ,tj :call Tj()<CR>
	endif

" 3.Cscope Configuration
set csprg=/usr/bin/cscope
set csto=0
set cst
set nocsverb

if 1
map <c-s> :w<CR>
map <c-c> y:call system("xclip -i -selection clipboard", getreg("\""))<CR>
map <c-a> :call setreg("\"",system("xclip -o -selection clipboard"))<CR>p
map <c-x> :'a,'b w! ~/tmp/tmp<CR> :'a,'b d<CR>
map <c-p> :r ~/tmp/tmp<CR>
map <c-n> <s-*>
map <s-z> :. s/^/\/\/#Comment By HKKim# /<CR>
map <s-c> :. s/^\/\/#Comment By HKKim# //g<CR>
endif


"if filereadable("./cscope.out")
"cs add cscope.out
"else
"cs add ./cscope.out
"cs add ./../cscope.out
"cs add ./../../cscope.out
"cs add ./../../../cscope.out
"cs add ./../../../../cscope.out
"cs add ./../../../../../cscope.out
"endif
"set csverb



" 4.Cscope Function & Key
" 4.1 Find this C symbol
func! Css()
	let css = expand("<cword>")
	new
	exe "cs find s ".css
	if getline(1) == ""
		exe "q!"
	endif
endfunc
nmap ,css :call Css()<cr>

" 4.2 Find finctions calling this function
func! Csc()
	let csc = expand("<cword>")
	new
	exe "cs find c ".csc
	if getline(1) == ""
		exe "q!"
	endif
endfunc
nmap ,csc :call Csc()<cr>

" 4.3 Find functions called by this function
func! Csd()
	let csd = expand("<cword>")
	new
	exe "cs find d ".csd
	if getline(1) == ""
		exe "q!"
	endif
endfunc
nmap ,csd :call Csd()<cr>

" 4.4 Find this definition
func! Csg()
	let csg = expand("<cword>")
	new
	exe "cs find g ".csg
	if getline(1) == ""
		exe "q!"
	endif
endfunc
nmap ,csg :call Csg()<cr>

filetype on
"filetype plugin on

map <F2>		:Ex<CR>
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
"call vundle#rc()

" 필수 Bundle
" Bundle 'gmarik/vundle'
" Bundle 'Yggdroot/indentLine'

" Plugin 'The-NERD-tree'
" Plugin 'Conque-shell'
"Plugin 'taglist.vim'

filetype plugin indent on

let g:indentLine_char = '|'
let g:indentLine_color_term = 0
