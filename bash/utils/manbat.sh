#!/usr/bin/env bash
# vim:ft=bash:foldmethod=marker
# desc: Modern man frontend and MANPAGER backend using bat

# {{{ Configuration

# {{{ MANBAT_STYLE
# MANBAT_STYLE:
#   plain   = no bat decorations (default)
#   numbers = show line numbers
#   full    = show all bat decorations
: "${MANBAT_STYLE:=plain}"
# }}}

# {{{ MANBAT_PAGING
# MANBAT_PAGING:
#   always = always use bat's pager (default)
#   auto   = let bat decide based on terminal output
#   never  = print directly
: "${MANBAT_PAGING:=always}"
# }}}

# {{{ MANBAT_COLOR
# MANBAT_COLOR:
#   auto   = let bat decide based on terminal output (default)
#   always = always emit color
#   never  = never emit color
: "${MANBAT_COLOR:=auto}"
# }}}

# }}}

_manbat_bat_cmd() {
  if command -v bat >/dev/null 2>&1; then
    printf '%s\n' bat
  elif command -v batcat >/dev/null 2>&1; then
    printf '%s\n' batcat
  else
    return 1
  fi
}

_manbat_usage() {
  cat <<'EOF'
Usage:
  manbat [MAN_ARGS...]        open a man page through bat
  manbat --pager [FILE...]    render already-formatted man output
  command | manbat            render piped man output

Examples:
  manbat printf
  manbat 3 printf
  MANPAGER='manbat.sh --pager' man printf

Environment:
  MANBAT_STYLE    bat style to use (default: plain)
  MANBAT_PAGING   bat paging mode to use (default: always)
  MANBAT_COLOR    bat color mode to use (default: auto)
EOF
}

_manbat_input() {
  if [ "$#" -gt 0 ]; then
    cat -- "$@"
  else
    cat
  fi
}

_manbat_clean() {
  local strip_ansi

  strip_ansi=$'s/\x1B\\[[0-9;?]*[ -/]*[@-~]//g; s/\x1B\\][^\x07\x1B]*(\x07|\x1B\\\\)//g'
  if command -v col >/dev/null 2>&1; then
    sed -E "$strip_ansi" | col -bx
  else
    sed -E "$strip_ansi"
  fi
}

_manbat_render() {
  local bat_cmd

  if bat_cmd="$(_manbat_bat_cmd)"; then
    _manbat_input "$@" | _manbat_clean | "$bat_cmd" --language=man --style="$MANBAT_STYLE" --paging="$MANBAT_PAGING" --color="$MANBAT_COLOR"
  elif command -v less >/dev/null 2>&1; then
    _manbat_input "$@" | _manbat_clean | less -m -RFQ
  else
    _manbat_input "$@" | _manbat_clean
  fi
}

_manbat_open_page() {
  local man_status render_status
  local -a statuses

  MAN_KEEP_FORMATTING=1 MANPAGER=cat man "$@" | _manbat_render
  statuses=("${PIPESTATUS[@]}")
  man_status=${statuses[0]}
  render_status=${statuses[1]}

  if [ "$man_status" -ne 0 ]; then
    return "$man_status"
  fi
  return "$render_status"
}

main() {
  case "${1:-}" in
    -h|--help)
      _manbat_usage
      return 0
      ;;
    --pager)
      shift
      _manbat_render "$@"
      ;;
    --)
      shift
      if [ "$#" -gt 0 ]; then
        _manbat_open_page "$@"
      else
        _manbat_render
      fi
      ;;
    *)
      if [ "$#" -gt 0 ]; then
        _manbat_open_page "$@"
      elif [ -t 0 ]; then
        _manbat_usage >&2
        return 2
      else
        _manbat_render
      fi
      ;;
  esac
}

main "$@"
