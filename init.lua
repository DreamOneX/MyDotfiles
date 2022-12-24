vim.cmd('filetype plugin indent on')
vim.o.compatible = false

print('(≧▽≦) NeoVim is starting...')
vim.o.backspace = 'indent,eol,start'
vim.o.shell = '/usr/bin/zsh'
vim.cmd('syntax on')
vim.o.number = true
vim.o.mouse = 'a'
vim.o.laststatus = 2
vim.o.ambiwidth = 'double'
vim.o.t_Co = 256
vim.o.history = 10000
vim.o.autoindent = true
vim.o.cindent= true
vim.o.tabstop = 4
vim.o.expandtab = true
vim.o.shiftwidth = 4
vim.o.incsearch = true
vim.o.smartindent = true
vim.o.hlsearch = true
vim.o.undofile = true
vim.o.undodir = '~/.vim/undo'
vim.o.cursorline = true
vim.o.ic = true
vim.o.background = 'dark'

vim.o.signcolumn = 'yes'
vim.o.updatetime = 300
