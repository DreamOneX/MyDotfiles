#!/usr/bin/env bash
# vim:ft=bash:foldmethod=marker

# Lightweight color palette for Bash startup files.
#
# COLOR_BACKEND:
#   auto = prefer tput when basic color support is available, else ANSI
#   tput = force tput; warn and fall back to ANSI when unavailable
#   ansi = force ANSI escape sequences
#
# COLOR_TRUECOLOR_MODE:
#   true   = force RGB()/RGB_BG() helpers on
#   false  = force RGB()/RGB_BG() helpers off
#   normal = enable only when COLORTERM or direct-color terminfo indicates support
#
# COLOR_COMPAT_MODE:
#   auto    = no forced downgrade
#   mono    = blank colors and attributes
#   basic8  = keep only the base 8 colors
#   basic16 = keep base 8 colors and bright foreground colors
#
# WHITE is normal white (ANSI 37 / tput setaf 7). Use BRIGHT_WHITE for
# bright white (ANSI 97 / tput setaf 15).

: "${COLOR_TRUECOLOR_MODE:=normal}"
: "${COLOR_COMPAT_MODE:=auto}"
: "${COLOR_BACKEND:=auto}"
: "${COLOR_DISABLE_LIST:=}"

# {{{ ANSI constants
ESC="$(printf '\033')"

ANSI_FG_BLACK="${ESC}[30m"
ANSI_FG_RED="${ESC}[31m"
ANSI_FG_GREEN="${ESC}[32m"
ANSI_FG_YELLOW="${ESC}[33m"
ANSI_FG_BLUE="${ESC}[34m"
ANSI_FG_MAGENTA="${ESC}[35m"
ANSI_FG_CYAN="${ESC}[36m"
ANSI_FG_WHITE="${ESC}[37m"
ANSI_FG_GRAY="${ESC}[90m"

ANSI_BRIGHT_BLACK="${ESC}[90m"
ANSI_BRIGHT_RED="${ESC}[91m"
ANSI_BRIGHT_GREEN="${ESC}[92m"
ANSI_BRIGHT_YELLOW="${ESC}[93m"
ANSI_BRIGHT_BLUE="${ESC}[94m"
ANSI_BRIGHT_MAGENTA="${ESC}[95m"
ANSI_BRIGHT_CYAN="${ESC}[96m"
ANSI_BRIGHT_WHITE="${ESC}[97m"

ANSI_BG_BLACK="${ESC}[40m"
ANSI_BG_RED="${ESC}[41m"
ANSI_BG_GREEN="${ESC}[42m"
ANSI_BG_YELLOW="${ESC}[43m"
ANSI_BG_BLUE="${ESC}[44m"
ANSI_BG_MAGENTA="${ESC}[45m"
ANSI_BG_CYAN="${ESC}[46m"
ANSI_BG_WHITE="${ESC}[47m"
ANSI_BG_RESET="${ESC}[49m"

ANSI_BG_BRIGHT_BLACK="${ESC}[100m"
ANSI_BG_BRIGHT_RED="${ESC}[101m"
ANSI_BG_BRIGHT_GREEN="${ESC}[102m"
ANSI_BG_BRIGHT_YELLOW="${ESC}[103m"
ANSI_BG_BRIGHT_BLUE="${ESC}[104m"
ANSI_BG_BRIGHT_MAGENTA="${ESC}[105m"
ANSI_BG_BRIGHT_CYAN="${ESC}[106m"
ANSI_BG_BRIGHT_WHITE="${ESC}[107m"

ANSI_BOLD="${ESC}[1m"
ANSI_DIM="${ESC}[2m"
ANSI_UNDERLINE="${ESC}[4m"
ANSI_RESET="${ESC}[0m"
# }}}

# {{{ helpers
_color_warn() {
    printf '%s\n' "shell-colors: warning: $*" >&2
}

_color_is_uint() {
    [[ "${1:-}" =~ ^[0-9]+$ ]]
}

_color_in_csv() {
    case ",$2," in
        *,"$1",*) return 0 ;;
        *) return 1 ;;
    esac
}

_color_set_var() {
    printf -v "$1" '%s' "$2"
}

_color_blank_vars() {
    local _color_name
    for _color_name in "$@"; do
        _color_set_var "$_color_name" ''
    done
}

_color_tput() {
    local _color_cap="$1"
    shift
    tput "$_color_cap" "$@" 2>/dev/null
}

_color_tput_or_ansi() {
    local _color_var="$1"
    local _color_ansi="$2"
    local _color_cap="$3"
    shift 3
    local _color_value

    if $_use_tput; then
        _color_value="$(_color_tput "$_color_cap" "$@")"
        if [[ -n "$_color_value" ]]; then
            _color_set_var "$_color_var" "$_color_value"
            return 0
        fi
    fi

    _color_set_var "$_color_var" "$_color_ansi"
}
# }}}

# {{{ backend detection
_use_tput=false
_tput_colors=0
_tput_available=false

if command -v tput >/dev/null 2>&1 && [[ -n "${TERM:-}" ]]; then
    if tput sgr0 >/dev/null 2>&1; then
        _tput_available=true
        _tput_colors="$(tput colors 2>/dev/null || printf '0')"
        _color_is_uint "$_tput_colors" || _tput_colors=0
    fi
fi

case "$COLOR_BACKEND" in
    ansi)
        _use_tput=false
        ;;
    tput)
        if $_tput_available && ((_tput_colors >= 8)); then
            _use_tput=true
        else
            _color_warn "COLOR_BACKEND=tput requested but tput is unavailable; falling back to ANSI"
            _use_tput=false
        fi
        ;;
    auto|'')
        if $_tput_available && ((_tput_colors >= 8)); then
            _use_tput=true
        else
            _use_tput=false
        fi
        ;;
    *)
        _color_warn "unknown COLOR_BACKEND '$COLOR_BACKEND'; falling back to ANSI"
        _use_tput=false
        ;;
esac
# }}}

# {{{ palette
_color_tput_or_ansi BLACK "$ANSI_FG_BLACK" setaf 0
_color_tput_or_ansi RED "$ANSI_FG_RED" setaf 1
_color_tput_or_ansi GREEN "$ANSI_FG_GREEN" setaf 2
_color_tput_or_ansi YELLOW "$ANSI_FG_YELLOW" setaf 3
_color_tput_or_ansi BLUE "$ANSI_FG_BLUE" setaf 4
_color_tput_or_ansi MAGENTA "$ANSI_FG_MAGENTA" setaf 5
_color_tput_or_ansi CYAN "$ANSI_FG_CYAN" setaf 6
_color_tput_or_ansi WHITE "$ANSI_FG_WHITE" setaf 7

if ((_tput_colors >= 16)); then
    _color_tput_or_ansi GRAY "$ANSI_FG_GRAY" setaf 8
    _color_tput_or_ansi BRIGHT_BLACK "$ANSI_BRIGHT_BLACK" setaf 8
    _color_tput_or_ansi BRIGHT_RED "$ANSI_BRIGHT_RED" setaf 9
    _color_tput_or_ansi BRIGHT_GREEN "$ANSI_BRIGHT_GREEN" setaf 10
    _color_tput_or_ansi BRIGHT_YELLOW "$ANSI_BRIGHT_YELLOW" setaf 11
    _color_tput_or_ansi BRIGHT_BLUE "$ANSI_BRIGHT_BLUE" setaf 12
    _color_tput_or_ansi BRIGHT_MAGENTA "$ANSI_BRIGHT_MAGENTA" setaf 13
    _color_tput_or_ansi BRIGHT_CYAN "$ANSI_BRIGHT_CYAN" setaf 14
    _color_tput_or_ansi BRIGHT_WHITE "$ANSI_BRIGHT_WHITE" setaf 15
else
    GRAY="$ANSI_FG_GRAY"
    BRIGHT_BLACK="$ANSI_BRIGHT_BLACK"
    BRIGHT_RED="$ANSI_BRIGHT_RED"
    BRIGHT_GREEN="$ANSI_BRIGHT_GREEN"
    BRIGHT_YELLOW="$ANSI_BRIGHT_YELLOW"
    BRIGHT_BLUE="$ANSI_BRIGHT_BLUE"
    BRIGHT_MAGENTA="$ANSI_BRIGHT_MAGENTA"
    BRIGHT_CYAN="$ANSI_BRIGHT_CYAN"
    BRIGHT_WHITE="$ANSI_BRIGHT_WHITE"
fi

_color_tput_or_ansi BG_BLACK "$ANSI_BG_BLACK" setab 0
_color_tput_or_ansi BG_RED "$ANSI_BG_RED" setab 1
_color_tput_or_ansi BG_GREEN "$ANSI_BG_GREEN" setab 2
_color_tput_or_ansi BG_YELLOW "$ANSI_BG_YELLOW" setab 3
_color_tput_or_ansi BG_BLUE "$ANSI_BG_BLUE" setab 4
_color_tput_or_ansi BG_MAGENTA "$ANSI_BG_MAGENTA" setab 5
_color_tput_or_ansi BG_CYAN "$ANSI_BG_CYAN" setab 6
_color_tput_or_ansi BG_WHITE "$ANSI_BG_WHITE" setab 7

if ((_tput_colors >= 16)); then
    _color_tput_or_ansi BG_BRIGHT_BLACK "$ANSI_BG_BRIGHT_BLACK" setab 8
    _color_tput_or_ansi BG_BRIGHT_RED "$ANSI_BG_BRIGHT_RED" setab 9
    _color_tput_or_ansi BG_BRIGHT_GREEN "$ANSI_BG_BRIGHT_GREEN" setab 10
    _color_tput_or_ansi BG_BRIGHT_YELLOW "$ANSI_BG_BRIGHT_YELLOW" setab 11
    _color_tput_or_ansi BG_BRIGHT_BLUE "$ANSI_BG_BRIGHT_BLUE" setab 12
    _color_tput_or_ansi BG_BRIGHT_MAGENTA "$ANSI_BG_BRIGHT_MAGENTA" setab 13
    _color_tput_or_ansi BG_BRIGHT_CYAN "$ANSI_BG_BRIGHT_CYAN" setab 14
    _color_tput_or_ansi BG_BRIGHT_WHITE "$ANSI_BG_BRIGHT_WHITE" setab 15
else
    BG_BRIGHT_BLACK="$ANSI_BG_BRIGHT_BLACK"
    BG_BRIGHT_RED="$ANSI_BG_BRIGHT_RED"
    BG_BRIGHT_GREEN="$ANSI_BG_BRIGHT_GREEN"
    BG_BRIGHT_YELLOW="$ANSI_BG_BRIGHT_YELLOW"
    BG_BRIGHT_BLUE="$ANSI_BG_BRIGHT_BLUE"
    BG_BRIGHT_MAGENTA="$ANSI_BG_BRIGHT_MAGENTA"
    BG_BRIGHT_CYAN="$ANSI_BG_BRIGHT_CYAN"
    BG_BRIGHT_WHITE="$ANSI_BG_BRIGHT_WHITE"
fi

_color_tput_or_ansi BG_RESET "$ANSI_BG_RESET" op
_color_tput_or_ansi BOLD "$ANSI_BOLD" bold
_color_tput_or_ansi DIM "$ANSI_DIM" dim
_color_tput_or_ansi UNDERLINE "$ANSI_UNDERLINE" smul
_color_tput_or_ansi RESET "$ANSI_RESET" sgr0
NC="$RESET"
# }}}

# {{{ direct color and 256-color helpers
_use_truecolor=false
case "$COLOR_TRUECOLOR_MODE" in
    true)
        _use_truecolor=true
        ;;
    false)
        _use_truecolor=false
        ;;
    normal|'')
        if [[ "${COLORTERM:-}" == "truecolor" || "${COLORTERM:-}" == "24bit" ]]; then
            _use_truecolor=true
        elif infocmp -1 "${TERM:-}" 2>/dev/null | grep -Eq '(^|,)[[:space:]]*(RGB|Tc|setrgbf|setrgbb)(,|=)'; then
            _use_truecolor=true
        fi
        ;;
    *)
        _color_warn "unknown COLOR_TRUECOLOR_MODE '$COLOR_TRUECOLOR_MODE'; disabling RGB helpers"
        _use_truecolor=false
        ;;
esac

_use_x256=false
if ((_tput_colors >= 256)) || [[ "$COLOR_BACKEND" == "ansi" ]]; then
    _use_x256=true
fi

if $_use_truecolor; then
    RGB()    { printf '%s[38;2;%s;%s;%sm' "$ESC" "$1" "$2" "$3"; }
    RGB_BG() { printf '%s[48;2;%s;%s;%sm' "$ESC" "$1" "$2" "$3"; }
else
    RGB()    { :; }
    RGB_BG() { :; }
fi

if $_use_x256; then
    X256() {
        _color_is_uint "${1:-}" && (($1 >= 0 && $1 <= 255)) || return 1
        printf '%s[38;5;%sm' "$ESC" "$1"
    }

    X256_BG() {
        _color_is_uint "${1:-}" && (($1 >= 0 && $1 <= 255)) || return 1
        printf '%s[48;5;%sm' "$ESC" "$1"
    }
else
    X256() { :; }
    X256_BG() { :; }
fi
# }}}

# {{{ compatibility layer
case "$COLOR_COMPAT_MODE" in
    mono)
        _color_blank_vars BLACK RED GREEN YELLOW BLUE MAGENTA CYAN WHITE GRAY \
                          BRIGHT_BLACK BRIGHT_RED BRIGHT_GREEN BRIGHT_YELLOW BRIGHT_BLUE BRIGHT_MAGENTA BRIGHT_CYAN BRIGHT_WHITE \
                          BG_BLACK BG_RED BG_GREEN BG_YELLOW BG_BLUE BG_MAGENTA BG_CYAN BG_WHITE BG_RESET \
                          BG_BRIGHT_BLACK BG_BRIGHT_RED BG_BRIGHT_GREEN BG_BRIGHT_YELLOW BG_BRIGHT_BLUE BG_BRIGHT_MAGENTA BG_BRIGHT_CYAN BG_BRIGHT_WHITE \
                          BOLD UNDERLINE DIM RESET NC
        RGB() { :; }
        RGB_BG() { :; }
        X256() { :; }
        X256_BG() { :; }
        ;;
    basic8)
        _color_blank_vars GRAY \
                          BRIGHT_BLACK BRIGHT_RED BRIGHT_GREEN BRIGHT_YELLOW BRIGHT_BLUE BRIGHT_MAGENTA BRIGHT_CYAN BRIGHT_WHITE \
                          BG_BRIGHT_BLACK BG_BRIGHT_RED BG_BRIGHT_GREEN BG_BRIGHT_YELLOW BG_BRIGHT_BLUE BG_BRIGHT_MAGENTA BG_BRIGHT_CYAN BG_BRIGHT_WHITE
        RGB() { :; }
        RGB_BG() { :; }
        X256() { :; }
        X256_BG() { :; }
        ;;
    basic16)
        _color_blank_vars GRAY \
                          BG_BRIGHT_BLACK BG_BRIGHT_RED BG_BRIGHT_GREEN BG_BRIGHT_YELLOW BG_BRIGHT_BLUE BG_BRIGHT_MAGENTA BG_BRIGHT_CYAN BG_BRIGHT_WHITE
        RGB() { :; }
        RGB_BG() { :; }
        X256() { :; }
        X256_BG() { :; }
        ;;
    auto|'')
        :
        ;;
    *)
        _color_warn "unknown COLOR_COMPAT_MODE '$COLOR_COMPAT_MODE'; leaving palette unchanged"
        ;;
esac

for _name in BLACK RED GREEN YELLOW BLUE MAGENTA CYAN WHITE GRAY \
             BRIGHT_BLACK BRIGHT_RED BRIGHT_GREEN BRIGHT_YELLOW BRIGHT_BLUE BRIGHT_MAGENTA BRIGHT_CYAN BRIGHT_WHITE \
             BG_BLACK BG_RED BG_GREEN BG_YELLOW BG_BLUE BG_MAGENTA BG_CYAN BG_WHITE BG_RESET \
             BG_BRIGHT_BLACK BG_BRIGHT_RED BG_BRIGHT_GREEN BG_BRIGHT_YELLOW BG_BRIGHT_BLUE BG_BRIGHT_MAGENTA BG_BRIGHT_CYAN BG_BRIGHT_WHITE \
             BOLD UNDERLINE DIM RESET NC; do
    if _color_in_csv "$_name" "$COLOR_DISABLE_LIST"; then
        _color_set_var "$_name" ''
    fi
done
[ -z "$RESET" ] && NC=''
# }}}

# {{{ optional utility
color_echo() {
    local _color_value="$1"
    shift
    printf '%s%s%s\n' "$_color_value" "$*" "$RESET"
}
# }}}
