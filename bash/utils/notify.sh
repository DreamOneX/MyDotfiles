#!/usr/bin/env bash
# vim:ft=bash:foldmethod=marker
# desc: Small persistent notification counters for Bash startup files

# {{{ Configuration

# {{{ BASH_NOTIFY_STATE_DIR
# BASH_NOTIFY_STATE_DIR:
#   directory used to remember limited startup notifications
#   default: ${XDG_STATE_HOME:-$HOME/.local/state}/bash-notify
: "${BASH_NOTIFY_STATE_DIR:=${XDG_STATE_HOME:-$HOME/.local/state}/bash-notify}"
# }}}

# {{{ BASH_NOTIFY_DEFAULT_LIMIT
# BASH_NOTIFY_DEFAULT_LIMIT:
#   default number of times a limited notification may be shown
#   default: 3
: "${BASH_NOTIFY_DEFAULT_LIMIT:=3}"
# }}}

# }}}

_bash_notify_key_path() {
    local key="$1"

    key="${key//[^[:alnum:]_.-]/_}"
    [ -n "$key" ] || key="notification"
    printf '%s/%s.count\n' "$BASH_NOTIFY_STATE_DIR" "$key"
}

bash_notify_should_show() {
    local key="${1:-}"
    local limit="${2:-$BASH_NOTIFY_DEFAULT_LIMIT}"
    local path count

    [ "$#" -ge 1 ] || return 2

    [[ "$limit" =~ ^[0-9]+$ ]] || limit="$BASH_NOTIFY_DEFAULT_LIMIT"
    [[ "$limit" =~ ^[0-9]+$ ]] || limit=3
    [ "$limit" -gt 0 ] || return 1

    path="$(_bash_notify_key_path "$key")"
    mkdir -p -- "$BASH_NOTIFY_STATE_DIR" 2>/dev/null || return 0

    if [ -r "$path" ]; then
        IFS= read -r count < "$path" || count=0
    else
        count=0
    fi
    [[ "$count" =~ ^[0-9]+$ ]] || count=0

    [ "$count" -lt "$limit" ] || return 1
    printf '%s\n' "$((count + 1))" > "$path" 2>/dev/null || true
    return 0
}
