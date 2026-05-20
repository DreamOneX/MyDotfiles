#!/usr/bin/env bash
# vim:ft=bash:foldmethod=marker
# skp.sh — cross-distro package picker+installer with fzf/skim (or a custom picker)
# Built-ins: termux-apt, termux-pacman, apt, pacman, yay, paru, zypper, dnf, yum, eix, emerge, brew, nix, snap, opkg, npm, pip, apk
# Custom PMs: --pm NAME reads ${NAME}_list_cmd / ${NAME}_info_cmd / ${NAME}_install_cmd (hyphens -> underscores)

# {{{ Configuration

# {{{ SKP_PICKER_ORDER
# SKP_PICKER_ORDER:
#   fzf = use fzf when available
#   sk  = use skim when available
#   default order: fzf, sk
: "${SKP_PICKER_ORDER:=fzf,sk}"
# }}}

# {{{ SKP_PM_ORDER
# SKP_PM_ORDER:
#   full package-manager order override for `--pm auto`
#   empty = use SKP_PM_GROUP_ORDER and group-specific preference lists (default)
: "${SKP_PM_ORDER:=}"
# }}}

# {{{ SKP_PM_GROUP_ORDER
# SKP_PM_GROUP_ORDER:
#   termux   = Termux package managers
#   arch     = Arch-family package managers
#   deb      = Debian-family package managers
#   rpm      = RPM-family package managers
#   gentoo   = Gentoo package managers
#   openwrt  = OpenWrt package managers
#   alpine   = Alpine package managers
#   userland = cross-platform userland package managers
#   default order: termux, arch, deb, rpm, gentoo, openwrt, alpine, userland
: "${SKP_PM_GROUP_ORDER:=termux,arch,deb,rpm,gentoo,openwrt,alpine,userland}"
# }}}

# {{{ SKP_TERMUX_PREFER
# SKP_TERMUX_PREFER:
#   termux-apt    = use Termux pkg/apt
#   termux-pacman = use Termux pacman
#   default order: termux-apt, termux-pacman
: "${SKP_TERMUX_PREFER:=termux-apt,termux-pacman}"
# }}}

# {{{ SKP_ARCH_PREFER
# SKP_ARCH_PREFER:
#   paru   = use paru when available
#   yay    = use yay when available
#   pacman = use pacman when available
#   default order: paru, yay, pacman
: "${SKP_ARCH_PREFER:=paru,yay,pacman}"
# }}}

# {{{ SKP_DEB_PREFER
# SKP_DEB_PREFER:
#   apt = use apt/apt-cache when available
#   default order: apt
: "${SKP_DEB_PREFER:=apt}"
# }}}

# {{{ SKP_RPM_PREFER
# SKP_RPM_PREFER:
#   zypper = use zypper when available
#   dnf    = use dnf when available
#   yum    = use yum when available
#   default order: zypper, dnf, yum
: "${SKP_RPM_PREFER:=zypper,dnf,yum}"
# }}}

# {{{ SKP_GENTOO_PREFER
# SKP_GENTOO_PREFER:
#   eix    = use eix for package lookup, emerge for install
#   emerge = use emerge for lookup and install
#   default order: eix, emerge
: "${SKP_GENTOO_PREFER:=eix,emerge}"
# }}}

# {{{ SKP_OPENWRT_PREFER
# SKP_OPENWRT_PREFER:
#   opkg = use opkg when available
#   default order: opkg
: "${SKP_OPENWRT_PREFER:=opkg}"
# }}}

# {{{ SKP_ALPINE_PREFER
# SKP_ALPINE_PREFER:
#   apk = use apk when available
#   default order: apk
: "${SKP_ALPINE_PREFER:=apk}"
# }}}

# {{{ SKP_USERLAND_PREFER
# SKP_USERLAND_PREFER:
#   nix  = use nix-env/nix when available
#   brew = use Homebrew when available
#   snap = use snap when available
#   default order: nix, brew, snap
#   npm/pip are explicit opt-in via --pm or SKP_PM_ORDER
: "${SKP_USERLAND_PREFER:=nix,brew,snap}"
# }}}

# }}}

# --- Resolve script dir (handles symlinks) ---
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
  DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
SCRIPT_DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"

# --- Colors: load palette if present, else minimal fallback (deferred, see _setup_colors) ---
if [ -f "$SCRIPT_DIR/../utils/shell-colors.sh" ]; then
  # shellcheck disable=SC1091
  source "$SCRIPT_DIR/../utils/shell-colors.sh"
else
  YELLOW=$'\033[0;33m'; RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; CYAN=$'\033[0;36m'; BOLD=$'\033[1m'; NC=$'\033[0m'
fi

_supports_color() {
  [ -t 1 ] || return 1
  [ -n "${NO_COLOR:-}" ] && return 1
  [ "${TERM:-}" = "dumb" ] && return 1
  if command -v tput >/dev/null 2>&1; then
    [ "$(tput colors 2>/dev/null || echo 0)" -ge 8 ] || return 1
  fi
  return 0
}

_setup_colors() {
  if [ "${1:-}" = "force_on" ]; then
    :
  elif [ "${1:-}" = "force_off" ] || ! _supports_color; then
    YELLOW=''; RED=''; GREEN=''; CYAN=''; BOLD=''; NC=''
  fi
}

_skp_split_list() {
  local list="${1//,/ }"
  local item
  for item in $list; do
    [ -n "$item" ] && printf '%s\n' "$item"
  done
}

_skp_join_list() {
  local list="${1//,/ }"
  local out="" item
  for item in $list; do
    [ -n "$item" ] || continue
    if [ -n "$out" ]; then
      out="$out, $item"
    else
      out="$item"
    fi
  done
  printf '%s' "$out"
}

_skp_is_termux() {
  [ -n "${TERMUX_VERSION:-}" ] && return 0
  [[ "${PREFIX:-}" == *"/com.termux/files/usr"* ]] && return 0
  [ -x "/data/data/com.termux/files/usr/bin/pkg" ] && return 0
  command -v termux-info >/dev/null 2>&1 && return 0
  return 1
}

_skp_pm_available() {
  case "$1" in
    termux-apt)    _skp_is_termux && command -v pkg >/dev/null 2>&1 ;;
    termux-pacman) _skp_is_termux && command -v pacman >/dev/null 2>&1 ;;
    apt)           command -v apt >/dev/null 2>&1 || command -v apt-cache >/dev/null 2>&1 ;;
    pacman|yay|paru|zypper|dnf|yum|eix|emerge|brew|nix|snap|opkg|apk|npm)
                   command -v "$1" >/dev/null 2>&1 ;;
    pip)           command -v python3 >/dev/null 2>&1 && python3 -m pip -V >/dev/null 2>&1 ;;
    *)             return 1 ;;
  esac
}

_skp_group_pm_list() {
  case "$1" in
    termux)  printf '%s\n' "$SKP_TERMUX_PREFER" ;;
    arch)    printf '%s\n' "$SKP_ARCH_PREFER" ;;
    deb)     printf '%s\n' "$SKP_DEB_PREFER" ;;
    rpm)     printf '%s\n' "$SKP_RPM_PREFER" ;;
    gentoo)  printf '%s\n' "$SKP_GENTOO_PREFER" ;;
    openwrt) printf '%s\n' "$SKP_OPENWRT_PREFER" ;;
    alpine)  printf '%s\n' "$SKP_ALPINE_PREFER" ;;
    userland) printf '%s\n' "$SKP_USERLAND_PREFER" ;;
    *)       printf '%s\n' "$1" ;;
  esac
}

_skp_resolve_auto_picker() {
  local picker
  while IFS= read -r picker; do
    if command -v "$picker" >/dev/null 2>&1; then
      printf '%s\n' "$picker"
      return 0
    fi
  done < <(_skp_split_list "$SKP_PICKER_ORDER")
  return 1
}

_skp_resolve_auto_pm() {
  local group pm

  if [ -n "$SKP_PM_ORDER" ]; then
    while IFS= read -r pm; do
      if _skp_pm_available "$pm"; then
        printf '%s\n' "$pm"
        return 0
      fi
    done < <(_skp_split_list "$SKP_PM_ORDER")
    return 1
  fi

  while IFS= read -r group; do
    while IFS= read -r pm; do
      if _skp_pm_available "$pm"; then
        printf '%s\n' "$pm"
        return 0
      fi
    done < <(_skp_split_list "$(_skp_group_pm_list "$group")")
  done < <(_skp_split_list "$SKP_PM_GROUP_ORDER")

  return 1
}

# --- skp function ---
skp() {
  _die_missing_arg() {
    printf >&2 "%s%s[ERROR]%s option '%s' requires a value.\n" "$RED" "$BOLD" "$NC" "$1"
    return 2
  }

  # Defaults
  local want_picker="auto" want_pm="auto" color_pref="auto"
  local list_cmd="" info_cmd="" install_cmd=""

  # Early color policy
  _setup_colors

  # --- Parse args (supports --opt=value and -- to end options) ---
  while [ $# -gt 0 ]; do
    case "$1" in
      --picker=*)      want_picker="${1#*=}"; shift ;;
      --picker)        [ $# -ge 2 ] || { _die_missing_arg "$1"; return $?; }
                       want_picker="$2"; shift 2 ;;
      --pm=*)          want_pm="${1#*=}"; shift ;;
      --pm)            [ $# -ge 2 ] || { _die_missing_arg "$1"; return $?; }
                       want_pm="$2"; shift 2 ;;
      --list-cmd=*)    list_cmd="${1#*=}"; shift ;;
      --list-cmd)      [ $# -ge 2 ] || { _die_missing_arg "$1"; return $?; }
                       list_cmd="$2"; shift 2 ;;
      --info-cmd=*)    info_cmd="${1#*=}"; shift ;;
      --info-cmd)      [ $# -ge 2 ] || { _die_missing_arg "$1"; return $?; }
                       info_cmd="$2"; shift 2 ;;
      --install-cmd=*) install_cmd="${1#*=}"; shift ;;
      --install-cmd)   [ $# -ge 2 ] || { _die_missing_arg "$1"; return $?; }
                       install_cmd="$2"; shift 2 ;;
      --no-color)      color_pref="off"; shift ;;
      --color)         color_pref="on"; shift ;;
      -h|--help)
        [ "$color_pref" = "on" ] && _setup_colors force_on
        [ "$color_pref" = "off" ] && _setup_colors force_off
        cat <<EOF
${BOLD}Usage:${NC} ${CYAN}skp${NC} ${GREEN}[--picker auto|fzf|sk|<custom>]${NC} ${GREEN}[--pm auto|termux-apt|termux-pacman|apt|pacman|yay|paru|zypper|dnf|yum|eix|emerge|opkg|apk|brew|nix|snap|npm|pip|<custom>]${NC}
       ${GREEN}[--list-cmd 'CMD'] [--info-cmd 'CMD'] [--install-cmd 'CMD']${NC} ${GREEN}[--color|--no-color]${NC}

${BOLD}Notes:${NC}
- ${YELLOW}{}${NC} inside ${CYAN}--info-cmd${NC} and ${CYAN}--install-cmd${NC} is replaced with the candidate package name.
- Auto picker order: ${CYAN}$(_skp_join_list "$SKP_PICKER_ORDER")${NC}
- Auto PM group order: ${CYAN}$(_skp_join_list "$SKP_PM_GROUP_ORDER")${NC}
  - Termux → ${CYAN}$(_skp_join_list "$SKP_TERMUX_PREFER")${NC}
  - Arch family → ${CYAN}$(_skp_join_list "$SKP_ARCH_PREFER")${NC}
  - Deb-based → ${CYAN}$(_skp_join_list "$SKP_DEB_PREFER")${NC}
  - RPM-based → ${CYAN}$(_skp_join_list "$SKP_RPM_PREFER")${NC}
  - Gentoo → ${CYAN}$(_skp_join_list "$SKP_GENTOO_PREFER")${NC}
  - OpenWrt → ${CYAN}$(_skp_join_list "$SKP_OPENWRT_PREFER")${NC}
  - Alpine → ${CYAN}$(_skp_join_list "$SKP_ALPINE_PREFER")${NC}
  - Cross-platform userland → ${CYAN}$(_skp_join_list "$SKP_USERLAND_PREFER")${NC}
- Override auto PM order with ${CYAN}SKP_PM_ORDER${NC}; override picker order with ${CYAN}SKP_PICKER_ORDER${NC}.
- npm / pip are supported via ${CYAN}--pm npm${NC} / ${CYAN}--pm pip${NC}, but are ${BOLD}not${NC} chosen by default auto-detect. They can be included via ${CYAN}SKP_PM_ORDER${NC}.
- Custom PM: set ${CYAN}\${NAME}_list_cmd / \${NAME}_info_cmd / \${NAME}_install_cmd${NC} (hyphens → underscores), then ${CYAN}skp --pm NAME${NC}.
- Custom picker allowed via ${CYAN}--picker <binary>${NC}; it must exist in PATH. If it doesn't support inline-info flags, those are omitted.

${BOLD}Examples:${NC}
- ${CYAN}skp --picker fzf --pm paru${NC}
- ${CYAN}skp --pm opkg${NC}
- ${CYAN}skp --list-cmd 'snap find "" | awk "NR>1{print \\\$1}"' --info-cmd 'snap info {}' --install-cmd 'sudo snap install {}'${NC}
EOF
        return 0 ;;
      --) shift; break ;;
      -*)
        printf >&2 "%s%s[ERROR]%s Unknown option: %s\n" "$RED" "$BOLD" "$NC" "$1"
        return 2 ;;
      *)
        printf >&2 "%s%s[ERROR]%s Unexpected positional argument: %s\n" "$RED" "$BOLD" "$NC" "$1"
        return 2 ;;
    esac
  done

  # Apply final color policy after parsing
  [ "$color_pref" = "on" ] && _setup_colors force_on
  [ "$color_pref" = "off" ] && _setup_colors force_off

  # --- Resolve picker (supports custom names; auto follows SKP_PICKER_ORDER) ---
  local sel=""
  case "$want_picker" in
    auto)
      if ! sel="$(_skp_resolve_auto_picker)"; then
        printf >&2 "%s%s[WARN]%s no picker found (looked for %s). skp disabled.\n" "$YELLOW" "$BOLD" "$NC" "$(_skp_join_list "$SKP_PICKER_ORDER")"
        return 1
      fi
      ;;
    *)
      if command -v "$want_picker" >/dev/null 2>&1; then
        sel="$want_picker"
      else
        printf >&2 "%s%s[ERROR]%s picker '%s' not found in PATH.\n" "$RED" "$BOLD" "$NC" "$want_picker"
        return 1
      fi
      ;;
  esac

  # Determine inline info option support
  local inline_opt=""
  if "$sel" --help 2>&1 | grep -q -- '--info='; then
    inline_opt="--info=inline"
  elif "$sel" --help 2>&1 | grep -q -- '--inline-info'; then
    inline_opt="--inline-info"
  else
    inline_opt=""
  fi

  # --- Resolve PM ---
  local pm=""
  if [ -n "$list_cmd$info_cmd$install_cmd" ]; then
    pm="custom"
  else
    case "$want_pm" in
      termux-apt|termux-pacman|apt|pacman|yay|paru|zypper|dnf|yum|eix|emerge|brew|nix|snap|opkg|apk|npm|pip)
        pm="$want_pm"
        ;;
      auto) pm="" ;;
      *)
        # env-driven custom (hyphens -> underscores) via indirect expansion
        local envkey list_var info_var inst_var
        envkey="${want_pm//-/_}"
        list_var="${envkey}_list_cmd"
        info_var="${envkey}_info_cmd"
        inst_var="${envkey}_install_cmd"
        list_cmd="${!list_var-}"
        info_cmd="${!info_var-}"
        install_cmd="${!inst_var-}"
        if [ -n "$list_cmd$info_cmd$install_cmd" ]; then
          if [ -z "$list_cmd" ] || [ -z "$info_cmd" ] || [ -z "$install_cmd" ]; then
            printf >&2 "%s%s[ERROR]%s custom PM '%s' requires %s, %s and %s to be set.\n" \
              "$RED" "$BOLD" "$NC" "$want_pm" "$list_var" "$info_var" "$inst_var"
            return 2
          fi
          pm="custom"
        fi
        ;;
    esac

    # Autodetect if still unresolved
    if [ -z "$pm" ]; then
      pm="$(_skp_resolve_auto_pm)"
    fi
  fi

  # pip integrity check when explicitly requested
  if [ "$pm" = "pip" ]; then
    if ! command -v python3 >/dev/null 2>&1 || ! python3 -m pip -V >/dev/null 2>&1; then
      printf >&2 "%s%s[ERROR]%s requested 'pip' but python3/pip is not available.\n" "$RED" "$BOLD" "$NC"
      return 1
    fi
  fi

  # --- Commands per PM ---
  if [ "$pm" = "custom" ]; then
    :
  elif [ "$pm" = "termux-apt" ]; then
    list_cmd="pkg list-all 2>/dev/null | cut -d'/' -f1"
    info_cmd="pkg show {}"
    install_cmd="pkg install {}"
  elif [ "$pm" = "termux-pacman" ]; then
    list_cmd="pacman -Sl 2>/dev/null | awk '{print \$2}'"
    info_cmd="pacman -Si {}"
    install_cmd="pacman -S {}"
  elif [ "$pm" = "paru" ]; then
    list_cmd="paru -Sl | awk '{print \$2}'"
    info_cmd="paru -Si {}"
    install_cmd="paru -S {}"
  elif [ "$pm" = "yay" ]; then
    list_cmd="yay -Sl | awk '{print \$2}'"
    info_cmd="yay -Si {}"
    install_cmd="yay -S {}"
  elif [ "$pm" = "pacman" ]; then
    list_cmd="pacman -Sl 2>/dev/null | awk '{print \$2}'"
    info_cmd="pacman -Si {}"
    install_cmd="sudo pacman -S {}"
  elif [ "$pm" = "apt" ]; then
    if command -v apt-cache >/dev/null 2>&1; then
      list_cmd="apt-cache search . 2>/dev/null | awk '{print \$1}'"
      info_cmd="apt-cache show {}"
    else
      list_cmd="apt search . 2>/dev/null | awk -F'/' 'NF>1 {print \$1}'"
      info_cmd="apt show {}"
    fi
    install_cmd="sudo apt install {}"
  elif [ "$pm" = "zypper" ]; then
    list_cmd="zypper se -s 2>/dev/null | awk -F'|' 'NR>2 {gsub(/ /, \"\", \$3); if (\$3!=\"\") print \$3}' | sort -u"
    info_cmd="zypper info {}"
    install_cmd="sudo zypper install {}"
  elif [ "$pm" = "dnf" ]; then
    list_cmd="dnf list available 2>/dev/null | awk 'NR>1 {split(\$1,a,\".\"); print a[1]}' | sort -u"
    info_cmd="dnf info {}"
    install_cmd="sudo dnf install {}"
  elif [ "$pm" = "yum" ]; then
    list_cmd="yum list available 2>/dev/null | awk 'NR>1 {split(\$1,a,\".\"); print a[1]}' | sort -u"
    info_cmd="yum info {}"
    install_cmd="sudo yum install {}"
  elif [ "$pm" = "eix" ]; then
    list_cmd="eix -a --format '<name>\n'"
    info_cmd="eix --nocolor -e {}"
    install_cmd="sudo emerge -av {}"
  elif [ "$pm" = "emerge" ]; then
    list_cmd="emerge --search '' 2>/dev/null | awk '/^[a-z0-9-]+\\/[a-z0-9+_.-]+/ {print \$1}' | cut -d'/' -f2 | sort -u"
    info_cmd="emerge -s {}"
    install_cmd="sudo emerge -av {}"
  elif [ "$pm" = "brew" ]; then
    list_cmd="brew formulae 2>/dev/null"
    info_cmd="brew info {}"
    install_cmd="brew install {}"
  elif [ "$pm" = "nix" ]; then
    list_cmd="nix-env -qaP 2>/dev/null | awk '{print \$1}'"
    info_cmd="nix search nixpkgs {}"
    install_cmd="nix-env -iA {}"
  elif [ "$pm" = "snap" ]; then
    list_cmd="snap find \"\" 2>/dev/null | awk 'NR>1 {print \$1}'"
    info_cmd="snap info {}"
    install_cmd="sudo snap install {}"
  elif [ "$pm" = "opkg" ]; then
    list_cmd="opkg list 2>/dev/null | awk '{print \$1}'"
    info_cmd="opkg info {}"
    install_cmd="opkg install {}"
  elif [ "$pm" = "npm" ]; then
    # Limit list to globally installed to avoid huge registry enumerations
    list_cmd="npm ls -g --depth=0 --parseable 2>/dev/null | awk -F'/' 'NF>0 {print \$NF}' | sed '/^npm$/d' | sort -u"
    info_cmd="npm view {}"
    install_cmd="npm i -g {}"
  elif [ "$pm" = "pip" ]; then
    list_cmd="python3 -m pip list --disable-pip-version-check --format=columns 2>/dev/null | awk 'NR>2 {print \$1}' | sort -u"
    info_cmd="python3 -m pip show {}"
    install_cmd="python3 -m pip install --user {}"
  elif [ "$pm" = "apk" ]; then
    list_cmd="apk search -q 2>/dev/null"
    info_cmd="apk info {}"
    install_cmd="sudo apk add {}"
  else
    printf >&2 "%s%s[WARN]%s No supported package manager found.\n" "$YELLOW" "$BOLD" "$NC"
    return 1
  fi

  # Validate we have required commands
  if [ -z "$list_cmd" ] || [ -z "$info_cmd" ] || [ -z "$install_cmd" ]; then
    printf >&2 "%s%s[ERROR]%s Missing required commands for package manager '%s'.\n" "$RED" "$BOLD" "$NC" "${pm:-unknown}"
    return 1
  fi

  # --- list -> pick ---
  local selection
  # shellcheck disable=SC2086
  selection=$(eval "$list_cmd" | "$sel" --multi --preview "$info_cmd 2>/dev/null" --height 90% --reverse --border ${inline_opt:+$inline_opt} --preview-window down:80%)
  [ -z "${selection:-}" ] && return 0

  # --- install (safe {}, per-package, shell-escaped) ---
  local pkgs=()
  while IFS= read -r _l; do
    [ -n "$_l" ] && pkgs+=("$_l")
  done <<< "$selection"

  # --- install (batch, shell-escaped) ---
  local esc_pkgs=() pkg
  for pkg in "${pkgs[@]}"; do
    esc_pkgs+=("$(printf "%q" "$pkg")")
  done

  # Join escaped package names into one space-separated string
  local pkg_list
  pkg_list="$(printf '%s ' "${esc_pkgs[@]}")"
  pkg_list="${pkg_list% }"   # trim trailing space

  local cmd
  if [[ "$install_cmd" == *"{}"* ]]; then
    # Replace occurrences of '{}' in install_cmd with the full escaped package list.
    cmd=${install_cmd//\{\}/$pkg_list}
  else
    cmd="$install_cmd $pkg_list"
  fi

  eval "$cmd"
}

# Allow script to be sourced or run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  skp "$@"
fi
