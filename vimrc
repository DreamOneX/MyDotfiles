filetype plugin on
set nocompatible


set backspace=indent,eol,start
set shell=/bin/bash "设置shell
syntax on "开启高亮
set number "显示行号
set mouse=a "开启鼠标
set laststatus=2 "显示状态栏
set ambiwidth=double
set t_Co=256
"set background=dark

"vim-plug start
call plug#begin('~/.vim/plugged')
Plug 'yianwillis/vimcdoc'    "中文文档
Plug 'Yggdroot/indentLine'    "缩进线
Plug 'vim-airline/vim-airline'    "状态栏
Plug 'vim-airline/vim-airline-themes'    "airline 的主题
Plug 'scrooloose/nerdcommenter'    "注释
Plug 'luochen1990/rainbow'    "括号高亮
Plug 'https://github.com/scrooloose/nerdtree.git'    "目录树
Plug 'majutsushi/tagbar'    "ctags
Plug 'Yggdroot/LeaderF', { 'do': './install.sh'  }    "搜索
Plug 'jiangmiao/auto-pairs'    "括号
Plug 'neoclide/coc.nvim', {'branch': 'release'}    "自动补全
Plug 'Chiel92/vim-autoformat' "自动格式化
Plug 'mtdl9/vim-log-highlighting' "日志高亮
Plug 'github/copilot.vim' "Github Copilot
"一些主题
Plug 'crusoexia/vim-monokai'
Plug 'morhetz/gruvbox'
Plug 'tomasr/molokai'
Plug 'sonph/onehalf', { 'rtp': 'vim' }
Plug 'dracula/vim'
Plug 'chriskempson/base16-vim'
Plug 'jnurmine/Zenburn'
Plug 'gosukiwi/vim-atom-dark'
Plug 'jacoborus/tender.vim'
Plug 'sjl/badwolf'
Plug 'arcticicestudio/nord-vim'
Plug 'altercation/vim-colors-solarized'
Plug 'ciaranm/inkpot'
Plug 'NLKNguyen/papercolor-theme'
Plug 'ayu-theme/ayu-vim'
call plug#end()
"vim-plug end


let g:AutoPairs = {'(':')', '[':']', '{':'}',"'":"'",'"':'"', '<':'>'}
let g:indent_guides_guide_size = 1  " 对齐线的尺寸
let g:indent_guides_start_level = 1  " 可视化显示缩进层数
" <\>+<c>+<SPC> 在Normal和Visual模式下添加或去除注释
"add spaces after comment delimiters by default
let g:NERDSpaceDelims = 1
au FileType python let g:NERDSpaceDelims = 0
" Use compact syntax for prettified multi-line comments
let g:NERDCompactSexyComs = 1
" Align line-wise comment delimiters flush left instead of following code indentation
let g:NERDDefaultAlign = 'left'
" Set a language to use its alternate delimiters by default
let g:NERDAltDelims_java = 1
" Add your own custom formats or override the defaults
" let g:NERDCustomDelimiters = { 'c': { 'left': '/**','right': '*/' } }
" Allow commenting and inverting empty lines (useful when commenting a region)
let g:NERDCommentEmptyLines = 1
" Enable trimming of trailing whitespace when uncommenting
let g:NERDTrimTrailingWhitespace = 1
" Enable NERDCommenterToggle to check all selected lines is commented or not
let g:NERDToggleCheckAllLines = 1
let g:NERDTreeWinSize = 25
let g:NERDTreeDirArrowExpandable = '+'
let g:NERDTreeDirArrowCollapsible = '-'
let g:NERDTreeShowLineNumbers=0
map <C-h> :NERDTree<CR> "按<C-w>打开NERDTree
let g:rainbow_active = 1
nnoremap <silent> <C-j> :TagbarToggle<CR> "按<C-t>打开tagbar
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#left_alt_sep = '|'
let g:airline#extensions#tabline#buffer_nr_show = 0
let g:airline#extensions#tabline#formatter = 'default'
" let g:airline_theme = 'desertink'  " 主题
" let g:airline_powerline_fonts = 1
let g:airline#extensions#keymap#enabled = 1
let g:airline#extensions#tabline#buffer_idx_mode = 1
let g:airline#extensions#tabline#buffer_idx_format = {
       \ '0': '0 ',
       \ '1': '1 ',
       \ '2': '2 ',
       \ '3': '3 ',
       \ '4': '4 ',
       \ '5': '5 ',
       \ '6': '6 ',
       \ '7': '7 ',
       \ '8': '8 ',
       \ '9': '9 '
       \}
" 设置切换tab的快捷键 <\> + <i> 切换到第i个 tab
nmap <leader>1 <Plug>AirlineSelectTab1
nmap <leader>2 <Plug>AirlineSelectTab2
nmap <leader>3 <Plug>AirlineSelectTab3
nmap <leader>4 <Plug>AirlineSelectTab4
nmap <leader>5 <Plug>AirlineSelectTab5
nmap <leader>6 <Plug>AirlineSelectTab6
nmap <leader>7 <Plug>AirlineSelectTab7
nmap <leader>8 <Plug>AirlineSelectTab8
nmap <leader>9 <Plug>AirlineSelectTab9
" 设置切换tab的快捷键 <\> + <-> 切换到前一个 tab
nmap <leader>- <Plug>AirlineSelectPrevTab
" 设置切换tab的快捷键 <\> + <+> 切换到后一个 tab
nmap <leader>+ <Plug>AirlineSelectNextTab
" 设置切换tab的快捷键 <\> + <q> 退出当前的 tab
nmap <leader>q :bp<cr>:bd #<cr>
" 修改了一些个人不喜欢的字符
if !exists('g:airline_symbols')
    let g:airline_symbols = {}
endif
let g:airline_symbols.linenr = "CL" " current line
let g:airline_symbols.whitespace = '|'
let g:airline_symbols.maxlinenr = 'Ml' "maxline
let g:airline_symbols.branch = 'BR'
let g:airline_symbols.readonly = "RO"
let g:airline_symbols.dirty = "DT"
let g:airline_symbols.crypt = "CR"
colo atom-dark
