# vim:ft=bash:foldmethod=marker

# {{{ path_has
path_has() {
  case ":$PATH:" in
    *":$1:"*) return 0 ;;
    *)        return 1 ;;
  esac
}
# }}}

# {{{ path_add_front
path_add_front() {
  if ! path_has "$1"; then
    export PATH="$1:$PATH"
  fi
}
# }}}

# {{{ path_add_back
path_add_back() {
  if ! path_has "$1"; then
    export PATH="$PATH:$1"
  fi
}
# }}}
