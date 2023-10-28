"--------------------------------------------------------------------------------
" General settings
"--------------------------------------------------------------------------------

set clipboard+=unnamedplus
set scrolloff=15
set tabstop=4
set shiftwidth=4
set shiftround
set expandtab
set hidden
set number
set relativenumber
set title
set list
set listchars=tab:▸\ ,trail:·
set mouse=a
set termguicolors
set ignorecase
set smartcase
set confirm
set nojoinspaces
set nowrap
set textwidth=79
set colorcolumn=90
set ruler
set cursorline

"--------------------------------------------------------------------------------
" Things to investigate
"--------------------------------------------------------------------------------

" Some additonal plugins to consider
" See: https://github.com/nickjj/dotfiles/blob/master/.vimrc
"
" ROOTER
"  https://github.com/airblade/vim-rooter
"
" Check common leader mappings
" - ctrl-p?
"
" List all leader mappings
" ':map <leader>'
" List all mappings in a new buffer: enew|pu=execute('map')
" see also which-key plugin
"
" Floatterm?

"--------------------------------------------------------------------------------
" Key maps
"--------------------------------------------------------------------------------

""
"" LEADER configurations
""
let mapleader = "\<space>"

" Neovim config file
nmap <leader>ve :edit ~/.config/nvim/init.vim<cr>
nmap <leader>vr :source ~/.config/nvim/init.vim<cr>

" Open the current file using the default program
nmap <leader>o :!xdg-open %<cr><cr>

" Buffer management
nmap <leader>e :q<cr>
nmap <leader>x :x<cr>
nmap <leader>w :w<cr>

" Change dir to that of current file
nnoremap <leader>cd :cd %:p:h<CR>:pwd<CR>

" Command to toggle autoformat
command AutoFormatToggle if &fo =~ 'a' | set fo-=a | else | set fo+=a | endif
nmap <leader>a :AutoFormatToggle<cr>

" Toggle wrap
noremap <Leader>W :set wrap!<CR>


" Mapping for easier access on swedish keyboards
map ¤ $

" Removes highlight of your last search
noremap <C-n> :nohl<CR>
vnoremap <C-n> :nohl<CR>
inoremap <C-n> <ESC>:nohl<CR>

inoremap jj <ESC>l

" Better indentation
vnoremap < <gv
vnoremap > >gv

" Maintain the cursor position when yanking a visual selection
" http://ddrscott.github.io/blog/2016/yank-without-jank/
vnoremap y myy`y
vnoremap Y myY`y

""
"" NAVIGATION
""

" Use Ctrl+<movement> keys to move around the windows
map <c-j> <c-w>j
map <c-k> <c-w>k
map <c-l> <c-w>l
map <c-h> <c-w>h

" Use ALT and arrow keys to resize splits
nnoremap <M-Right> :vertical resize +2<CR>
nnoremap <M-Left> :vertical resize -2<CR>
nnoremap <M-Down> :resize -2<CR>
nnoremap <M-Up> :resize +2<CR>

" Switch between alternate files using TAB
map <TAB> :bnext<CR>
map <S-TAB> :bprevious<CR>
map <C-pageup> :bprevious<CR>
map <C-pagedown> :bnext<CR>


" Toggle hybrid relative line numbers
nnoremap <leader>l :setlocal relativenumber!<Cr>

" Set relative numbers by default and return to absolute line numbering when
" cursor leaves buffer/window/split
"autocmd BufEnter * setlocal relativenumber
augroup numbertoggle
  autocmd!
  autocmd BufLeave,WinLeave,FocusLost * set norelativenumber
augroup END

""
"" FOLDING
""
nmap <leader>z :set foldmethod=syntax<cr>
nmap <leader>Z :set foldmethod=manual<cr>

""
"" SEARCH AND REPLACE WITHIN A FILE
""

" Press * to search for the term under the cursor or a visual selection and
" then press a key below to replace all instances of it in the current file.
nnoremap <Leader>r :%s///g<Left><Left>
nnoremap <Leader>rc :%s///gc<Left><Left><Left>

" Type a replacement term and press . to repeat the replacement again. Useful
" for replacing a few instances of the term (comparable to multiple cursors).
nnoremap <silent> s* :let @/='\<'.expand('<cword>').'\>'<CR>cgn
xnoremap <silent> s* "sy:let @/=@s<CR>cgn

" Use RipGrep as grep
" See https://gist.github.com/romainl/56f0c28ef953ffc157f36cc495947ab3
set grepprg=rg\ --vimgrep\ --smart-case

function! Grep(...)
    return system(join([&grepprg] + [expandcmd(join(a:000, ' '))], ' '))
endfunction

"command! -nargs=+ -complete=file_in_path -bar Grep  cgetexpr Grep(<f-args>)
command! -nargs=+ -complete=file_in_path -bar Grep  cgetexpr Grep(<f-args>)
command! -nargs=+ -complete=file_in_path -bar LGrep lgetexpr Grep(<f-args>)

cnoreabbrev <expr> grep  (getcmdtype() ==# ':' && getcmdline() ==# 'grep')  ? 'Grep'  : 'grep'
cnoreabbrev <expr> lgrep (getcmdtype() ==# ':' && getcmdline() ==# 'lgrep') ? 'LGrep' : 'lgrep'

augroup quickfix
    autocmd!
    autocmd QuickFixCmdPost cgetexpr cwindow
    autocmd QuickFixCmdPost lgetexpr lwindow
augroup END

"--------------------------------------------------------------------------------
" Plugins
"
" Using vim-plug, see https://github.com/junegunn/vim-plug for instructions
"
" More plugins:
" * nvim-compe! - Code completion
" * lsp_signature.nvim - Signatures for functions
" * Startify
" * https://github.com/justinmk/vim-sneak
"
"--------------------------------------------------------------------------------
" Automatically install vim-plug
let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'
if empty(glob(data_dir . '/autoload/plug.vim'))
  silent execute '!curl -fLo '.data_dir.'/autoload/plug.vim --create-dirs  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin(data_dir . '/plugins')

source ~/.config/nvim/plugins/airline.vim
source ~/.config/nvim/plugins/asterisk.vim
source ~/.config/nvim/plugins/fugitive.vim
source ~/.config/nvim/plugins/fzf.vim
source ~/.config/nvim/plugins/grepper.vim
source ~/.config/nvim/plugins/heritage.vim
source ~/.config/nvim/plugins/incremental-search-improved.vim
source ~/.config/nvim/plugins/kitty-navigator.vim
source ~/.config/nvim/plugins/nvim-tree.vim
source ~/.config/nvim/plugins/papercolor-theme.vim
source ~/.config/nvim/plugins/peekaboo.vim
source ~/.config/nvim/plugins/quick-scope.vim
source ~/.config/nvim/plugins/repeat.vim
source ~/.config/nvim/plugins/sayonara.vim
source ~/.config/nvim/plugins/scrollview.vim
source ~/.config/nvim/plugins/surround.vim
source ~/.config/nvim/plugins/telescope.vim
source ~/.config/nvim/plugins/trailing-whitespace.vim
source ~/.config/nvim/plugins/treesitter.vim
source ~/.config/nvim/plugins/unimpaired.vim
source ~/.config/nvim/plugins/vim-ack.vim
source ~/.config/nvim/plugins/whichkey.vim

call plug#end()
doautocmd User PlugLoaded

" Additional configuration using Lua
lua require('nvim-tree-config')
lua require('nvim-telescope-config')
"lua require('treesitter')


