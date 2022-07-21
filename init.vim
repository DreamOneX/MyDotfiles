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
set history=10000 "历史
set autoindent    "自动缩进
set cindent
set tabstop=4     "tab长度
set expandtab
set shiftwidth=4
set incsearch
set smartindent   "缩进
set hlsearch
"set background=dark


function Paste_set()
	if &paste
		set nopaste
	else
		set paste
	endif
endfunction

nmap <expr><leader>pp Paste_set()

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
Plug 'ZSaberLv0/ZFVimIM' "中文输入法
Plug 'ZSaberLv0/ZFVimJob' "  用于提升词库加载性能
Plug 'DreamOneX/ZFVimIM_pinyin_base' " 你的词库
Plug 'ZSaberLv0/ZFVimIM_openapi' " 百度云输入法
Plug 'easymotion/vim-easymotion' " 搜索
Plug 'vim-scripts/gundo.vim' " 撤销
Plug 'udalov/kotlin-vim' " kotlin
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
colo atom-dark-256

"copilot
let g:copilot_node_command = "/usr/local/node16/bin/node"

"ZFVimIm
let g:zf_git_user_email='me@dreamonex.ml'
let g:zf_git_user_name='DreamOneX'
let g:zf_git_user_token='不可以啦'
let &statusline='%{ZFVimIME_IMEStatusline()}'.&statusline
function! ZF_Setting_cmdEdit()
	let cmdtype = getcmdtype()
	if cmdtype != ':' && cmdtype != '/'
		return ''
	endif
	call feedkeys("\<c-c>q" . cmdtype . 'k0' . (getcmdpos() - 1) . 'li', 'nt')
	return ''
endfunction
cnoremap <silent><expr> <leader>;; ZF_Setting_cmdEdit()

" 更改快捷键
map f <Plug>(easymotion-prefix)
map ff <Plug>(easymotion-s)
map fs <Plug>(easymotion-f)
map fl <Plug>(easymotion-lineforward)
map fj <Plug>(easymotion-j)
map fk <Plug>(easymotion-k)
map fh <Plug>(easymotion-linebackward)
nmap ss <Plug>(easymotion-s2)
" " 忽略大小写
let g:EasyMotion_smartcase = 1"

" coc.nvim
nmap <leader>rn <Plug>(coc-rename)
nmap <leader>rf <Plug>(coc-refactor)

" Use `[g` and `]g` to navigate diagnostics
" Use `:CocDiagnostics` to get all diagnostics of current buffer in location list.
nmap <silent> [g <Plug>(coc-diagnostic-prev)
nmap <silent> ]g <Plug>(coc-diagnostic-next)

" GoTo code navigation.
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

" Use K to show documentation in preview window.
nnoremap <silent> K :call ShowDocumentation()<CR>

function! ShowDocumentation()
	if CocAction('hasProvider', 'hover')
		call CocActionAsync('doHover')
	else
		call feedkeys('K', 'in')
	endif
endfunction

autocmd CursorHold * silent call CocActionAsync('highlight')

" Applying codeAction to the selected region.
" Example: `<leader>aap` for current paragraph
xmap <leader>a  <Plug>(coc-codeaction-selected)
nmap <leader>a  <Plug>(coc-codeaction-selected)

" Remap keys for applying codeAction to the current buffer.
nmap <leader>ac  <Plug>(coc-codeaction)
" Apply AutoFix to problem on the current line.
nmap <leader>qf  <Plug>(coc-fix-current)

" Run the Code Lens action on the current line.
nmap <leader>cl  <Plug>(coc-codelens-action)

" Map function and class text objects
" NOTE: Requires 'textDocument.documentSymbol' support from the language server.
xmap if <Plug>(coc-funcobj-i)
omap if <Plug>(coc-funcobj-i)
xmap af <Plug>(coc-funcobj-a)
omap af <Plug>(coc-funcobj-a)
xmap ic <Plug>(coc-classobj-i)
omap ic <Plug>(coc-classobj-i)
xmap ac <Plug>(coc-classobj-a)
omap ac <Plug>(coc-classobj-a)

" Formatting selected code.
xmap <leader>f  <Plug>(coc-format-selected)
nmap <leader>f  <Plug>(coc-format-selected)

" Use CTRL-S for selections ranges.
" Requires 'textDocument/selectionRange' support of language server.
nmap <silent> <C-s> <Plug>(coc-range-select)
xmap <silent> <C-s> <Plug>(coc-range-select)

autocmd FileType scss setl iskeyword+=@-@

" Use <C-l> for trigger snippet expand.
imap <C-l> <Plug>(coc-snippets-expand)

" Use <C-j> for select text for visual placeholder of snippet.
vmap <C-j> <Plug>(coc-snippets-select)

" Use <C-j> for jump to next placeholder, it's default of coc.nvim
let g:coc_snippet_next = '<c-j>'

" Use <C-k> for jump to previous placeholder, it's default of coc.nvim
let g:coc_snippet_prev = '<c-k>'

" Use <C-j> for both expand and jump (make expand higher priority.)
imap <C-j> <Plug>(coc-snippets-expand-jump)

" Use <leader>x for convert visual selected code to snippet
xmap <leader>x  <Plug>(coc-convert-snippet)

inoremap <silent><expr> <TAB>
      \ pumvisible() ? coc#_select_confirm() :
      \ coc#expandableOrJumpable() ? "\<C-r>=coc#rpc#request('doKeymap', ['snippets-expand-jump',''])\<CR>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ coc#refresh()

function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

let g:coc_snippet_next = '<tab>'

" autoformat
let g:autoformat_verbosemode=1
let g:formatdef_ktlint = '"ktlint --stdin -F"'
let g:formatters_kotlin = ['ktlint']
