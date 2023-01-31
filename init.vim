filetype plugin on
set nocompatible

echo "(≧▽≦) NeoVim is starting"
set backspace=indent,eol,start
set shell=/usr/bin/zsh  " 设置shell
syntax on               " 开启高亮
set number              " 显示行号
set mouse=a             " 开启鼠标
set laststatus=2        " 显示状态栏
set ambiwidth=double
set t_Co=256
set history=10000       " 历史
set autoindent          " 自动缩进
set cindent
set tabstop=4           " tab长度
set expandtab
set shiftwidth=4
set incsearch
set smartindent         " 缩进
set hlsearch            " 高亮搜索
set undofile            " 撤销文件
set undodir=~/.vim/undo
set cursorline          " 高亮当前行
set ic                  " 无视大小写
set background=dark

set signcolumn=yes
set updatetime=300

if has("termguicolors")
    " fix bug for vim
    set t_8f=[38;2;%lu;%lu;%lum
    set t_8b=[48;2;%lu;%lu;%lum

    " enable true color
    set termguicolors
endif

if exists("g:neovide")
    set guifont=Sauce\ Code\ Pro\ Medium\ Nerd\ Font\ Complete:h14
    let g:neovide_scale_factor = 1.0
    let g:neovide_floating_blur_amount_x = 2.0
    let g:neovide_floating_blur_amount_y = 2.0
    let g:transparency = 0.8
    let g:neovide_transparency = 0.8
    let g:neovide_cursor_vfx_mode = "pixiedust"
    let g:neovide_cursor_vfx_opacity = 300.0
    let g:neovide_cursor_vfx_particle_lifetime = 4.2
    let g:neovide_cursor_vfx_particle_density = 32.0
    let g:neovide_cursor_vfx_particle_speed = 8.0
    let g:neovide_cursor_vfx_particle_phase = 1.2
    let g:neovide_cursor_vfx_particle_curl = 0.6
    let g:neovide_cursor_animation_length = 0.07
    let g:neovide_cursor_trail_size = 0.9
    " let g:neovide_cursor_vfx_mode = "railgun"
    " let g:neovide_cursor_vfx_opacity = 300.0
    " let g:neovide_cursor_vfx_particle_lifetime = 1.8
    " let g:neovide_cursor_vfx_particle_density = 12.0
    " let g:neovide_cursor_vfx_particle_speed = 10.0
    " let g:neovide_cursor_vfx_particle_phase = 1.2
    " let g:neovide_cursor_vfx_particle_curl = 0.8

endif

let mapleader = "\\"

iabbrev @@ DreamOneX <me@dreamonex.eu.org>

nnoremap <leader>pp :set paste!<CR>
tnoremap <ESC><ESC><ESC><ESC> <C-\><C-n>

nnoremap <leader>ev :split $MYVIMRC<CR>
nnoremap <leader>rl :source $MYVIMRC<CR>
nnoremap <leader>evd :e $MYVIMRC<CR>
nnoremap <silent> <space>r :set relativenumber!<CR>

nnoremap <C-h> :NERDTreeToggle<CR> " 按<C-h>打开NERDTree
nnoremap <leader>nf :NERDTreeFind<CR>
nnoremap <silent> <C-j> :TagbarToggle<CR> "按<C-j>打开tagbar

"vim-plug start
call plug#begin('~/.vim/plugged')
Plug 'yianwillis/vimcdoc'                           " 中文文档
Plug 'Yggdroot/indentLine'                          " 缩进线
Plug 'vim-airline/vim-airline'                      " 状态栏
Plug 'vim-airline/vim-airline-themes'               " airline 的主题
Plug 'scrooloose/nerdcommenter'                     " 注释
Plug 'luochen1990/rainbow'                          " 括号高亮
Plug 'https://github.com/scrooloose/nerdtree.git'   " NerdTree
Plug 'ryanoasis/vim-devicons'                       " NerdFonts
Plug 'johnstef99/vim-nerdtree-syntax-highlight'
Plug 'Xuyuanp/nerdtree-git-plugin'                  " NerdTree Git
Plug 'PhilRunninger/nerdtree-visual-selection'      " NerdTree Ops

Plug 'majutsushi/tagbar'                            " ctags
Plug 'Yggdroot/LeaderF', { 'do': './install.sh'  }  " 搜索
Plug 'jiangmiao/auto-pairs'                         " 括号
Plug 'neoclide/coc.nvim', {'branch': 'release'}     " coc.nvim
Plug 'Chiel92/vim-autoformat'                       " 自动格式化
Plug 'mtdl9/vim-log-highlighting'                   " 日志高亮
Plug 'github/copilot.vim'                           " Github Copilot
Plug 'easymotion/vim-easymotion'                    " ‽
Plug 'udalov/kotlin-vim'                            " kotlin
Plug 'simnalamburt/vim-mundo'                       " 撤销
Plug 'dense-analysis/ale'                           " ale
Plug 'godlygeek/tabular'                            " 文本对齐
Plug 'preservim/vim-markdown'                       " markdown
Plug 'kshenoy/vim-signature'                        " mark高亮
Plug 'mg979/vim-visual-multi', {'branch': 'master'} " 多光标
Plug 'wellle/targets.vim'                           " 更多文本对象


"一些主题
Plug 'crusoexia/vim-monokai'
Plug 'morhetz/gruvbox'
Plug 'tomasr/molokai'
Plug 'sonph/onehalf', { 'rtp': 'vim' }
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
let g:indentLine_color_term = 239
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
let g:NERDTreeFileExtensionHighlightFullName = 1
let g:NERDTreeExactMatchHighlightFullName = 1
let g:NERDTreePatternMatchHighlightFullName = 1
let g:NERDTreeHighlightFolders = 1 " enables folder icon highlighting using exact match
let g:NERDTreeHighlightFoldersFullName = 1 " highlights the folder name

let g:NERDTreeExtensionHighlightColor = {}
let g:NERDTreeExtensionHighlightColor['xml'] = '8FAA54'
let g:NERDTreeExtensionHighlightColor['yaml'] = '8FAA54'

" let g:webdevicons_enable_nerdtree = 0

" Git
let g:NERDTreeGitStatusIndicatorMapCustom = {
                \ 'Modified'  :'*',
                \ 'Staged'    :'+',
                \ 'Untracked' :'∆',
                \ 'Renamed'   :'>',
                \ 'Unmerged'  :'=',
                \ 'Deleted'   :'x',
                \ 'Dirty'     :'✗',
                \ 'Ignored'   :'▨',
                \ 'Clean'     :'√',
                \ 'Unknown'   :'?',
                \ }
let g:NERDTreeGitStatusShowIgnored = 0
let g:NERDTreeGitStatusUseNerdFonts = 0
" end

let g:rainbow_active = 1
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#left_alt_sep = '|'
let g:airline#extensions#tabline#buffer_nr_show = 0
let g:airline#extensions#tabline#formatter = 'default'
" let g:airline_theme = 'desertink'  " 主题
let g:airline_powerline_fonts = 1
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
let g:airline#extensions#ale#enabled = 1
" 设置切换tab的快捷键 <\> + <i> 切换到第i个 tab
nnoremap <leader>1 <Plug>AirlineSelectTab1
nnoremap <leader>2 <Plug>AirlineSelectTab2
nnoremap <leader>3 <Plug>AirlineSelectTab3
nnoremap <leader>4 <Plug>AirlineSelectTab4
nnoremap <leader>5 <Plug>AirlineSelectTab5
nnoremap <leader>6 <Plug>AirlineSelectTab6
nnoremap <leader>7 <Plug>AirlineSelectTab7
nnoremap <leader>8 <Plug>AirlineSelectTab8
nnoremap <leader>9 <Plug>AirlineSelectTab9
" 设置切换tab的快捷键 <\> + <-> 切换到前一个 tab
nnoremap <leader>- <Plug>AirlineSelectPrevTab
" 设置切换tab的快捷键 <\> + <+> 切换到后一个 tab
nnoremap <leader>+ <Plug>AirlineSelectNextTab
" 设置切换tab的快捷键 <\> + <q> 退出当前的 tab
nnoremap <leader>q :bp<cr>:bd #<cr>
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

"copilot
let g:copilot_node_command = "~/.vim/local/node16/bin/node"
imap <silent><script><expr> <M-t> copilot#Accept("\<CR>")
let g:copilot_no_tab_map = v:true

"ZFVimIm
let g:zf_git_user_email='me@dreamonex.eu.org'
let g:zf_git_user_name='DreamOneX'
let g:zf_git_user_token='¿'
let g:ZFVimIM_keymap=0

" 更改快捷键
map <space> <Plug>(easymotion-prefix)
nmap <space>f <Plug>(easymotion-s)
nmap <space>l <Plug>(easymotion-lineforward)
nmap <space>j <Plug>(easymotion-j)
nmap <space>k <Plug>(easymotion-k)
nmap <space>h <Plug>(easymotion-linebackward)
nmap <space>s <Plug>(easymotion-s2)
" " 忽略大小写
let g:EasyMotion_smartcase = 1


" coc.nvim

" Use tab for trigger completion with characters ahead and navigate.
" NOTE: There's always complete item selected by default, you may want to enable
" no select by `"suggest.noselect": true` in your configuration file.
" NOTE: Use command ':verbose imap <tab>' to make sure tab is not mapped by
" other plugin before putting this into your config.
inoremap <silent><expr> <TAB>
      \ coc#pum#visible() ? coc#pum#next(1) :
      \ CheckBackspace() ? "\<Tab>" :
      \ coc#refresh()
inoremap <expr><S-TAB> coc#pum#visible() ? coc#pum#prev(1) : "\<C-h>"

" Make <CR> to accept selected completion item or notify coc.nvim to format
" <C-g>u breaks current undo, please make your own choice.
inoremap <silent><expr> <CR> coc#pum#visible() ? coc#pum#confirm()
                              \: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"

function! CheckBackspace() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

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

" Remap <C-f> and <C-b> to scroll float windows/popups
if has('nvim-0.4.0') || has('patch-8.2.0750')
  nnoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? coc#float#scroll(1) : "\<C-f>"
  nnoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? coc#float#scroll(0) : "\<C-b>"
  nnoremap <silent><nowait><expr> <M-q> coc#float#has_scroll() ? coc#float#close_all() : "\<M-q>"
  inoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(1)\<cr>" : "\<Right>"
  inoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(0)\<cr>" : "\<Left>"
  vnoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? coc#float#scroll(1) : "\<C-f>"
  vnoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? coc#float#scroll(0) : "\<C-b>"
  vnoremap <silent><nowait><expr> <M-q> coc#float#has_scroll() ? coc#float#close_all() : "\<M-q>"
endif

" Add `:Format` command to format current buffer
command! -nargs=0 Format :call CocActionAsync('format')

" Add `:Fold` command to fold current buffer
command! -nargs=? Fold :call     CocAction('fold', <f-args>)

" Add `:OR` command for organize imports of the current buffer
command! -nargs=0 OR   :call     CocActionAsync('runCommand', 'editor.action.organizeImport')


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

function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

let g:coc_snippet_next = '<tab>'

nmap <Leader>tp <Plug>(coc-translator-p)
vmap <Leader>tp <Plug>(coc-translator-pv)

nmap <Leader>te <Plug>(coc-translator-e)
vmap <Leader>te <Plug>(coc-translator-ev)

nmap <Leader>tr <Plug>(coc-translator-r)
vmap <Leader>tr <Plug>(coc-translator-rv)

" autoformat
let g:autoformat_verbosemode=1
let g:formatdef_ktlint = '"ktlint --stdin -F"'
let g:formatters_kotlin = ['ktlint']
let g:formatdef_python = '"yapf"'
let g:formatter_yapf_style = 'pep8'
let g:formatters_python = ['python']
let g:formatdef_allman = '"astyle --style=allman --pad-oper"'
let g:formatters_cpp = ['allman']
let g:formatters_c = ['allman']
nnoremap <leader>af :Autoformat<CR>

" LeaderF
let g:Lf_RootMarkers = ['.git', '.svn', '.hg', '.project', '.root']
nnoremap <leader>lr :Leaderf rg<CR>
nnoremap <leader>ll :LeaderfLine<CR>
nnoremap <leader>lf :LeaderfFile<CR>
" Mundo
nnoremap <leader>ms :MundoShow<CR>
nnoremap <leader>mh :MundoHide<CR>

" ale
let b:ale_linters = ['flake8', 'pylint', 'ktlint']
let b:ale_fixers = ['autopep8', 'yapf']
let g:ale_disable_lsp = 1

let g:ale_python_pylint_options = '-d=line-too-long -d=missing-function-docstring -d=missing-module-docstring --good-names f,fg,bg'
let g:ale_python_flake8_options = '--ignore E501'

" signature
nnoremap <leader>sr :SignatureRefresh<CR>
nnoremap <leader>st :SignatureToggleSigns<CR>

" markdown
let g:vim_markdown_conceal = 0
