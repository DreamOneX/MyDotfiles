#!/usr/bin/env bash
# vim:ft=bash:foldmethod=marker
# desc: Lightweight temporary workspace manager

# {{{ Configuration

# {{{ TMPD_ROOT
# TMPD_ROOT:
#   root directory shared by all shell processes
#   default: ${TMPDIR:-/tmp}/tmpd-${USER:-uid}
: "${TMPD_ROOT:=${TMPDIR:-/tmp}/tmpd-${USER:-$(id -u 2>/dev/null || printf unknown)}}"
# }}}

# }}}

_tmpd_usage() {
  cat <<'EOF'
Usage:
  tmpd [NAME]       create a new workspace and print its path
  tmpd new [NAME]   create a new workspace and print its path
  tmpd cd KEY       print the path for an existing workspace
  tmpd -            print the newest workspace path
  tmpd ls           list workspaces
  tmpd path KEY     print the path for an existing workspace
  tmpd rm KEY       remove a workspace
  tmpd root         print the tmpd root

Notes:
  The shell function changes directory for tmpd/new/cd/-.
  State is shared through TMPD_ROOT; no registry file is kept.
EOF
}

_tmpd_root() {
  printf '%s\n' "$TMPD_ROOT"
}

_tmpd_ensure_root() {
  mkdir -p -- "$TMPD_ROOT"
}

_tmpd_sanitize_name() {
  local name="$1"

  name="${name//[^[:alnum:]_.-]/-}"
  name="${name##[-.]}"
  name="${name%%[-.]}"
  printf '%s' "$name"
}

_tmpd_new() {
  local name="${1:-}"
  local stamp safe template dir

  _tmpd_ensure_root || return
  stamp="$(date +%Y%m%d-%H%M%S)"

  if [ -n "$name" ]; then
    safe="$(_tmpd_sanitize_name "$name")"
    [ -n "$safe" ] || safe="workspace"
    template="$TMPD_ROOT/$stamp.$safe.XXXXXX"
  else
    template="$TMPD_ROOT/$stamp.XXXXXX"
  fi

  dir="$(mktemp -d "$template")" || return
  printf '%s\n' "$dir"
}

_tmpd_list_dirs() {
  local dir idx inserted name
  local -a dirs=() sorted=()

  _tmpd_ensure_root || return
  for dir in "$TMPD_ROOT"/*; do
    [ -d "$dir" ] || continue
    dirs+=("$dir")
  done

  for dir in "${dirs[@]}"; do
    inserted=0
    for idx in "${!sorted[@]}"; do
      if [ "$dir" -nt "${sorted[$idx]}" ]; then
        sorted=("${sorted[@]:0:idx}" "$dir" "${sorted[@]:idx}")
        inserted=1
        break
      fi
    done
    [ "$inserted" -eq 1 ] || sorted+=("$dir")
  done

  for dir in "${sorted[@]}"; do
    name="${dir##*/}"
    printf '%s\n' "$name"
  done
}

_tmpd_ls() {
  local name path

  while IFS= read -r name; do
    [ -n "$name" ] || continue
    path="$TMPD_ROOT/$name"
    printf '%s\t%s\n' "$name" "$path"
  done < <(_tmpd_list_dirs)
}

_tmpd_match_key() {
  local key="$1"
  local name

  _tmpd_list_dirs | while IFS= read -r name; do
    [ -n "$name" ] || continue
    case "$name" in
      "$key"|"$key".*|*."$key".*|"$key"*) printf '%s\n' "$name" ;;
    esac
  done
}

_tmpd_resolve() {
  local key="$1"
  local matches=() name

  if [ -z "$key" ]; then
    printf >&2 'tmpd: missing workspace key\n'
    return 2
  fi

  while IFS= read -r name; do
    [ -n "$name" ] && matches+=("$name")
  done < <(_tmpd_match_key "$key")

  case "${#matches[@]}" in
    0)
      printf >&2 "tmpd: no workspace matches '%s'\n" "$key"
      return 1
      ;;
    1)
      printf '%s\n' "$TMPD_ROOT/${matches[0]}"
      ;;
    *)
      printf >&2 "tmpd: workspace key '%s' is ambiguous:\n" "$key"
      printf >&2 '  %s\n' "${matches[@]}"
      return 1
      ;;
  esac
}

_tmpd_latest() {
  local name

  name="$(_tmpd_list_dirs | sed -n '1p')"
  if [ -z "$name" ]; then
    printf >&2 'tmpd: no workspace exists\n'
    return 1
  fi

  printf '%s\n' "$TMPD_ROOT/$name"
}

_tmpd_rm() {
  local dir

  dir="$(_tmpd_resolve "${1:-}")" || return
  rm -rf -- "$dir"
}

main() {
  case "${1:-}" in
    -h|--help)
      _tmpd_usage
      ;;
    new)
      shift
      _tmpd_new "$@"
      ;;
    cd|path)
      shift
      _tmpd_resolve "${1:-}"
      ;;
    -|last)
      _tmpd_latest
      ;;
    ls|list)
      _tmpd_ls
      ;;
    rm|remove|delete)
      shift
      _tmpd_rm "${1:-}"
      ;;
    root)
      _tmpd_root
      ;;
    "")
      _tmpd_new
      ;;
    *)
      _tmpd_new "$1"
      ;;
  esac
}

main "$@"
