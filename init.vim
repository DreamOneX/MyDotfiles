filetype plugin on
set nocompatible
syntax on               " 开启高亮

echo "(≧▽≦) NeoVim is starting"
set backspace=indent,eol,start
set encoding=utf-8
set fileencodings=utf-8,gbk,gb2312,cp936
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
set ignorecase          " 无视大小写
set smartcase
set background=dark
set nrformats=bin,hex   " C-a C-x 设置
set conceallevel=1      " 不隐藏特殊字符
set signcolumn=yes
" set signcolumn=number
" set wildmenu            " 命令行补全
" set wildmode=list:longest,full
" set wildignore=*.swp,*.bak,*.pyc,*.class,*.o,*.obj,*.exe,*.dll,*.so,*.dylib,*.zip,*.tar.gz,*.rar,*.7z
" set wildignorecase      " 忽略大小写
" set scrolloff=3         " 光标上下留白
" set sidescrolloff=5     " 光标左右留白

set updatetime=300

set listchars=eol:¬,tab:>-,trail:~,extends:>,precedes:<,nbsp:.,multispace:---+,conceal:#
set list

if exists('$PREFIX') && executable($PREFIX . '/bin/zsh')
    set shell=$PREFIX/bin/zsh
elseif executable('zsh')
    set shell=zsh
elseif exists('$PREFIX') && executable($PREFIX . '/bin/bash')
    set shell=$PREFIX/bin/bash
elseif executable('bash')
    set shell=bash
elseif exists('$SHELL')
    set shell=$SHELL
else
    set shell=sh
endif

if executable('fcitx5-remote')
    " 1 is inactivate, 2 is activate
    let fcitx5enabled = system('fcitx5-remote')
    let insertstate = fcitx5enabled
    augroup fcitx5
        autocmd!
        autocmd InsertLeave * let insertstate = system('fcitx5-remote') | call system('fcitx5-remote -c')
        autocmd InsertEnter * if insertstate == 2 | call system('fcitx5-remote -o') | endif
    augroup END
endif

function! CommentFoldV() range abort
  " 1) Determine range (visual or range args)
  let s = (a:firstline > 0 ? a:firstline : getpos("'<")[1])
  let e = (a:lastline  > 0 ? a:lastline  : getpos("'>")[1])
  if s == 0 || e == 0
    echohl WarningMsg | echom "[CommentFoldV] No valid selection." | echohl None
    return
  endif
  if s > e | let [s,e] = [e,s] | endif

  " 2) Fold markers
  let [open_m, close_m] = split(&foldmarker, ',')
  if empty(open_m) | let open_m = '{{{' | endif
  if empty(close_m) | let close_m = '}}}' | endif

  " 3) Comment string
  let cs = &commentstring
  if empty(cs) || cs ==# '%s'
    let cs = '# %s'
  endif

  " 4) Indent and lines to insert
  let indent      = matchstr(getline(s), '^\s*')
  let tag         = 'FOLD_TITLE'
  let open_line   = indent . printf(cs, open_m . ' ' . tag)
  let close_line  = indent . printf(cs, close_m)

  " 5) Insert closing and opening markers
  call append(e, close_line)
  call append(s - 1, open_line)

  " 6) Move cursor and visually select tag
  let open_lnum = s
  let line_text = getline(open_lnum)
  let c0 = match(line_text, '\V' . tag)
  if c0 >= 0
    call cursor(open_lnum, c0 + 1)
    execute 'normal! v' . (strlen(tag) - 1) . 'l' . "\<C-g>"
  else
    call cursor(open_lnum, 1)
  endif
endfunction

xnoremap <silent> <leader>fm :<C-U>call CommentFoldV()<CR>

augroup vimrc
    autocmd!

    autocmd BufWritePre * :%s/\n\+\%$//e " 删除文件末尾空行
    autocmd FileType help,nerdtree,Mundo nnoremap <buffer> <Esc> :q<CR>

    autocmd BufWinEnter * if line("'\"") > 1 && line("'\"") <= line("$") | keepjumps execute "normal! g'\"" | silent! normal! zvzz | endif

    autocmd BufReadPost * if &filetype !=# 'markdown' | silent! %s/\s\+$//e | endif
    autocmd BufWritePre * if &filetype !=# 'markdown' | silent! %s/\s\+$//e | endif

augroup END


if has("termguicolors")
    " fix bug for vim
    set t_8f=[38;2;%lu;%lu;%lum
    set t_8b=[48;2;%lu;%lu;%lum

    " enable true color
    set termguicolors
endif

if exists("g:neovide")
    set guifont=JetBrainsMono\ Nerd\ Font\ Mono:h14
    let g:neovide_scale_factor = 0.7

    let g:neovide_text_gamma = 0.8
    let g:neovide_text_contrast = 0.1

    let g:neovide_padding_top = 0
    let g:neovide_padding_bottom = 0
    let g:neovide_padding_right = 0
    let g:neovide_padding_left = 0

    let g:neovide_floating_blur_amount_x = 2.0
    let g:neovide_floating_blur_amount_y = 2.0
    let g:transparency = 0.8
    let g:neovide_opacity = 0.8
    " let g:neovide_cursor_animation_length = 0
    let g:neovide_cursor_vfx_mode = "pixiedust"
    let g:neovide_cursor_vfx_opacity = 300.0
    let g:neovide_cursor_vfx_particle_lifetime = 4.2
    let g:neovide_cursor_vfx_particle_density = 8.0
    let g:neovide_cursor_vfx_particle_speed = 8.0
    let g:neovide_cursor_vfx_particle_phase = 1.2
    let g:neovide_cursor_vfx_particle_curl = 0.6
    let g:neovide_cursor_animation_length = 0.05
    let g:neovide_cursor_trail_size = 0.8
    " let g:neovide_cursor_vfx_mode = "railgun"
    " let g:neovide_cursor_vfx_opacity = 300.0
    " let g:neovide_cursor_vfx_particle_lifetime = 1.8
    " let g:neovide_cursor_vfx_particle_density = 12.0
    " let g:neovide_cursor_vfx_particle_speed = 10.0
    " let g:neovide_cursor_vfx_particle_phase = 1.2
    " let g:neovide_cursor_vfx_particle_curl = 0.8

endif

let mapleader = "\\"
let maplocalleader = "\\\\"

" let g:clipboard = {
"             \ 'name': 'termux',
"             \ 'copy': {
"                 \ '+': 'termux-clipboard-set',
"                 \ '*': 'termux-clipboard-set',
"             \ },
"             \ 'paste': {
"                 \ '+': 'termux-clipboard-get',
"                 \ '*': 'termux-clipboard-get',
"             \ },
"             \ 'cache_enabled': 0,
"             \ }

let g:clipboard = {
            \ 'name': 'wayland',
            \ 'copy': {
                \ '+': 'wl-copy',
                \ '*': 'wl-copy',
            \ },
            \ 'paste': {
                \ '+': 'wl-paste',
                \ '*': 'wl-paste',
            \ },
            \ 'cache_enabled': 0,
            \ }

iabbrev @@ DreamOneX <me@dreamonex.eu.org>
iabbrev vim: vim:ft=bash:fdm=marker
iabbrev shebang #!/usr/bin/env

nnoremap <leader>pp :set paste!<CR>
nnoremap <leader>lc :set cursorcolumn!<CR>
tnoremap <ESC><ESC><ESC><ESC> <C-\><C-n>

nnoremap <silent> <leader>ev :split $MYVIMRC<CR>
nnoremap <silent> <leader>rl :source $MYVIMRC<CR>
nnoremap <silent> <leader>evd :e $MYVIMRC<CR>
nnoremap <silent> <space>r :set relativenumber!<CR>
nnoremap <silent> <space><space>wh :help <c-R><c-W><CR>

nnoremap <silent> <C-k> :NERDTreeToggle<CR>
nnoremap <silent> <C-h> :NERDTreeFind<CR>
nnoremap <silent> <C-j> :NERDTreeRefreshRoot<CR>

" noremap -= <ESC>
" inoremap -= <ESC>

inoremap <M-k> <Up>
inoremap <M-j> <Down>
inoremap <M-h> <Left>
inoremap <M-l> <Right>

inoremap <silent> <C-z> <C-o><C-z>

nnoremap <Leader>expt :%s/	/    /g<CR>

command! -nargs=+ -complete=command YankErr call s:yank_err(<f-args>)

function! s:yank_err(...) abort
    let l:args = a:000

    if len(l:args) > 1 && l:args[0] =~ '^["+*a-zA-Z0-9]$'
        let l:reg = l:args[0]
        let l:cmd = join(l:args[1:], ' ')
    else
        let l:reg = '"'
        let l:cmd = join(l:args, ' ')
    endif

    try
        execute l:cmd
    catch /.*/
        execute 'let @' . l:reg . ' = v:exception'
        echom 'Error yanked to register ' . l:reg
    endtry
endfunction

let g:clipboard_enabled = 0

function! ToggleClipboardYankPaste() abort
  if g:clipboard_enabled
    " 恢复默认映射
    silent! unmap y
    silent! unmap p
    silent! unmap Y
    silent! unmap P
    let g:clipboard_enabled = 0
    echo '📋 剪贴板模式已关闭（y/p 不影响系统剪贴板）'
  else
    " 只映射 y 和 p 到系统剪贴板
    nnoremap y "+y
    nnoremap Y "+Y
    nnoremap p "+p
    nnoremap P "+P
    vnoremap y "+y
    vnoremap p "+p
    let g:clipboard_enabled = 1
    echo '📋 剪贴板模式已启用（y/p 映射到系统剪贴板）'
  endif
endfunction

command! ToggleClipboardYankPaste call ToggleClipboardYankPaste()
nnorema <leader>tc :ToggleClipboardYankPaste<CR>

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
" Plug 'ActivityWatch/aw-watcher-vim'

Plug 'majutsushi/tagbar'                            " ctags
Plug 'Yggdroot/LeaderF', { 'do': './install.sh'  }  " 搜索
" Plug 'jiangmiao/auto-pairs'                         " 括号
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
Plug 'monaqa/dial.nvim'                             " C-a C-x 增强
Plug 'tpope/vim-surround'                           " surround
Plug 'freitass/todo.txt-vim'                        " todo.txt
Plug 'justinmk/vim-sneak'                           " 2 字母ft
Plug 'unblevable/quick-scope'                       " ft highlight
Plug 'purofle/vim-mindustry-logic'

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

Plug 'neoclide/coc-lists', { 'do': 'yarn install --frozen-lockfile' }
call plug#end()
"vim-plug end

colorscheme atom-dark

" let g:AutoPairs = {'(':')', '[':']', '{':'}',"'":"'",'"':'"', '<':'>'}
" if vimscript, dont include "
" augroup AutoPairs
"     autocmd!
"     autocmd FileType nerdtree,tagbar let b:AutoPairs = {}
"     autocmd FileType vim let b:AutoPairs = {'(':')', '[':']', '{':'}',"'":"'"}
" augroup END

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

let g:rainbow_conf = {
        \   'separately': {
        \       'nerdtree': 0,
    \   }
    \}
let g:rainbow_active = 1

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

let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#left_alt_sep = '|'
let g:airline#extensions#tabline#buffer_nr_show = 0
let g:airline#extensions#tabline#formatter = 'default'
" let g:airline_theme = 'badwolf'  " 主题
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

" copilot
" let g:copilot_node_command = "~/.vim/local/node16/bin/node"
imap <silent><script><expr> <M-t> copilot#Accept("\<CR>")
imap <silent> <M-n> <Plug>(copilot-next)
imap <silent> <M-p> <Plug>(copilot-prev)
let g:copilot_no_tab_map = v:true

" ZFVimIm
" let g:zf_git_user_email='me@dreamonex.eu.org'
" let g:zf_git_user_name='DreamOneX'
" let g:zf_git_user_token='¿'
" let g:ZFVimIM_keymap=0

" 更改快捷键
map <space> <Plug>(easymotion-prefix)
nmap <space>f <Plug>(easymotion-s)
nmap <space>l <Plug>(easymotion-lineforward)
nmap <space>j <Plug>(easymotion-j)
nmap <space>k <Plug>(easymotion-k)
nmap <space>h <Plug>(easymotion-linebackward)
nmap <space>s <Plug>(easymotion-s2)
nmap <space>ns <plug>(easymotion-sn)
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
inoremap <silent><expr> <M-f> coc#pum#visible() ? coc#pum#confirm()
                              \: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"

" if coc#pum#visible(), <ESC> will close the completion menu
inoremap <silent><expr> <M-q>
      \ coc#pum#visible() ? coc#pum#cancel() :
      \ "\<M-q>"

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

augroup coc
    autocmd!
    " Highlight symbol under cursor on CursorHold
    autocmd CursorHold * silent call CocActionAsync('highlight')
    " Show documentation on CursorHold
    " autocmd CursorHold * silent call ShowDocumentation()
    " Show signature help on CursorHold
    " autocmd CursorHold * silent call CocActionAsync('signatureHelp')
    " Show diagnostics on CursorHold
    " autocmd CursorHold * silent call CocActionAsync('diagnosticList')
    " Show code actions on CursorHold
    " autocmd CursorHold * silent call CocActionAsync('codeAction', 'source')
augroup END

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

" " Use <C-l> for trigger snippet expand.
" imap <C-l> <Plug>(coc-snippets-expand)
"
" " Use <C-j> for select text for visual placeholder of snippet.
" vmap <C-j> <Plug>(coc-snippets-select)
"
" " Use <C-j> for jump to next placeholder, it's default of coc.nvim
" let g:coc_snippet_next = '<c-j>'
"
" " Use <C-k> for jump to previous placeholder, it's default of coc.nvim
" let g:coc_snippet_prev = '<c-k>'
"
" " Use <C-j> for both expand and jump (make expand higher priority.)
" imap <C-j> <Plug>(coc-snippets-expand-jump)
"
" " Use <leader>x for convert visual selected code to snippet
" xmap <leader>x  <Plug>(coc-convert-snippet)

" let g:coc_snippet_next = '<tab>'

nmap <Leader>tp <Plug>(coc-translator-p)
vmap <Leader>tp <Plug>(coc-translator-pv)

nmap <Leader>te <Plug>(coc-translator-e)
vmap <Leader>te <Plug>(coc-translator-ev)

nmap <Leader>tr <Plug>(coc-translator-r)
vmap <Leader>tr <Plug>(coc-translator-rv)

nnoremap <silent> <space><space>oc :CocList<CR>

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
let g:Lf_HiddenFiles = 1
let g:Lf_ShowDevIcons = 1
let g:Lf_UseVersionControl = 1
let g:Lf_PopupShowBorder = 0
let g:Lf_PopupBorders = [' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ']
let g:Lf_PreviewResultSyntax = 1

nnoremap <silent> <space><space>r :Leaderf rg<CR>
nnoremap <silent> <space><space>l :LeaderfLine<CR>
nnoremap <silent> <space><space>f :LeaderfFile<CR>
nnoremap <silent> <space><space>b :LeaderfBuffer<CR>
nnoremap <silent> <space><space>m :LeaderfMru<CR>
nnoremap <silent> <space><space>t :LeaderfTag<CR>
nnoremap <silent> <space><space>i :LeaderfFunction<CR>
nnoremap <silent> <space><space>cl :LeaderfLineCword<CR>
nnoremap <silent> <space><space>cf :LeaderfFileCword<CR>
nnoremap <silent> <space><space>cb :LeaderfBufferCword<CR>
nnoremap <silent> <space><space>cm :LeaderfMruCword<CR>
nnoremap <silent> <space><space>ct :LeaderfTagCword<CR>
nnoremap <silent> <space><space>ci :LeaderfFunctionCword<CR>

" Mundo
nnoremap <leader>ms :MundoShow<CR>
nnoremap <leader>mh :MundoHide<CR>

" ale
let b:ale_linters = ['flake8', 'pylint', 'ktlint']
let b:ale_fixers = ['autopep8', 'yapf']
let g:ale_disable_lsp = 1

let g:ale_python_pylint_options = '-d=line-too-long -d=missing-function-docstring -d=missing-module-docstring --good-names i,j,k,f,e,s,r,a,b,c,d,fg,bg'
let g:ale_python_flake8_options = '--ignore E501'

" signature
nnoremap <leader>sr :SignatureRefresh<CR>
nnoremap <leader>st :SignatureToggleSigns<CR>

" markdown
let g:vim_markdown_conceal = 0
let g:vim_markdown_conceal_code_blocks = 0
let g:vim_markdown_folding_disabled = 1
let g:vim_markdown_frontmatter = 1

" quick scope
let g:qs_highlight_on_keys = ['f', 'F', 't', 'T', 's', 'S']
let g:qs_buftype_blacklist = ['terminal', 'nofile']
let g:qs_filetype_blacklist = ['dashboard', 'startify', 'nerdtree']
augroup qs_color
    autocmd!
    autocmd ColorScheme * highlight QuickScopePrimary guifg='#afff5f' gui=underline ctermfg=155 cterm=underline
    autocmd ColorScheme * highlight QuickScopeSecondary guifg='#5fffff' gui=underline ctermfg=81 cterm=underline
augroup END

" dial.nvim
nmap  <C-a>  <Plug>(dial-increment)
nmap  <C-x>  <Plug>(dial-decrement)
vmap  <C-a>  <Plug>(dial-increment)
vmap  <C-x>  <Plug>(dial-decrement)
vmap g<C-a> g<Plug>(dial-increment)
vmap g<C-x> g<Plug>(dial-decrement)

lua << EOF
local augend = require("dial.augend")
require("dial.config").augends:register_group{
  default = {
    augend.integer.alias.decimal_int,
    augend.integer.alias.hex,
    augend.integer.alias.binary,
    augend.date.alias["%Y/%m/%d"],
    augend.date.alias["%Y-%m-%d"],
    augend.date.alias["%Y年%-m月%-d日"],
    augend.date.alias["%Y年%-m月%-d日(%ja)"],
    augend.date.alias["%H:%M:%S"],
    augend.date.alias["%H:%M"],
    augend.date.new{
        pattern = "%Y.%m.%d",
        default_kind = "day",
        only_valid = true,
        word = false,
    },
    augend.constant.alias.bool,
    augend.constant.new{
      elements = {"False", "True"},
      word = true,
      cyclic = true,
    },
    augend.constant.new{
      elements = {"and", "or"},
      word = true,
      cyclic = true,
    },
    augend.constant.new{
      elements = {"&&", "||"},
      word = false,
      cyclic = true,
    },
    augend.semver.alias.semver,
    augend.constant.new{
        elements = {"tcp", "udp"},
        word = true,
        cyclic = true,
    }
  },
  visual = {
    augend.integer.alias.decimal_int,
    augend.integer.alias.hex,
    augend.integer.alias.binary,
    augend.date.alias["%Y/%m/%d"],
    augend.date.alias["%Y-%m-%d"],
    augend.date.alias["%Y年%-m月%-d日"],
    augend.date.alias["%Y年%-m月%-d日(%ja)"],
    augend.date.alias["%H:%M:%S"],
    augend.date.alias["%H:%M"],
    augend.date.new{
        pattern = "%Y.%m.%d",
        default_kind = "day",
        only_valid = true,
        word = false,
    },
    augend.constant.alias.bool,
    augend.semver.alias.semver,
    augend.constant.alias.alpha,
    augend.constant.alias.Alpha,
  },
}

-- change augends in VISUAL mode
vim.keymap.set("v", "<C-a>", require("dial.map").inc_visual("visual"), {noremap = true})
vim.keymap.set("v", "<C-x>", require("dial.map").dec_visual("visual"), {noremap = true})
EOF
