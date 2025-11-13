#!/usr/bin/env bash
# vim:ft=bash:fdm=marker

# TODO: testworkplace manager

# {{{ TEST_WORKPLACE_ROOT
# TEST_WORKPLACE_ROOT is used by function tw to set LOCAL var
: "${TEST_WORKSPACE_ROOT:=$HOME/test_workspace}"
# }}}

tw() {
    # Here is a simple convention of the command format, which may not be followed strictly:
    # tw [DATE] [INDEX] [ -m | --message "message" ] [ -M | --multi ] [ --git | --vcs ]
    local ROOT="${TEST_WORKSPACE_ROOT:-$HOME/test_workspace}"
    local date_arg=""
    local index_arg=""
    local multi=0
    local vcs=0
    local comment=""

    # arg parser
    while [ $# -gt 0 ]; do
        case "$1" in
            -m|--multi) multi=1; shift ;;
            --git|--vcs) vcs=1; shift ;;
            today|yesterday|[0-9]*) if [ -z "$date_arg" ]; then
                date_arg="$1"; shift; continue
            fi ;;&
            [0-9]*) if [ -z "$date_arg" ]; then
                echo -e "${RED}${BOLD}[ERROR] Date argument must be set before index argument.${NC}"
                return 1
            fi
            index_arg="$1"; shift ;;
            -c|--comment|--message) if [ $# -lt 2 ]; then
                echo -e "${RED}${BOLD}[ERROR] $1 requires an argument.${NC}"
                return 1
            fi
            comment="$2"; shift 2 ;;
            *) echo -e "${RED}${BOLD}[ERROR] Unknown argument: $1${NC}"; return 1 ;;
        esac
    done

    # debug
    echo "date_arg: $date_arg"
    echo "index_arg: $index_arg"
    echo "multi: $multi"
    echo "vcs: $vcs"
    echo "comment: $comment"
}
