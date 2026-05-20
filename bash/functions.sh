# vim:ft=bash:foldmethod=marker

# {{{ PREAMBLE
_BASH_DOTFILES_DIR="${SCRIPT_DIR:-$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
_BASH_DOTFILES_OLD_SOURCE="${SOURCE-}"
_BASH_DOTFILES_OLD_DIR="${DIR-}"
_BASH_DOTFILES_OLD_SCRIPT_DIR="${SCRIPT_DIR-}"
_BASH_DOTFILES_HAD_SOURCE=0
_BASH_DOTFILES_HAD_DIR=0
_BASH_DOTFILES_HAD_SCRIPT_DIR=0

[ "${SOURCE+x}" ] && _BASH_DOTFILES_HAD_SOURCE=1
[ "${DIR+x}" ] && _BASH_DOTFILES_HAD_DIR=1
[ "${SCRIPT_DIR+x}" ] && _BASH_DOTFILES_HAD_SCRIPT_DIR=1

__BASH_DOTFILES_DIR="$_BASH_DOTFILES_DIR"

source "$_BASH_DOTFILES_DIR/func/skp.sh"
source "$_BASH_DOTFILES_DIR/func/tw.sh"
source "$_BASH_DOTFILES_DIR/func/ps_info.sh"

if [ "$_BASH_DOTFILES_HAD_SOURCE" -eq 1 ]; then
  SOURCE="$_BASH_DOTFILES_OLD_SOURCE"
else
  unset SOURCE
fi

if [ "$_BASH_DOTFILES_HAD_DIR" -eq 1 ]; then
  DIR="$_BASH_DOTFILES_OLD_DIR"
else
  unset DIR
fi

if [ "$_BASH_DOTFILES_HAD_SCRIPT_DIR" -eq 1 ]; then
  SCRIPT_DIR="$_BASH_DOTFILES_OLD_SCRIPT_DIR"
else
  unset SCRIPT_DIR
fi

unset _BASH_DOTFILES_DIR _BASH_DOTFILES_OLD_SOURCE _BASH_DOTFILES_OLD_DIR
unset _BASH_DOTFILES_OLD_SCRIPT_DIR _BASH_DOTFILES_HAD_SOURCE
unset _BASH_DOTFILES_HAD_DIR _BASH_DOTFILES_HAD_SCRIPT_DIR
# }}}

# {{{ run-help
# Thanks to Arch Wiki :)
run-help() { help "$READLINE_LINE" 2>/dev/null || man "$READLINE_LINE"; }
# }}}

# {{{ manbat
manbat() {
  "$__BASH_DOTFILES_DIR/utils/manbat.sh" "$@"
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
else
  echo -e "${YELLOW}${BOLD}[WARN] rsync not found. cpr/mvr unavailable.${NC}"
fi
# }}}

# {{{ unicodeof
unicodeof() {
    for i in $(echo "$*" | sed 's/\(.\)/\1 /g'); do
        printf "%s\tU+%04X\n" "$i" "'$i"
    done
}
# }}}

# {{{ new
new () {
    for i in "$@"; do
        mkdir -p "${i%/*}"
        touch "$i"
    done
}
# }}}

# {{{ rmcolor
rmcolor() {
    sed -r "s/\x1B\[[0-9;]*[mK]//g"
}
# }}}

# {{{ mkcd - mkdir & cd
mkcd() {
    mkdir -p -- "$1" && cd -- "$1"
}
# }}}

# {{{ tmpd
tmpd() {
    local dir
    dir=$(mktemp -d "${TMPDIR:-/tmp}/tmpd.XXXXXX") && echo "Created temporary directory: $dir"
    cd "$dir" || return
}
# }}}

# {{{ xargsn
xargsn() {
    xargs -r -n "${1:-1}"
}
# }}}
