#!/usr/bin/env bash
# vim:ft=bash:foldmethod=marker
# desc: Persistent test workspace manager

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

shopt -u failglob 2>/dev/null || true
shopt -s nullglob

_tw_usage() {
  cat <<'EOF'
Usage:
  tw                         create or enter today's workspace
  tw DATE                    enter an existing workspace by date
  tw new [DATE] [comment MESSAGE] [--vcs|--no-vcs]
  tw -m [DATE] [comment MESSAGE] [--vcs|--no-vcs]
  tw [DATE] comment MESSAGE  rename an existing workspace with a comment
  tw comment MESSAGE         create or enter today, then set a comment
  tw ls                      list workspaces
  tw path DATE               print the path for an existing workspace
  tw root                    print the workspace root

Notes:
  DATE is calendar-first. DATE never creates a workspace except through
  bare tw, tw new, or tw -m.
EOF
}

_tw_die() {
  printf >&2 'tw: %s\n' "$*"
  return 1
}

_tw_root() {
  printf '%s\n' "$TEST_WORKSPACE_ROOT"
}

_tw_ensure_root() {
  mkdir -p -- "$TEST_WORKSPACE_ROOT"
}

_tw_today() {
  date +%Y%m%d
}

_tw_yesterday() {
  date -d 'yesterday' +%Y%m%d 2>/dev/null || date -v-1d +%Y%m%d 2>/dev/null
}

_tw_month_limit_days() {
  local months="$TW_DATE_LIMIT_MONTHS"

  case "$months" in
    ''|*[!0-9]*) months=12 ;;
  esac

  printf '%s\n' $((months * 31))
}

_tw_sanitize_comment() {
  local comment="$*"

  comment="${comment,,}"
  comment="${comment//[^[:alnum:]_.-]/-}"
  while [[ "$comment" == *--* ]]; do
    comment="${comment//--/-}"
  done
  comment="${comment##[-.]}"
  comment="${comment%%[-.]}"
  printf '%s' "$comment"
}

_tw_valid_name() {
  [[ "$1" =~ ^[0-9]{8}(_[0-9]+)?(--[[:alnum:]_.-]+)?$ ]]
}

_tw_name_date() {
  printf '%s\n' "${1:0:8}"
}

_tw_name_prefix() {
  local name="$1"

  name="${name%%--*}"
  printf '%s\n' "$name"
}

_tw_date_epoch() {
  date -d "$1" +%s 2>/dev/null
}

_tw_date_distance_days() {
  local lhs rhs lhs_epoch rhs_epoch diff

  lhs="$(_tw_date_epoch "$1")" || return
  rhs="$(_tw_date_epoch "$2")" || return
  lhs_epoch="$lhs"
  rhs_epoch="$rhs"
  diff=$((lhs_epoch - rhs_epoch))
  [ "$diff" -lt 0 ] && diff=$((-diff))
  printf '%s\n' $((diff / 86400))
}

_tw_date_offset_days() {
  local ymd="$1"
  local offset="$2"

  date -d "$ymd $offset day" +%Y%m%d 2>/dev/null
}

_tw_list_names() {
  local dir name

  _tw_ensure_root || return
  for dir in "$TEST_WORKSPACE_ROOT"/*; do
    [ -d "$dir" ] || continue
    name="${dir##*/}"
    _tw_valid_name "$name" || continue
    printf '%s\n' "$name"
  done | sort -r
}

_tw_ls() {
  local name prefix comment

  while IFS= read -r name; do
    [ -n "$name" ] || continue
    prefix="$(_tw_name_prefix "$name")"
    comment=""
    if [[ "$name" == *--* ]]; then
      comment="${name#*--}"
    fi
    if [ -n "$comment" ]; then
      printf '%s\t%s\t%s\n' "$prefix" "$comment" "$TEST_WORKSPACE_ROOT/$name"
    else
      printf '%s\t%s\n' "$prefix" "$TEST_WORKSPACE_ROOT/$name"
    fi
  done < <(_tw_list_names)
}

_tw_latest_for_date() {
  local ymd="$1"
  local name prefix best="" best_idx=-1 idx

  while IFS= read -r name; do
    [ -n "$name" ] || continue
    prefix="$(_tw_name_prefix "$name")"
    case "$prefix" in
      "$ymd")
        idx=0
        ;;
      "$ymd"_[0-9]*)
        idx="${prefix#"$ymd"_}"
        ;;
      *)
        continue
        ;;
    esac

    if [ "$idx" -gt "$best_idx" ]; then
      best="$name"
      best_idx="$idx"
    fi
  done < <(_tw_list_names)

  [ -n "$best" ] && printf '%s\n' "$best"
}

_tw_base_for_date() {
  local ymd="$1"
  local name prefix

  while IFS= read -r name; do
    [ -n "$name" ] || continue
    prefix="$(_tw_name_prefix "$name")"
    [ "$prefix" = "$ymd" ] || continue
    printf '%s\n' "$name"
    return
  done < <(_tw_list_names)
}

_tw_prefix_exists() {
  local prefix="$1"
  local name

  while IFS= read -r name; do
    [ -n "$name" ] || continue
    [ "$(_tw_name_prefix "$name")" = "$prefix" ] || continue
    return 0
  done < <(_tw_list_names)

  return 1
}

_tw_exact_name_match() {
  local key="$1"
  local name prefix

  while IFS= read -r name; do
    [ -n "$name" ] || continue
    prefix="$(_tw_name_prefix "$name")"
    case "$name:$prefix" in
      "$key":*|*:"$key") printf '%s\n' "$name" ;;
    esac
  done < <(_tw_list_names)
}

_tw_candidate_years_for_mmdd() {
  local mmdd="$1"
  local current_year year

  current_year="$(date +%Y)"
  for year in "$current_year" "$((current_year - 1))" "$((current_year + 1))"; do
    date -d "${year}-${mmdd:0:2}-${mmdd:2:2}" +%Y%m%d 2>/dev/null
  done
}

_tw_parse_full_date() {
  local value="$1"
  local year month day

  case "$value" in
    today)
      _tw_today
      ;;
    yesterday)
      _tw_yesterday
      ;;
    [0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9])
      year="${value:0:4}"
      month="${value:4:2}"
      day="${value:6:2}"
      date -d "$year-$month-$day" +%Y%m%d 2>/dev/null
      ;;
    [0-9][0-9][0-9][0-9][0-9][0-9])
      year="20${value:0:2}"
      month="${value:2:2}"
      day="${value:4:2}"
      date -d "$year-$month-$day" +%Y%m%d 2>/dev/null
      ;;
  esac
}

_tw_resolve_candidate_dates() {
  local key="$1"
  local current_month day mmdd

  case "$key" in
    today|yesterday|[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]|[0-9][0-9][0-9][0-9][0-9][0-9])
      _tw_parse_full_date "$key"
      ;;
    [0-9][0-9][0-9][0-9])
      _tw_candidate_years_for_mmdd "$key"
      ;;
    [0-9]|[0-9][0-9])
      current_month="$(date +%m)"
      day="$(printf '%02d' "$((10#$key))")"
      for mmdd in "$current_month$day"; do
        _tw_candidate_years_for_mmdd "$mmdd"
      done
      ;;
  esac
}

_tw_best_existing_day() {
  local day="$1"
  local max_days="${2:-}"
  local today name ymd distance best="" best_distance=9999999 best_ymd=""

  today="$(_tw_today)"
  while IFS= read -r name; do
    [ -n "$name" ] || continue
    ymd="$(_tw_name_date "$name")"
    [ "${ymd:6:2}" = "$day" ] || continue
    distance="$(_tw_date_distance_days "$ymd" "$today")" || continue
    if [ -n "$max_days" ] && [ "$distance" -gt "$max_days" ]; then
      continue
    fi
    if [ "$distance" -lt "$best_distance" ] || {
      [ "$distance" -eq "$best_distance" ] && [ "$ymd" -gt "$best_ymd" ]
    }; then
      best="$ymd"
      best_distance="$distance"
      best_ymd="$ymd"
    fi
  done < <(_tw_list_names)

  [ -n "$best" ] && printf '%s\n' "$best"
}

_tw_best_existing_mmdd() {
  local mmdd="$1"
  local max_days="${2:-}"
  local today name ymd distance best="" best_distance=9999999 best_ymd=""

  today="$(_tw_today)"
  while IFS= read -r name; do
    [ -n "$name" ] || continue
    ymd="$(_tw_name_date "$name")"
    [ "${ymd:4:4}" = "$mmdd" ] || continue
    distance="$(_tw_date_distance_days "$ymd" "$today")" || continue
    if [ -n "$max_days" ] && [ "$distance" -gt "$max_days" ]; then
      continue
    fi
    if [ "$distance" -lt "$best_distance" ] || {
      [ "$distance" -eq "$best_distance" ] && [ "$ymd" -gt "$best_ymd" ]
    }; then
      best="$ymd"
      best_distance="$distance"
      best_ymd="$ymd"
    fi
  done < <(_tw_list_names)

  [ -n "$best" ] && printf '%s\n' "$best"
}

_tw_resolve_short_day() {
  local key="$1"
  local max_days="$2"
  local day best reference nearby offset

  day="$(printf '%02d' "$((10#$key))")"
  [ "$((10#$key))" -ge 1 ] && [ "$((10#$key))" -le 31 ] || return 1
  best="$(_tw_best_existing_day "$day" "$max_days")"
  if [ -n "$best" ]; then
    _tw_latest_for_date "$best"
    return
  fi

  reference="$(date +%Y%m)${day}"
  for offset in -2 -1 1 2; do
    nearby="$(_tw_date_offset_days "$reference" "$offset")" || continue
    best="$(_tw_best_existing_day "${nearby:6:2}" "$max_days")"
    if [ -n "$best" ]; then
      _tw_latest_for_date "$best"
      return
    fi
  done

  best="$(_tw_best_existing_day "$day")"
  if [ -n "$best" ]; then
    _tw_latest_for_date "$best"
    return
  fi

  return 1
}

_tw_resolve_mmdd() {
  local key="$1"
  local max_days="$2"
  local candidate best nearby offset

  while IFS= read -r candidate; do
    [ -n "$candidate" ] || continue
    best="$(_tw_latest_for_date "$candidate")"
    if [ -n "$best" ]; then
      printf '%s\n' "$best"
      return
    fi
  done < <(_tw_resolve_candidate_dates "$key")

  best="$(_tw_best_existing_mmdd "$key" "$max_days")"
  if [ -n "$best" ]; then
    _tw_latest_for_date "$best"
    return
  fi

  while IFS= read -r candidate; do
    [ -n "$candidate" ] || continue
    for offset in -2 -1 1 2; do
      nearby="$(_tw_date_offset_days "$candidate" "$offset")" || continue
      best="$(_tw_latest_for_date "$nearby")"
      if [ -n "$best" ]; then
        printf '%s\n' "$best"
        return
      fi
    done
  done < <(_tw_resolve_candidate_dates "$key")

  best="$(_tw_best_existing_mmdd "$key")"
  if [ -n "$best" ]; then
    _tw_latest_for_date "$best"
    return
  fi

  return 1
}

_tw_resolve_by_calendar() {
  local key="$1"
  local max_days
  local candidate best name
  local -a candidates=()

  max_days="$(_tw_month_limit_days)"
  case "$key" in
    [0-9]|[0-9][0-9])
      _tw_resolve_short_day "$key" "$max_days"
      return
      ;;
    [0-9][0-9][0-9][0-9])
      _tw_resolve_mmdd "$key" "$max_days"
      return
      ;;
  esac

  while IFS= read -r candidate; do
    [ -n "$candidate" ] && candidates+=("$candidate")
  done < <(_tw_resolve_candidate_dates "$key")

  [ "${#candidates[@]}" -gt 0 ] || return 1

  for candidate in "${candidates[@]}"; do
    name="$(_tw_latest_for_date "$candidate")"
    if [ -n "$name" ]; then
      printf '%s\n' "$name"
      return 0
    fi
  done

  return 1
}

_tw_resolve_by_key() {
  local key="$1"
  local name matches=()

  while IFS= read -r name; do
    [ -n "$name" ] && matches+=("$name")
  done < <(_tw_exact_name_match "$key")

  case "${#matches[@]}" in
    0)
      return 1
      ;;
    1)
      printf '%s\n' "${matches[0]}"
      ;;
    *)
      printf >&2 "tw: workspace key '%s' is ambiguous:\n" "$key"
      printf >&2 '  %s\n' "${matches[@]}"
      return 2
      ;;
  esac
}

_tw_resolve_name() {
  local key="$1"
  local name

  [ -n "$key" ] || return 1

  name="$(_tw_resolve_by_calendar "$key")" && {
    printf '%s\n' "$name"
    return
  }

  name="$(_tw_resolve_by_key "$key")" && {
    printf '%s\n' "$name"
    return
  }

  _tw_die "no workspace matches '$key'"
}

_tw_resolve_path() {
  local key="$1"
  local name

  name="$(_tw_resolve_name "$key")" || return
  printf '%s\n' "$TEST_WORKSPACE_ROOT/$name"
}

_tw_next_name() {
  local ymd="$1"
  local comment="${2:-}"
  local idx prefix suffix

  suffix=""
  if [ -n "$comment" ]; then
    suffix="--$comment"
  fi

  if ! _tw_prefix_exists "$ymd"; then
    printf '%s%s\n' "$ymd" "$suffix"
    return
  fi

  idx=1
  while :; do
    prefix="${ymd}_${idx}"
    if ! _tw_prefix_exists "$prefix"; then
      printf '%s%s\n' "$prefix" "$suffix"
      return
    fi
    idx=$((idx + 1))
  done
}

_tw_apply_vcs() {
  local dir="$1"
  local use_vcs="$2"

  [ "$use_vcs" = "1" ] || return 0
  git -C "$dir" init --quiet
}

_tw_create() {
  local ymd="$1"
  local comment="${2:-}"
  local use_vcs="$3"
  local name dir

  _tw_ensure_root || return
  name="$(_tw_next_name "$ymd" "$comment")"
  dir="$TEST_WORKSPACE_ROOT/$name"
  mkdir -p -- "$dir" || return
  _tw_apply_vcs "$dir" "$use_vcs" || return
  printf '%s\n' "$dir"
}

_tw_today_workspace() {
  local comment="${1:-}"
  local use_vcs="$2"
  local today name dir

  today="$(_tw_today)"
  name="$(_tw_base_for_date "$today")"
  if [ -n "$name" ]; then
    dir="$TEST_WORKSPACE_ROOT/$name"
    if [ -n "$comment" ]; then
      dir="$(_tw_set_comment_path "$dir" "$comment")" || return
    fi
    printf '%s\n' "$dir"
    return
  fi

  _tw_create "$today" "$comment" "$use_vcs"
}

_tw_set_comment_path() {
  local dir="$1"
  local comment="$2"
  local name prefix slug target

  [ -d "$dir" ] || _tw_die "workspace does not exist: $dir" || return
  name="${dir##*/}"
  prefix="$(_tw_name_prefix "$name")"
  slug="$(_tw_sanitize_comment "$comment")"
  [ -n "$slug" ] || _tw_die 'comment becomes empty after sanitizing' || return

  target="$TEST_WORKSPACE_ROOT/$prefix--$slug"
  if [ "$target" != "$dir" ]; then
    [ ! -e "$target" ] || _tw_die "target workspace already exists: ${target##*/}" || return
    mv -- "$dir" "$target" || return
  fi

  printf '%s\n' "$target"
}

_tw_parse_create_args() {
  local date_arg=""
  local comment=""
  local use_vcs="$TW_VCS_DEFAULT"
  local ymd
  local part

  while [ "$#" -gt 0 ]; do
    case "$1" in
      --vcs|--git)
        use_vcs=1
        shift
        ;;
      --no-vcs|--no-git)
        use_vcs=0
        shift
        ;;
      comment|-c|--comment|--message)
        shift
        [ "$#" -gt 0 ] || _tw_die 'comment requires a message' || return
        while [ "$#" -gt 0 ]; do
          case "$1" in
            --vcs|--git|--no-vcs|--no-git)
              break
              ;;
          esac
          part="$1"
          if [ -n "$comment" ]; then
            comment="$comment $part"
          else
            comment="$part"
          fi
          shift
        done
        [ -n "$comment" ] || _tw_die 'comment requires a message' || return
        ;;
      -*)
        _tw_die "unknown option: $1" || return
        ;;
      *)
        if [ -z "$date_arg" ]; then
          date_arg="$1"
          shift
        else
          _tw_die "unexpected argument: $1" || return
        fi
        ;;
    esac
  done

  if [ -n "$comment" ]; then
    comment="$(_tw_sanitize_comment "$comment")"
    [ -n "$comment" ] || _tw_die 'comment becomes empty after sanitizing' || return
  fi

  if [ -z "$date_arg" ]; then
    ymd="$(_tw_today)"
  else
    ymd="$(_tw_parse_full_date "$date_arg" | sed -n '1p')"
    if [ -z "$ymd" ]; then
      ymd="$(_tw_resolve_candidate_dates "$date_arg" | sed -n '1p')"
    fi
    [ -n "$ymd" ] || _tw_die "invalid creation date: $date_arg" || return
  fi

  _tw_create "$ymd" "$comment" "$use_vcs"
}

_tw_parse_default_args() {
  local date_arg=""
  local comment=""
  local use_vcs="$TW_VCS_DEFAULT"
  local dir
  local part

  while [ "$#" -gt 0 ]; do
    case "$1" in
      --vcs|--git)
        use_vcs=1
        shift
        ;;
      --no-vcs|--no-git)
        use_vcs=0
        shift
        ;;
      comment|-c|--comment|--message)
        shift
        [ "$#" -gt 0 ] || _tw_die 'comment requires a message' || return
        while [ "$#" -gt 0 ]; do
          case "$1" in
            --vcs|--git|--no-vcs|--no-git)
              break
              ;;
          esac
          part="$1"
          if [ -n "$comment" ]; then
            comment="$comment $part"
          else
            comment="$part"
          fi
          shift
        done
        [ -n "$comment" ] || _tw_die 'comment requires a message' || return
        ;;
      -*)
        _tw_die "unknown option: $1" || return
        ;;
      *)
        if [ -z "$date_arg" ]; then
          date_arg="$1"
          shift
        else
          _tw_die "unexpected argument: $1" || return
        fi
        ;;
    esac
  done

  if [ -z "$date_arg" ]; then
    _tw_today_workspace "$comment" "$use_vcs"
    return
  fi

  if [ -n "$comment" ]; then
    dir="$(_tw_resolve_path "$date_arg")" || return
    _tw_set_comment_path "$dir" "$comment"
  else
    _tw_resolve_path "$date_arg"
  fi
}

main() {
  case "${1:-}" in
    -h|--help)
      _tw_usage
      ;;
    root)
      _tw_root
      ;;
    ls|list)
      _tw_ls
      ;;
    path)
      shift
      [ "$#" -gt 0 ] || _tw_die 'path requires a date or key' || return
      _tw_resolve_path "$1"
      ;;
    new|-m|--multi)
      shift
      _tw_parse_create_args "$@"
      ;;
    *)
      _tw_parse_default_args "$@"
      ;;
  esac
}

main "$@"
