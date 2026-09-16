" Portable Vim configuration. Plugin installation is explicit and optional.
set nocompatible
filetype plugin indent on
syntax on
set encoding=utf-8
set number relativenumber
set cursorline
set hidden
set expandtab tabstop=4 shiftwidth=4 softtabstop=4
set smartindent autoindent
set ignorecase smartcase
set incsearch hlsearch
set showmatch mouse=a
set clipboard=unnamedplus
set updatetime=300
set signcolumn=yes
set laststatus=2
set termguicolors
set undofile
set undodir=$HOME/.vim/undodir
set backupdir=$HOME/.vim/backup
set directory=$HOME/.vim/swap

for dir in [expand('~/.vim/undodir'), expand('~/.vim/backup'), expand('~/.vim/swap')]
  if !isdirectory(dir) | call mkdir(dir, 'p') | endif
endfor

let g:dotfiles_plugins = exists('$DOTFILES_PROFILE') && $DOTFILES_PROFILE ==# 'mirror' && exists('*plug#begin')
if g:dotfiles_plugins
  call plug#begin('~/.vim/plugged')
  Plug 'sheerun/vim-polyglot'
  Plug 'tomasiser/vim-code-dark'
  Plug 'preservim/nerdtree'
  Plug 'Xuyuanp/nerdtree-git-plugin'
  Plug 'ryanoasis/vim-devicons'
  Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
  Plug 'junegunn/fzf.vim'
  Plug 'tpope/vim-surround'
  Plug 'tpope/vim-repeat'
  Plug 'tpope/vim-commentary'
  Plug 'tpope/vim-fugitive'
  Plug 'airblade/vim-gitgutter'
  Plug 'vim-airline/vim-airline'
  Plug 'vim-airline/vim-airline-themes'
  Plug 'neoclide/coc.nvim', { 'branch': 'release' }
  Plug 'dense-analysis/ale'
  call plug#end()
endif

set background=dark
try
  colorscheme codedark
catch /^Vim\%((\a\+)\)\=:E185/
  highlight Normal guibg=#000000 ctermbg=16
endtry

let mapleader = ' '
nnoremap <leader>w :write<CR>
nnoremap <leader>q :quit<CR>
nnoremap <leader><space> :nohlsearch<CR>
inoremap jk <Esc>
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l
vnoremap < <gv
vnoremap > >gv

if exists(':NERDTreeToggle') == 2
  let g:NERDTreeShowHidden = 1
  let g:NERDTreeMinimalUI = 1
  let g:NERDTreeWinSize = 34
  nnoremap <leader>e :NERDTreeToggle<CR>
  nnoremap <leader>f :NERDTreeFind<CR>
endif

augroup dotfiles_vim
  autocmd!
  autocmd BufWritePre * %s/\s\+$//e
  autocmd FileType python setlocal shiftwidth=4 tabstop=4 expandtab
  autocmd FileType java,c,cpp setlocal shiftwidth=4 tabstop=4 expandtab
  autocmd FileType javascript,typescript,html,css setlocal shiftwidth=2 tabstop=2 expandtab
augroup END
