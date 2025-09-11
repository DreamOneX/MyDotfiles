# vim:ft=bash:foldmethod=marker

source $HOME/.profile
source $HOME/.shell_profile_res/shell-colors.sh

# {{{ VARIABLES

# {{{ HISTORY
export HISTCONTROL="ignoreboth"
export HISTSIZE=100000
export HISTTIMEFORMAT="%F %T "
# }}}

# {{{ PAGER
# export PAGER=
# export MANPAGER=manbat
# }}}

# {{{ LESS BEAUTIFY
export LESS_TERMCAP_mb=$'\E[01;34m'
export LESS_TERMCAP_md=$'\E[01;34m'
export LESS_TERMCAP_me=$'\E[0m'
export LESS_TERMCAP_us=$'\E[01;32m'
export LESS_TERMCAP_ue=$'\E[0m'
export LESS_TERMCAP_so=$'\E[01;33;44m'
export LESS_TERMCAP_se=$'\E[0m'
# }}}

# }}}

# {{{ EXTERNAL
source $PREFIX/share/bash-completion/bash_completion
eval "$(fzf --bash)"
# }}}

# {{{ FUNCTIONS

# {{{ run-help
# Thanks to Arch Wiki :)
run-help() { help "$READLINE_LINE" 2>/dev/null || man "$READLINE_LINE"; }
# }}}

# {{{ path_prompt_generate
path_prompt_generate() {
  local fullpath="$PWD"
  local IFS='/'
  read -ra parts <<< "$fullpath"

  local HEAD_COUNT=2         # 头部完整保留的目录数量
  local TAIL_COUNT=2         # 尾部完整保留的目录数量
  local ABBREV_LEN=1         # 中间目录缩写保留几个字母

  local total=${#parts[@]}
  local result=""

  # 边界检查：如果目录层级太少，就直接返回原路径
  if (( total <= HEAD_COUNT + TAIL_COUNT )); then
    echo "$fullpath"
    return
  fi

  # 保留头部完整目录
  for ((i=0; i<HEAD_COUNT; i++)); do
    [[ -n "${parts[i]}" ]] && result+="/${parts[i]}"
  done

  # 缩写中间目录
  for ((i=HEAD_COUNT; i<total-TAIL_COUNT; i++)); do
    if [[ -n "${parts[i]}" ]]; then
      result+="/${parts[i]:0:ABBREV_LEN}"
    fi
  done

  # 保留尾部完整目录
  for ((i=total-TAIL_COUNT; i<total; i++)); do
    [[ -n "${parts[i]}" ]] && result+="/${parts[i]}"
  done

  echo "$result"
}
# }}}

# {{{ manbat
# TODO: Buggy, need to fix
manbat() {
  local width=$(tput cols)
  local ll=$((width * 2))
  sed "1i\\.nf\n.ll ${ll}n" | groff -Tutf8 -mandoc | bat -l man --paging=always
}
# }}}

# {{{ skp
skp() {
    pkg list-all 2>/dev/null | fzf -m --preview 'pkg show $(echo {} | cut -d"/" -f1) 2>/dev/null' --height 80% --reverse --border --inline-info --preview-window=down:80% | cut -d'/' -f1 | xargs -or pkg install
}
# }}}

# {{{ rsync mvr/cpr
if command -v rsync >/dev/null 2>&1; then
  cpr() {
    rsync -a --info=stats1,progress2 --partial --modify-window=1 "$@"
  }
  mvr() {
    rsync -a --info=stats1,progress2 --partial --modify-window=1 --remove-source-files "$@"
  }
fi
# }}}

# }}}

# {{{ BINDINGS
bind -m vi-insert -x '"\eh": run-help'
bind -m emacs -x     '"\eh": run-help'
# }}}

# {{{ ALIASES

# {{{ dots cd
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ......='cd ../../../../..'
# }}}

# {{{ grep
alias grep='grep --color=auto'
alias egrep='grep -irlE'
alias fgrep='grep -irlF'
if command -v rg >/dev/null 2>&1; then
    alias afind='rg -il'
elif command -v ack >/dev/null 2>&1; then
    alias afind='ack -il'
else
    alias afind='grep -irl'
fi
# }}}

alias gc1='git clone --recursive --depth=1'
alias globurl='noglob urlglobber '
alias md='mkdir -p'
alias rd=rmdir

# {{{ ls
if command -v eza >/dev/null 2>&1; then
  alias ls="eza --color=auto"
  alias l='eza -lbah'
  alias la='eza -labgh'
  alias ll='eza -lbg'
  alias lsa='eza -lbagR'
  alias lst='eza -lTabgh'  # Tree-style view
  alias lls='/bin/ls --color=auto'
  alias llst='tree -pCsh'
  alias lll='lls -lah'
  alias lla='lls -lAh'
  alias lllll='lls -lh'
  alias llsa='lls -lah'
  alias supereza='eza -laghHimSuU --changed --time-style full-iso --octal-permissions --git --icons --extended'
else
  echo -e "${YELLOW}${BOLD}[WARN] eza not found. Falling back to ls.${NC}"

  alias ls='ls --color=auto'
  alias l='ls -lah'
  alias la='ls -lah'
  alias ll='ls -lh'
  alias lsa='ls -lR'
  alias lls='ls --color=auto'
  alias lll='ls -lah'
  alias lla='ls -lAh'
  alias lllll='ls -lh'
  alias llsa='ls -lah'
  alias supereza='ls -lah'

  if command -v tree >/dev/null 2>&1; then
    alias lst='tree -Csh'
    alias llst='tree -pCsh'
  else
    echo -e "${YELLOW}${BOLD}[WARN] tree not found. lst/llst disabled.${NC}"
    alias lst='echo -e \"${YELLOW}${BOLD}[WARN] tree not found. lst unavailable.${NC}\"'
    alias llst='echo -e \"${YELLOW}${BOLD}[WARN] tree not found. llst unavailable.${NC}\"'
  fi
fi
# }}}

# {{{ cat
if command -v bat >/dev/null 2>&1; then
    alias cat='bat -pp'
    alias lcat='/bin/cat'
else
    echo -e "${YELLOW}${BOLD}[WARN] bat not found. Falling back to cat.${NC}"
fi
# }}}

alias ghcs='gh copilot suggest'

# }}}

# {{{ pnpm
export PNPM_HOME="/data/data/com.termux/files/home/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end }}}

eval $(zoxide init bash)
