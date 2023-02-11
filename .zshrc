typeset -g POWERLEVEL9K_INSTANT_PROMPT=off
#Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
typeset -x XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
# Lines configured by zsh-newuser-install
HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=1000000
ENABLE_CORRECTION="true"
COMPLETION_WAITING_DOTS="true"

autoload -U run-help
autoload run-help-git
autoload run-help-svn
autoload run-help-svk
unalias run-help
alias help=run-help

# setopt autocd beep extendedglob nomatch notify
## Options section
setopt correct                                                  # Auto correct mistakes
setopt extendedglob                                             # Extended globbing. Allows using regular expressions with *
setopt nocaseglob                                               # Case insensitive globbing
setopt rcexpandparam                                            # Array expension with parameters
setopt nocheckjobs                                              # Don't warn about running processes when exiting
setopt numericglobsort                                          # Sort filenames numerically when it makes sense
setopt nobeep                                                   # No beep
setopt appendhistory                                            # Immediately append history instead of overwriting
setopt histignorealldups                                        # If a new command is a duplicate, remove the older one
setopt autocd                                                   # if only directory path is entered, cd there.
setopt inc_append_history                                       # save commands are added to the history immediately, otherwise only when shell exits.
setopt histignorespace                                          # Don't save commands that start with space
bindkey -e
bindkey '^[[7~' beginning-of-line                               # Home key
bindkey '^[[H' beginning-of-line                                # Home key
if [[ "${terminfo[khome]}" != "" ]]; then
  bindkey "${terminfo[khome]}" beginning-of-line                # [Home] - Go to beginning of line
fi
bindkey '^[[8~' end-of-line                                     # End key
bindkey '^[[F' end-of-line                                     # End key
if [[ "${terminfo[kend]}" != "" ]]; then
  bindkey "${terminfo[kend]}" end-of-line                       # [End] - Go to end of line
fi
bindkey '^[[2~' overwrite-mode                                  # Insert key
bindkey '^[[3~' delete-char                                     # Delete key
bindkey '^[[C'  forward-char                                    # Right key
bindkey '^[[D'  backward-char                                   # Left key
bindkey '^[[5~' history-beginning-search-backward               # Page up key
bindkey '^[[6~' history-beginning-search-forward                # Page down key

# Navigate words with ctrl+arrow keys
bindkey '^[Oc' forward-word                                     #
bindkey '^[Od' backward-word                                    #
bindkey '^[[1;5D' backward-word                                 #
bindkey '^[[1;5C' forward-word                                  #
bindkey '^H' backward-kill-word                                 # delete previous word with ctrl+backspace
bindkey '^[[Z' undo                                             # Shift+tab undo last action
# End of lines configured by zsh-newuser-install
# The following lines were added by compinstall
zstyle :compinstall filename '/home/dreamonex/.zshrc'
zstyle ':completion:*' rehash true

autoload -Uz compinit
compinit
# End of lines added by compinstall

### Added by Zinit's installer
if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
    print -P "%F{33} %F{220}Installing %F{33}ZDHARMA-CONTINUUM%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
    command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"
    command git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git" && \
        print -P "%F{33} %F{34}Installation successful.%f%b" || \
        print -P "%F{160} The clone has failed.%f%b"
fi

source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# Load a few important annexes, without Turbo
# (this is currently required for annexes)
zinit light-mode for \
    zdharma-continuum/zinit-annex-as-monitor \
    zdharma-continuum/zinit-annex-bin-gem-node \
    zdharma-continuum/zinit-annex-patch-dl \
    zdharma-continuum/zinit-annex-rust

### End of Zinit's installer chunk



zinit light Aloxaf/fzf-tab && enable-fzf-tab
# disable sort when completing `git checkout`
zstyle ':completion:*:git-checkout:*' sort false
# set descriptions format to enable group support
zstyle ':completion:*:descriptions' format '[%d]'
# set list-colors to enable filename colorizing
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
# preview directory's content with exa when completing cd
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'exa -1 --color=always $realpath'
# switch group using `,` and `.`
zstyle ':fzf-tab:*' switch-group ',' '.'
#历史搜索
zinit light zsh-users/zsh-history-substring-search

# Load Oh MY Zsh Plugins
#git alias
zinit snippet OMZ::plugins/git/git.plugin.zsh
#解压
zinit snippet OMZ::plugins/extract/extract.plugin.zsh
#history格式化及alias
zinit snippet OMZ::lib/history.zsh
#如果命令不存在，会提醒你可能缺失的依赖
zinit snippet OMZ::plugins/command-not-found/command-not-found.plugin.zsh
#sudo
zinit snippet OMZ::plugins/sudo/sudo.plugin.zsh

eval "$(zoxide init zsh)"


# Zinit Ice Load
#p10k主题
zinit ice depth=1; zinit light romkatv/powerlevel10k
#命令高亮
zinit ice lucid wait='0' atinit='zpcompinit'; zinit light zdharma/fast-syntax-highlighting
#命令补全建议
zinit ice wait lucid atload'_zsh_autosuggest_start'; zinit light zsh-users/zsh-autosuggestions
#命令补全
zinit ice lucid wait='0'; zinit light zsh-users/zsh-completions
#Alias提醒
zinit ice lucid wait='0'; zinit light djui/alias-tips


# 配置
#历史搜索
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
typeset -g HISTORY_SUBSTRING_SEARCH_PREFIXED=1

[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

alias ...=../..
alias ....=../../..
alias .....=../../../..
alias ......=../../../../..
alias _='sudo '
alias afind='ack -il'
# alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'
alias gc1='git clone --recursive --depth=1'
alias globurl='noglob urlglobber '
alias grep='grep --color=auto'
alias md='mkdir -p'
alias rd=rmdir
alias ls="exa --color=auto" 
# Exa is a modern version of ls. exa是一款优秀的ls替代品,拥有更好的文件展示体验,输出结果更快,使用rust编写。
alias l='exa -lbah'
alias la='exa -labgh'
alias ll='exa -lbg'
alias lsa='exa -lbagR'
alias lst='exa -lTabgh' # 输入lst,将展示类似于tree的树状列表。
alias lls='/bin/ls --color=auto'
# color should not be always.
alias llst='tree -pCsh'
alias lll='lls -lah'
alias lla='lls -lAh'
alias lllll='lls -lh'
alias llsa='lls -lah'

alias superexa='exa -laghHimSuU --changed --time-style full-iso --octal-permissions --git --icons --extended'

alias lcat=/bin/cat
# bat supports syntax highlighting for a large number of programming and markup languages. bat是cat的替代品，支持多语言语法高亮。
alias cat="bat -pp"
typeset -g BAT_PAGER="less -m -RFQ"
alias sr='screen -r'
alias lcat=/bin/cat

alias fd='fd -HI'

alias p='proxychains -q'
alias sp="paru -Sl | fzf | awk '{print \$2}'"

eval $(thefuck --alias)
# You can use whatever you want as an alias, like for Mondays:
eval $(thefuck --alias FUCK)
export GPG_TTY=$(tty)
export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
echo UPDATESTARTUPTTY | gpg-connect-agent 1> /dev/null

export LESS_TERMCAP_mb=$'\E[01;34m'
export LESS_TERMCAP_md=$'\E[01;34m'
export LESS_TERMCAP_me=$'\E[0m'
export LESS_TERMCAP_us=$'\E[01;32m'
export LESS_TERMCAP_ue=$'\E[0m'
export LESS_TERMCAP_so=$'\E[01;33;44m'
export LESS_TERMCAP_se=$'\E[0m'
export VISUAL=nvim

alias rsync=srsync
function cpr() {
  rsync --archive -hh --partial --info=stats1,progress2 --modify-window=1 "$@"
} 
function mvr() {
  rsync --archive -hh --partial --info=stats1,progress2 --modify-window=1 --remove-source-files "$@"
}

function unicodeof() {
    for i in $(echo "$*" | sed 's/\(.\)/\1 /g'); do
        printf "%s\tU+%04X\n" "$i" "'$i"
    done
}

function new() {
    for i in "$@"; do
        mkdir -p "${i%/*}"
        touch "$i"
    done
}

function fzfparu() {
    paru -Sl | fzf -m --preview 'paru -Si {2}' | awk '{print $2}' | tr '\n' ' ' | xargs -or paru -S
}

alias t='todo.sh'
source /home/dreamonex/.config/broot/launcher/bash/br
. "/home/dreamonex/.acme.sh/acme.sh.env"
