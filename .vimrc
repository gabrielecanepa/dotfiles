" Encoding
if has("multi_byte")
  set encoding=utf-8
  setglobal fileencoding=utf-8
else
  echoerr "This version of (g)vim was not compiled with +multi_byte"
endif

" Editing
syntax on
filetype plugin indent on
set backspace=indent,eol,start
set tabstop=2 shiftwidth=2 expandtab
set autoindent
set number
set nowrap
set scrolloff=5

" Search
set incsearch
set hlsearch
set ignorecase
set smartcase

" Interface
set ruler
set showcmd
set wildmenu
set laststatus=2
set mouse=a

" Files
set hidden
set nobackup
set nowritebackup
set noswapfile
if has("persistent_undo")
  let s:undodir = expand("$HOME/.vim/undo")
  if !isdirectory(s:undodir)
    call mkdir(s:undodir, "p")
  endif
  let &undodir = s:undodir
  set undofile
endif
