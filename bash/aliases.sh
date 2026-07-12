# vim:ft=bash:foldmethod=marker

# {{{ notify
if ! declare -F bash_notify_should_show >/dev/null 2>&1; then
    _ALIASES_DIR="${SCRIPT_DIR:-$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
    [ -r "$_ALIASES_DIR/utils/notify.sh" ] && source "$_ALIASES_DIR/utils/notify.sh"
    unset _ALIASES_DIR
fi

_alias_notify_should_show() {
    if declare -F bash_notify_should_show >/dev/null 2>&1; then
        bash_notify_should_show "${1:-}" "${2:-${BASH_NOTIFY_DEFAULT_LIMIT:-3}}"
        return $?
    fi

    return 0
}
# }}}

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
    if _alias_notify_should_show aliases.afind.ack; then
        echo -e "${YELLOW}${BOLD}[WARN] rg not found, but ack founded. afind falling back to ack${NC}"
    fi
    alias afind='ack -il'
else
    if _alias_notify_should_show aliases.afind.grep; then
        echo -e "${YELLOW}${BOLD}[WARN] rg/ack not found. afind falling back to grep.${NC}"
    fi
    alias afind='grep -irl'
fi
# }}}

# {{{ git
if command -v git >/dev/null 2>&1; then
    alias gc1='git clone --recursive --depth=1'
    alias gcl='git clone'
    alias gst='git status'
    alias gco='git checkout'
    alias gcb='git checkout -b'
    alias gca='git commit -a'
    alias gcam='git commit -a -m'
    alias gamend='git commit --amend'
    alias ga='git add'
    alias gaa='git add .'
    alias gp='git push'
    alias gl='git pull'
    alias gf='git fetch'
    alias gb='git branch'
    alias gbv='git branch -vv'
    alias glo='git log --oneline --graph --decorate --all'
    alias gss='git status -s'
    alias gd='git diff'
    alias gdc='git diff --cached'
    alias gundo='git reset --soft HEAD^'
    alias grhh='git reset --hard'
    alias grst='git reset --soft'
    alias gcln='git clone --no-checkout'
    alias gpr='git pull --rebase'
    alias gcp='git cherry-pick'
    alias gsta='git stash'
    alias gstp='git stash pop'
    alias gsts='git stash show --text'
    alias grb='git rebase'
    alias grbc='git rebase --continue'
    alias grba='git rebase --abort'
    alias grbs='git rebase --skip'
else
    if _alias_notify_should_show aliases.git.missing; then
        echo -e "${YELLOW}${BOLD}[WARN] git not found. Git aliases unavailable.${NC}"
    fi
fi
# }}}

# {{{ noglob
if command -v noglob >/dev/null 2>&1; then
    alias globurl='noglob urlglobber '
else
    if _alias_notify_should_show aliases.noglob.missing; then
        echo -e "${YELLOW}${BOLD}[WARN] noglob not found. globurl unavailable.${NC}"
    fi
fi
# }}}

# {{{ ls
if command -v exa >/dev/null 2>&1; then
    if command -v eza >/dev/null 2>&1 ; then
        if _alias_notify_should_show aliases.eza.exa_both; then
            echo -e "${YELLOW}${BOLD}[WARN] both exa and eza found. man, what can i say? eza will be used normally${NC}"
        fi
    else
        if _alias_notify_should_show aliases.eza.exa_compat; then
            echo -e "${YELLOW}${BOLD}[WARN] exa found, though eza is not installed. exa will be used as eza. some compatibility issues may be caused.${NC}"
        fi
        alias eza='exa'
    fi
    if _alias_notify_should_show aliases.eza.info; then
        echo -e "${BLUE}${BOLD}[INFO] eza is a fork of exa, serving as its maintained successor${NC}"
    fi
fi

if command -v eza >/dev/null 2>&1 ; then
  alias ls="eza --color=auto"
  alias l='eza -lbah'
  alias la='eza -labgh'
  alias ll='eza -lbg'
  alias lsa='eza -lbagR'
  alias lst='eza -lTabgh'  # Tree-style view
  alias lls='/bin/ls --color=auto'
  alias lll='lls -lah'
  alias lla='lls -lAh'
  alias lllll='lls -lh'
  alias llsa='lls -lah'
  alias supereza='eza -laghHimSuU --changed --time-style full-iso --octal-permissions --git --icons --extended'

  if command -v tree >/dev/null 2>&1; then
    alias llst='tree -Csh'
    alias lllst='tree -pCsh'
  else
    if _alias_notify_should_show aliases.tree.eza_missing; then
        echo -e "${YELLOW}${BOLD}[WARN] tree not found, though eza is installed. llst/lllst disabled. please use lst for tree-style view${NC}"
    fi
  fi

else
  if _alias_notify_should_show aliases.eza.missing; then
    echo -e "${YELLOW}${BOLD}[WARN] eza not found. Falling back to ls.${NC}"
  fi

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
    if _alias_notify_should_show aliases.tree.missing; then
        echo -e "${YELLOW}${BOLD}[WARN] tree not found. lst/llst disabled.${NC}"
    fi
  fi
fi
# }}}

# {{{ cat
if command -v bat >/dev/null 2>&1; then
    alias cat='bat -pp'
    alias lcat='/bin/cat'
else
    if _alias_notify_should_show aliases.bat.missing; then
        echo -e "${YELLOW}${BOLD}[WARN] bat not found. Falling back to cat.${NC}"
    fi
fi
# }}}

# {{{ fd
if command -v fd >/dev/null 2>&1; then
    alias fd='fd -HI'
else
    if _alias_notify_should_show aliases.fd.missing; then
        echo -e "${YELLOW}${BOLD}[WARN] fd not found. fd unavailable.${NC}"
    fi
fi
# }}}

# {{{ gh
if command -v gh >/dev/null 2>&1; then
    alias ghcs='gh copilot suggest'
else
    if _alias_notify_should_show aliases.gh.missing; then
        echo -e "${YELLOW}${BOLD}[WARN] gh not found. gh aliases unavailable.${NC}"
    fi
fi
# }}}

# {{{ todo.sh
if command -v todo.sh >/dev/null 2>&1; then
    alias t='todo.sh'
else
    if _alias_notify_should_show aliases.todo_sh.missing; then
        echo -e "${YELLOW}${BOLD}[WARN] todo.sh not found. todo aliases unavailable.${NC}"
    fi
fi
# }}}

alias md='mkdir -p'
alias rd=rmdir
