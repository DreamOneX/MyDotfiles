# vim:ft=bash:foldmethod=marker

# {{{ bash-completion
if [ -v BASH_COMPLETION ] && [ -r "$BASH_COMPLETION" ]; then
    source "$BASH_COMPLETION"
elif [ -v PREFIX ] && [ -r "$PREFIX/share/bash_completion/bash_completion" ]; then
    source "$PREFIX/share/bash-completion/bash_completion"
elif [ -v TERMUX_VERSION ] && [ -r "/data/data/com.termux/files/usr/share/bash-completion/bash_completion" ]; then
    source "/data/data/com.termux/files/usr/share/bash-completion/bash_completion"
elif [ -r "/usr/share/bash-completion/bash_completion" ]; then
    source "/usr/share/bash-completion/bash_completion"
else
    echo -e "${YELLOW}${BOLD}[WARN] bash-completion not found. bash-completion unavailable.${NC}"
fi
# }}}

# {{{ fzf
if command -v fzf >/dev/null 2>&1; then
    eval "$(fzf --bash)"
else
    echo -e "${YELLOW}${BOLD}[WARN] fzf not found. fzf unavailable.${NC}"
fi
# }}}

# {{{ zoxide
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init bash)"
else
    echo -e "${YELLOW}${BOLD}[WARN] zoxide not found. zoxide unavailable.${NC}"
fi
# }}}
