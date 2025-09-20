#!/usr/bin/env bash
# skp.sh — cross-distro package picker+installer with fzf/skim (or a custom picker)
# Built-ins: termux-apt, termux-pacman, apt, pacman, yay, paru, zypper, dnf, yum, eix, emerge, brew, nix, snap, opkg, npm, pip
# Custom PMs: --pm NAME reads ${NAME}_list_cmd / ${NAME}_info_cmd / ${NAME}_install_cmd (hyphens -> underscores)
set -u

# --- Configurable options (override via env) ---
# TODO: this section is currently non-functional
# : "${SKP_PICKER_ORDER:=fzf,sk}" # comma-separated preferred pickers for 'auto' (in order)
# : "${SKP_PM_ORDER:=termux-apt,paru,yay,pacman,apt,zypper,dnf,yum,eix,emerge,opkg,nix,brew,snap}" # comma-separated preferred PMs for 'auto' (in order)
# TODO: devide different pm into groups and prefer some groups over others
# e.g. termux > arch family > deb-based > rpm-based > gentoo > openwrt > cross-platform userland
# and SKP_XXX_PREFER lists to tweak order inside groups
# e.g. SKP_ARCH_PREFER=paru,yay,pacman

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

# --- skp function ---
skp() {
  # Termux detection
  _is_termux() {
    [ -n "${TERMUX_VERSION:-}" ] && return 0
    [[ "${PREFIX:-}" == *"/com.termux/files/usr"* ]] && return 0
    [ -x "/data/data/com.termux/files/usr/bin/pkg" ] && return 0
    command -v termux-info >/dev/null 2>&1 && return 0
    return 1
  }

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
${BOLD}Usage:${NC} ${CYAN}skp${NC} ${GREEN}[--picker auto|fzf|sk|<custom>]${NC} ${GREEN}[--pm auto|termux-apt|termux-pacman|apt|pacman|yay|paru|zypper|dnf|yum|eix|emerge|opkg|brew|nix|snap|npm|pip|<custom>]${NC}
       ${GREEN}[--list-cmd 'CMD'] [--info-cmd 'CMD'] [--install-cmd 'CMD']${NC} ${GREEN}[--color|--no-color]${NC}

${BOLD}Notes:${NC}
- ${YELLOW}{}${NC} inside ${CYAN}--info-cmd${NC} and ${CYAN}--install-cmd${NC} is replaced with the candidate package name.
- Built-in groups (autodetect order):
  - Termux → ${CYAN}termux-apt${NC}
  - Arch family → ${CYAN}paru, yay, pacman${NC}
  - Deb-based → ${CYAN}apt${NC}
  - RPM-based → ${CYAN}zypper, dnf, yum${NC}
  - Gentoo → ${CYAN}eix, emerge${NC}
  - OpenWrt → ${CYAN}opkg${NC}
  - Cross-platform userland → ${CYAN}nix, brew, snap${NC}
- npm / pip are supported via ${CYAN}--pm npm${NC} / ${CYAN}--pm pip${NC}, but are ${BOLD}not${NC} chosen by auto-detect. but please be aware that ${CYAN}npm${NC} and ${CYAN}pip${NC} lists only globally installed packages.
- Custom PM: set ${CYAN}\${NAME}_list_cmd / \${NAME}_info_cmd / \${NAME}_install_cmd${NC} (hyphens → underscores), then ${CYAN}skp --pm NAME${NC}.
- Custom picker allowed via ${CYAN}--picker <binary>${NC}; it must exist in PATH. If it doesn't support inline-info flags, those are omitted.

${BOLD}Examples:${NC}
- ${CYAN}skp --picker fzf --pm paru${NC}
- ${CYAN}skp --pm opkg${NC}
- ${CYAN}skp --list-cmd 'snap find "" | awk "NR>1{print \\$1}"' --info-cmd 'snap info {}' --install-cmd 'sudo snap install {}'${NC}
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

  # --- Resolve picker (supports custom names; auto prefers fzf -> sk) ---
  local sel=""
  case "$want_picker" in
    auto)
      if command -v fzf >/dev/null 2>&1; then
        sel="fzf"
      elif command -v sk >/dev/null 2>&1; then
        sel="sk"
      else
        printf >&2 "%s%s[WARN]%s no picker found (looked for fzf, sk). skp disabled.\n" "$YELLOW" "$BOLD" "$NC"
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
      termux-apt|termux-pacman|apt|pacman|yay|paru|zypper|dnf|yum|eix|emerge|brew|nix|snap|opkg|npm|pip)
        pm="$want_pm"
        ;;
      auto) pm="" ;;
      *)
        # env-driven custom (hyphens -> underscores) via indirect expansion
        local envkey list_var info_var inst_var
        envkey=$(printf "%s" "$want_pm" | sed 's/-/_/g')
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
      if _is_termux; then
        pm="termux-apt"
      fi
      if [ -z "$pm" ]; then
        # --- Arch family (AUR helpers are preferred if installed; otherwise pacman) ---
        if   command -v paru   >/dev/null 2>&1; then pm="paru"
        elif command -v yay    >/dev/null 2>&1; then pm="yay"
        elif command -v pacman >/dev/null 2>&1; then pm="pacman"

        # --- Deb-based ---
        elif command -v apt    >/dev/null 2>&1; then pm="apt"

        # --- RPM-based (SUSE/Fedora/RHEL) ---
        elif command -v zypper >/dev/null 2>&1; then pm="zypper"
        elif command -v dnf    >/dev/null 2>&1; then pm="dnf"
        elif command -v yum    >/dev/null 2>&1; then pm="yum"

        # --- Gentoo (prefer eix; fallback to emerge) ---
        elif command -v eix    >/dev/null 2>&1; then pm="eix"
        elif command -v emerge >/dev/null 2>&1; then pm="emerge"

        # --- OpenWrt ---
        elif command -v opkg   >/dev/null 2>&1; then pm="opkg"

        # --- Cross-platform userland (not OS-native): nix outranks snap ---
        elif command -v nix    >/dev/null 2>&1; then pm="nix"
        elif command -v brew   >/dev/null 2>&1; then pm="brew"
        elif command -v snap   >/dev/null 2>&1; then pm="snap"
        fi
      fi
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

  local pkg cmd esc
  for pkg in "${pkgs[@]}"; do
    esc=$(printf "%q" "$pkg")
    if [[ "$install_cmd" == *"{}"* ]]; then
      # Replace occurrences of '{}' in install_cmd with the escaped package name.
      cmd=${install_cmd//\{\}/$esc}
    else
      cmd="$install_cmd $esc"
    fi
    eval "$cmd"
  done
}

# Allow script to be sourced or run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  skp "$@"
fi
