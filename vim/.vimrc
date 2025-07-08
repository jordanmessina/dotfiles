set nocompatible              " be iMproved, required
filetype off                  " required

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
" alternatively, pass a path where Vundle should install plugins
"call vundle#begin('~/some/path/here')

" let Vundle manage Vundle, required
Plugin 'VundleVim/Vundle.vim'

Plugin 'flazz/vim-colorschemes'

"Plugin 'Valloric/YouCompleteMe'

"Plugin 'ctrlpvim/ctrlp.vim'

" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required
" To ignore plugin indent changes, instead use:
"filetype plugin on
"
" Brief help
" :PluginList       - lists configured plugins
" :PluginInstall    - installs plugins; append `!` to update or just :PluginUpdate
" :PluginSearch foo - searches for foo; append `!` to refresh local cache
" :PluginClean      - confirms removal of unused plugins; append `!` to auto-approve removal
"
" see :h vundle for more details or wiki for FAQ
" Put your non-Plugin stuff after this line

"searching is not case sensitive
set ignorecase

"good to use with ignorecase
"searching for any string that has capitals will find using cases
"(ie) The will find 'The' will only find 'The', 'the' will find 'the' and
"'The'
set smartcase

"use cindent because python comment always happens at beginning of line, set taps to 4 spaces
set cindent
set tabstop=4
set shiftwidth=4
set expandtab
set softtabstop=4
set smarttab

"no annoying ass swap files, fuck that shit
set nobackup
set nowritebackup
set noswapfile


"set colorscheme
syntax enable
colorscheme 3dglasses

"toggle paste mode to F2
set pastetoggle=<F2>
"set line numbers
set nu

"maps leader key to ,
let mapleader = ","

"allows you to do %% which will give the path of the current buffer
cnoremap %% <C-R>=expand('%:h').'/'<cr>
"expand this to ,e
map <leader>e :edit %%

"switch between last two files w/ ', ,'
nnoremap <leader><leader> <c-^>

"switch between open windows with ',w'
nnoremap <leader>w <c-w><c-w>

"cntl-p
let g:ctrlp_map = ',t'

function! s:LoadSrcFiles()
    highlight OverLength ctermbg=red ctermfg=white guibg=#592929
    match OverLength /\%120v.\+/
 endfunction

" For source code files, use some special settings
autocmd FileType python, call s:LoadSrcFiles()

"pep8 and pyflakes check
au BufWritePost *.py !pep8 %
au BufWritePost *.py !pyflakes %

"breaking the bad habbit of using the cursor
noremap <Up> <NOP>
noremap <Down> <NOP>
noremap <Left> <NOP>
noremap <Right> <NOP>
