#!/usr/bin/env bash
# vim:ft=bash:foldmethod=marker

# {{{ Configuration

# {{{ TEST_WORKSPACE_ROOT
# TEST_WORKSPACE_ROOT:
#   root directory shared by all tw workspaces
#   default: $HOME/test_workspace
: "${TEST_WORKSPACE_ROOT:=$HOME/test_workspace}"
# }}}

# {{{ TW_VCS_DEFAULT
# TW_VCS_DEFAULT:
#   whether new tw workspaces should run git init by default
#   default: 1
: "${TW_VCS_DEFAULT:=1}"
# }}}

# {{{ TW_DATE_LIMIT_MONTHS
# TW_DATE_LIMIT_MONTHS:
#   month window for short-date workspace matching
#   default: 12
: "${TW_DATE_LIMIT_MONTHS:=12}"
# }}}

# }}}

_tw_date_comment_requested() {
    local saw_date=0

    while [ "$#" -gt 0 ]; do
        case "$1" in
            --vcs|--git|--no-vcs|--no-git)
                shift
                ;;
            comment|-c|--comment|--message)
                [ "$saw_date" -eq 1 ] && return 0
                return 1
                ;;
            -*)
                return 1
                ;;
            *)
                saw_date=1
                shift
                ;;
        esac
    done

    return 1
}

tw() {
    local dir cmd utils_dir
    local -a tw_cmd

    utils_dir="${__BASH_DOTFILES_DIR:-$(cd -P "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
    tw_cmd=("$utils_dir/utils/tw.sh")
    tw_cmd=(env \
        "TEST_WORKSPACE_ROOT=$TEST_WORKSPACE_ROOT" \
        "TW_VCS_DEFAULT=$TW_VCS_DEFAULT" \
        "TW_DATE_LIMIT_MONTHS=$TW_DATE_LIMIT_MONTHS" \
        "${tw_cmd[@]}")
    cmd="${1:-}"

    case "$cmd" in
        -h|--help|help|ls|list|path|root)
            "${tw_cmd[@]}" "$@"
            ;;
        comment)
            dir="$("${tw_cmd[@]}" "$@")" || return
            printf 'tw: %s\n' "$dir"
            cd -- "$dir" || return
            ;;
        new|-m|--multi)
            dir="$("${tw_cmd[@]}" "$@")" || return
            printf 'tw: %s\n' "$dir"
            cd -- "$dir" || return
            ;;
        *)
            if _tw_date_comment_requested "$@"; then
                "${tw_cmd[@]}" "$@"
                return
            fi

            dir="$("${tw_cmd[@]}" "$@")" || return
            printf 'tw: %s\n' "$dir"
            cd -- "$dir" || return
            ;;
    esac
}
