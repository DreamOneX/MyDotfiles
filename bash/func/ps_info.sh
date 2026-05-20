# vim:ft=bash:foldmethod=marker

# {{{ Configuration

# {{{ PS_USER_TERMUX_PREFER
# Termux username display preference
#  - whoami   : always show the true username ( u0_axxx ) (default)
#  - root     : always show 'root' as username
#    termux   : always show 'termux' as username
: "${PS_USER_TERMUX_PREFER:=whoami}"
# }}}

# {{{ PS_HOSTNAME_PREFER
# Hostname display preference
# - short    : short hostname (default)
# - fqdn     : full qualified domain name
# - domain   : domain name only
# - lan_ipv4 : local network IPv4 address
# - lan_ipv6 : local network IPv6 address
# - wan_ipv4 : public IPv4 address
# - wan_ipv6 : public IPv6 address
# NOTE: wan_xxxx may be slow, unreliable, privacy risk, etc.)
# TODO: implement the wan_xxxx options
: "${PS_HOSTNAME_PREFER:=short}"
# }}}

# {{{ PS_CONN_PREFER
# Connection info display preference
# - none    : do not show connection info, ps_conn() will return empty string
# - brief   : show brief connection info, only the conn type, follow the PS_CONN_ORDER (default)
# - full    : show full connection info, including details
: "${PS_CONN_PREFER:=brief}"
# }}}

# {{{ PS_CONN_ORDER
# Connection info display order, remove types you don't want to see at all
# - default order: SSH, TTY, VPN
: "${PS_CONN_ORDER:=ssh,tty,vpn}"
# }}}

# {{{ PS_PATH_HEAD_COUNT
# PS_PATH_HEAD_COUNT:
#   number of leading path components kept by ps_path
#   default: 2
: "${PS_PATH_HEAD_COUNT:=2}"
# }}}

# {{{ PS_PATH_TAIL_COUNT
# PS_PATH_TAIL_COUNT:
#   number of trailing path components kept by ps_path
#   default: 2
: "${PS_PATH_TAIL_COUNT:=2}"
# }}}

# {{{ PS_PATH_ABBREV_LEN
# PS_PATH_ABBREV_LEN:
#   abbreviation length for middle path components
#   default: 1
: "${PS_PATH_ABBREV_LEN:=1}"
# }}}

# {{{ PS_TIME_FORMAT
# PS_TIME_FORMAT:
#   date(1) format used by ps_time
#   default: %H:%M:%S
: "${PS_TIME_FORMAT:=%H:%M:%S}"
# }}}

# {{{ PS_DATE_FORMAT
# PS_DATE_FORMAT:
#   date(1) format used by ps_date
#   default: %F
: "${PS_DATE_FORMAT:=%F}"
# }}}

# {{{ PS_CHAR_USER
# PS_CHAR_USER:
#   prompt character for non-root shells
#   default: $
: "${PS_CHAR_USER:=\$}"
# }}}

# {{{ PS_CHAR_ROOT
# PS_CHAR_ROOT:
#   prompt character for root shells
#   default: #
: "${PS_CHAR_ROOT:=#}"
# }}}

# {{{ PS_SEPARATOR
# PS_SEPARATOR:
#   generic separator printed by ps_sep
#   default: one space
: "${PS_SEPARATOR:= }"
# }}}

# }}}

# {{{ User & Host
# {{{ ps_user
ps_user() {
    local user="$(whoami)"
    if [[ -n "$TERMUX_VERSION" ]]; then
        case "$PS_USER_TERMUX_PREFER" in
            root)   user="root" ;;
            termux) user="termux" ;;
            *)      user="${PS_USER_TERMUX_PREFER}" ;; # just the value of PS_USER_TERMUX_PREFER
        esac
    fi
    echo "$user"
}
# }}}
# {{{ ps_host
ps_host() {
    local host=""
    case "$PS_HOSTNAME_PREFER" in
        short)    host="$(hostname -s)" ;;
        fqdn)     host="$(hostname -f)" ;;
        domain)   host="$(hostname -d)" ;;
        # lan_ipv4) host="$()"
        # lan_ipv6) host="$(hostname -I | awk '{for(i=1;i<=NF;i++) if($i ~ /:/) {print $i; exit}}')" ;;
        # wan_ipv4) host="TODO_wan_ipv4" ;; # TODO
        # wan_ipv6) host="TODO_wan_ipv6" ;; # TODO
        *)        host="${PS_HOSTNAME_PREFER}" ;; # just the value of PS_HOSTNAME_PREFER
    esac
    echo "$host"
}
# }}}
# {{{ ps_conn
ps_conn() {
  # -------- read prefs --------
  local prefer="${PS_CONN_PREFER:-brief}"
  local order="${PS_CONN_ORDER:-ssh,tty,vpn}"

  # none => empty string
  if [[ "$prefer" == "none" ]]; then
    echo ""
    return 0
  fi

  # -------- helpers --------
  _have() { command -v "$1" >/dev/null 2>&1; }

  # -------- detect SSH/MOSH --------
  local has_ssh="" ssh_from="" ssh_kind=""
  if [[ -n "$MOSH_SESSION" ]]; then
    has_ssh=1
    ssh_kind="mosh"
  elif [[ -n "$SSH_CONNECTION" || -n "$SSH_CLIENT" || -n "$SSH_TTY" ]]; then
    has_ssh=1
    ssh_kind="ssh"
  fi
  if [[ -n "$SSH_CONNECTION" ]]; then
    # SSH_CONNECTION: "client_ip client_port server_ip server_port"
    ssh_from="$(awk '{print $1}' <<<"$SSH_CONNECTION")"
  elif [[ -n "$SSH_CLIENT" ]]; then
    ssh_from="$(awk '{print $1}' <<<"$SSH_CLIENT")"
  fi

  # -------- detect TTY / PTY --------
  local tty_path tty_kind="" tty_brief=""
  tty_path="$(tty 2>/dev/null)"
  if [[ "$tty_path" != "not a tty" && -n "$tty_path" ]]; then
    if [[ "$tty_path" == /dev/pts/* ]]; then
      tty_kind="pty"
      # /dev/pts/N -> N
      tty_brief="pty${tty_path##*/}"
    elif [[ "$tty_path" == /dev/tty[0-9]* ]]; then
      tty_kind="tty"
      tty_brief="tty${tty_path#/dev/tty}"
    elif [[ "$tty_path" == /dev/ttys[0-9]* ]]; then
      # macOS: /dev/ttys000
      tty_kind="tty"
      tty_brief="tty${tty_path#/dev/ttys}"
    else
      tty_kind="tty"
      tty_brief="tty"
    fi
  fi

  # -------- detect VPN (lightweight, prompt-safe) --------
  # signals: interface names + default route + known processes (as last resort -> "likely")
  local vpn_state="no" vpn_ifaces=() def_if="" def_via=""
  if _have ip; then
    # interfaces
    while IFS= read -r line; do
      # "2: wg0: ..." -> field 2 is name
      local _n
      _n="$(awk -F': ' 'NR{print $2}' <<<"$line" | cut -d: -f1)"
      case "$_n" in
        tun*|tap*|wg*|utun*|tailscale*|zt*|ppp*|warp* ) vpn_ifaces+=("$_n");;
      esac
    done < <(ip -o link show 2>/dev/null)
    # default route
    def_if="$(ip route show default 2>/dev/null | awk '/default/ {for(i=1;i<=NF;i++) if($i=="dev"){print $(i+1); exit}}')"
    def_via="$(ip route show default 2>/dev/null | awk '/default/ {for(i=1;i<=NF;i++) if($i=="via"){print $(i+1); exit}}')"
  elif _have ifconfig; then
    while IFS= read -r _n; do
      case "$_n" in
        tun*|tap*|wg*|utun*|tailscale*|zt*|ppp*|warp* ) vpn_ifaces+=("$_n");;
      esac
    done < <(ifconfig -a 2>/dev/null | grep '^[a-z0-9].*:' | cut -d: -f1)
    if _have route; then
      def_if="$(route -n get default 2>/dev/null | awk '/interface:/{print $2; exit}')"
      def_via="$(route -n get default 2>/dev/null | awk '/gateway:/{print $2; exit}')"
    fi
  fi

  if (( ${#vpn_ifaces[@]} > 0 )); then
    vpn_state="yes"
  fi
  if [[ "$def_if" =~ ^(tun|tap|wg|utun|tailscale|zt|ppp|warp) ]]; then
    vpn_state="yes"
  fi
  if [[ "$vpn_state" == "no" ]]; then
    # processes as weak signal
    if _have pgrep && pgrep -fa 'openvpn|wireguard|wg-quick|wgcf|tailscaled|tailscale|zerotier|nebula|warp-svc' ; then
      vpn_state="likely"
    else
      if ps aux 2>/dev/null | grep -E 'openvpn|wireguard|wg-quick|wgcf|tailscaled|tailscale|zerotier|nebula|warp-svc' | grep -vq grep ; then
        vpn_state="likely"
      fi
    fi
  fi

  # -------- format per prefer + order --------
  local out_parts=()
  IFS=',' read -r -a _order_arr <<<"$order"

  for _k in "${_order_arr[@]}"; do
    case "$_k" in
      ssh)
        if [[ -n "$has_ssh" ]]; then
          if [[ "$prefer" == "brief" ]]; then
            out_parts+=("ssh")
          else
            # full
            if [[ -n "$ssh_from" ]]; then
              if [[ "$ssh_kind" == "mosh" ]]; then
                out_parts+=("ssh(mosh,$ssh_from)")
              else
                out_parts+=("ssh($ssh_from)")
              fi
            else
              out_parts+=("ssh")
            fi
          fi
        fi
        ;;
      tty)
        if [[ -n "$tty_kind" ]]; then
          if [[ "$prefer" == "brief" ]]; then
            # want: `ttyN` or `ptyN`
            if [[ -n "$tty_brief" ]]; then
              out_parts+=("$tty_brief")
            else
              out_parts+=("$tty_kind")
            fi
          else
            # full: tty(/dev/ttyX) or pty(/dev/pts/N)
            if [[ -n "$tty_path" ]]; then
              out_parts+=("$tty_kind($tty_path)")
            else
              out_parts+=("$tty_kind")
            fi
          fi
        fi
        ;;
      vpn)
        # only show when some signal exists
        if [[ "$vpn_state" != "no" ]]; then
          if [[ "$prefer" == "brief" ]]; then
            out_parts+=("vpn")
          else
            # full: vpn(ifaces:..., def: IF via GW) / vpn(likely)
            if [[ "$vpn_state" == "likely" ]]; then
              out_parts+=("vpn(likely)")
            else
              local _v=""
              if (( ${#vpn_ifaces[@]} )); then
                _v+="ifaces:${vpn_ifaces[*]}"
              fi
              if [[ -n "$def_if" ]]; then
                [[ -n "$_v" ]] && _v+=", "
                _v+="def:${def_if}"
                [[ -n "$def_via" ]] && _v+=" via ${def_via}"
              fi
              [[ -z "$_v" ]] && _v="on"
              out_parts+=("vpn(${_v})")
            fi
          fi
        fi
        ;;
    esac
  done

  # join with spaces; if empty -> ""
  if ((${#out_parts[@]})); then
    local IFS=' '
    echo "${out_parts[*]}"
  else
    echo ""
  fi
}
# }}}
# {{{ ps_root_prompt
ps_root_prompt() {
    local uid="${EUID:-$(id -u 2>/dev/null)}"

    [ "$uid" = "0" ] || return 0
    printf '#\n'
}
# }}}
# }}}

# {{{ Path & Environment
# {{{ ps_path
ps_path() {
    path_prompt_generate "${1:-$PWD}"
}
# }}}

# {{{ ps_chroot
ps_chroot() {
    local chroot=""

    if [ -n "${debian_chroot:-}" ]; then
        chroot="$debian_chroot"
    elif [ -r /etc/debian_chroot ]; then
        chroot="$(sed -n '1p' /etc/debian_chroot 2>/dev/null)"
    fi

    [ -n "$chroot" ] || return 0
    printf '%s\n' "$chroot"
}
# }}}

# {{{ ps_venv
ps_venv() {
    local env_name=""

    if [ -n "${VIRTUAL_ENV:-}" ]; then
        env_name="${VIRTUAL_ENV##*/}"
    elif [ -n "${CONDA_DEFAULT_ENV:-}" ]; then
        env_name="$CONDA_DEFAULT_ENV"
    fi

    [ -n "$env_name" ] || return 0
    printf '%s\n' "$env_name"
}
# }}}

# ps_lang() { # TODO: language version (node/go/ruby/rust/etc.) }
# ps_kube() { # TODO: kubectl context/namespace }
# ps_tf() { # TODO: terraform workspace }
# }}}

# {{{ VCS & Project
# {{{ ps_git
ps_git() {
    local branch state=""

    command -v git >/dev/null 2>&1 || return 0
    git rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 0

    branch="$(git symbolic-ref --quiet --short HEAD 2>/dev/null \
        || git rev-parse --short HEAD 2>/dev/null)" || return 0
    [ -n "$branch" ] || return 0

    git diff --quiet --ignore-submodules -- 2>/dev/null || state="${state}*"
    git diff --cached --quiet --ignore-submodules -- 2>/dev/null || state="${state}+"
    if [ -n "$(git ls-files --others --exclude-standard 2>/dev/null | sed -n '1p')" ]; then
        state="${state}?"
    fi

    printf '%s%s\n' "$branch" "$state"
}
# }}}

# ps_hg() { # TODO: hg branch/status }
# ps_svn() { # TODO: svn info }
# ps_pkg() { # TODO: project/package version }
# }}}

# {{{ System & Status
# {{{ ps_status
ps_status() {
    local status=$?

    [ "$#" -gt 0 ] && status="$1"
    [ "$status" = "0" ] && return 0
    printf '%s\n' "$status"
}
# }}}

# {{{ ps_jobs
ps_jobs() {
    local count

    count="$(jobs -p 2>/dev/null | wc -l)" || return 0
    count="${count//[[:space:]]/}"
    [ "${count:-0}" -gt 0 ] || return 0
    printf '%s\n' "$count"
}
# }}}

# {{{ ps_load
ps_load() {
    if [ -r /proc/loadavg ]; then
        awk '{print $1}' /proc/loadavg 2>/dev/null
    else
        uptime 2>/dev/null | awk -F'load averages?: ' '{print $2}' | awk -F', ' '{print $1}'
    fi
}
# }}}

# {{{ ps_mem
ps_mem() {
    if [ -r /proc/meminfo ]; then
        awk '
            /^MemTotal:/ { total = $2 }
            /^MemAvailable:/ { available = $2 }
            /^MemFree:/ { free = $2 }
            /^Buffers:/ { buffers = $2 }
            /^Cached:/ { cached = $2 }
            /^SReclaimable:/ { sreclaimable = $2 }
            /^Shmem:/ { shmem = $2 }
            END {
                if (available <= 0) {
                    available = free + buffers + cached + sreclaimable - shmem
                }
                if (total > 0 && available > 0) {
                    printf "%d%%\n", ((total - available) * 100) / total
                }
            }
        ' /proc/meminfo 2>/dev/null
    elif command -v free >/dev/null 2>&1; then
        free -m 2>/dev/null | awk '/^Mem:/ && $2 > 0 { printf "%d%%\n", ($3 * 100) / $2 }'
    fi
}
# }}}

# ps_battery() { # TODO: battery info }
# ps_temp() { # TODO: cpu/gpu temperature }
# {{{ ps_uptime
ps_uptime() {
    local seconds days hours minutes

    if [ -r /proc/uptime ]; then
        seconds="$(awk '{printf "%d", $1}' /proc/uptime 2>/dev/null)" || return 0
        days=$((seconds / 86400))
        hours=$(((seconds % 86400) / 3600))
        minutes=$(((seconds % 3600) / 60))

        if [ "$days" -gt 0 ]; then
            printf '%dd%dh\n' "$days" "$hours"
        elif [ "$hours" -gt 0 ]; then
            printf '%dh%02dm\n' "$hours" "$minutes"
        else
            printf '%dm\n' "$minutes"
        fi
    else
        uptime -p 2>/dev/null | sed 's/^up //'
    fi
}
# }}}

# ps_net() { # TODO: IP/wifi/vpn info }
# }}}

# {{{ Time & Session
# {{{ ps_time
ps_time() {
    date +"${PS_TIME_FORMAT:-%H:%M:%S}"
}
# }}}

# {{{ ps_date
ps_date() {
    date +"${PS_DATE_FORMAT:-%F}"
}
# }}}

# ps_timer() { # TODO: elapsed time since last command }
# {{{ ps_hist
ps_hist() {
    [ -n "${HISTCMD:-}" ] || return 0
    printf '%s\n' "$HISTCMD"
}
# }}}
# }}}

# {{{ Decorations
# {{{ ps_char
ps_char() {
    local uid="${EUID:-$(id -u 2>/dev/null)}"

    if [ "$uid" = "0" ]; then
        printf '%s\n' "$PS_CHAR_ROOT"
    else
        printf '%s\n' "$PS_CHAR_USER"
    fi
}
# }}}

# {{{ ps_sep
ps_sep() {
    printf '%s\n' "$PS_SEPARATOR"
}
# }}}

# {{{ ps_newline
ps_newline() {
    printf '\\n'
}
# }}}

# {{{ ps_color
_ps_color_value() {
    local name="${1^^}"

    case "$name" in
        BLACK|RED|GREEN|YELLOW|BLUE|MAGENTA|CYAN|WHITE|GRAY)
            printf '%s' "${!name-}"
            ;;
        BRIGHT_BLACK|BRIGHT_RED|BRIGHT_GREEN|BRIGHT_YELLOW)
            printf '%s' "${!name-}"
            ;;
        BRIGHT_BLUE|BRIGHT_MAGENTA|BRIGHT_CYAN|BRIGHT_WHITE)
            printf '%s' "${!name-}"
            ;;
        BG_BLACK|BG_RED|BG_GREEN|BG_YELLOW|BG_BLUE|BG_MAGENTA|BG_CYAN|BG_WHITE)
            printf '%s' "${!name-}"
            ;;
        BG_BRIGHT_BLACK|BG_BRIGHT_RED|BG_BRIGHT_GREEN|BG_BRIGHT_YELLOW)
            printf '%s' "${!name-}"
            ;;
        BG_BRIGHT_BLUE|BG_BRIGHT_MAGENTA|BG_BRIGHT_CYAN|BG_BRIGHT_WHITE)
            printf '%s' "${!name-}"
            ;;
        BOLD|DIM|UNDERLINE|RESET|NC|BG_RESET)
            printf '%s' "${!name-}"
            ;;
        *)
            return 1
            ;;
    esac
}

ps_color() {
    local name value

    [ "$#" -gt 0 ] || set -- reset
    for name in "$@"; do
        value="$(_ps_color_value "$name")" || return
        [ -n "$value" ] || continue
        printf '\\[%s\\]' "$value"
    done
}
# }}}
# }}}



# {{{ path_prompt_generate
path_prompt_generate() {
  local fullpath="${1:-$PWD}"
  local IFS='/'
  read -ra parts <<< "$fullpath"

  local HEAD_COUNT="${PS_PATH_HEAD_COUNT:-2}"     # 头部完整保留的目录数量
  local TAIL_COUNT="${PS_PATH_TAIL_COUNT:-2}"     # 尾部完整保留的目录数量
  local ABBREV_LEN="${PS_PATH_ABBREV_LEN:-1}"     # 中间目录缩写保留几个字母

  [[ "$HEAD_COUNT" =~ ^[0-9]+$ ]] || HEAD_COUNT=2
  [[ "$TAIL_COUNT" =~ ^[0-9]+$ ]] || TAIL_COUNT=2
  [[ "$ABBREV_LEN" =~ ^[0-9]+$ ]] || ABBREV_LEN=1

  local total=${#parts[@]}
  local result=""

  # 边界检查：如果目录层级太少，就直接返回原路径
  if (( total <= HEAD_COUNT + TAIL_COUNT )); then
    echo "$fullpath"
    return
  fi

  # 保留头部完整目录
  for ((i=0; i<HEAD_COUNT; i++)); do
    [[ -n "${parts[i]}" ]] && result+="/${parts[i]}"
  done

  # 缩写中间目录
  for ((i=HEAD_COUNT; i<total-TAIL_COUNT; i++)); do
    if [[ -n "${parts[i]}" ]]; then
      result+="/${parts[i]:0:ABBREV_LEN}"
    fi
  done

  # 保留尾部完整目录
  for ((i=total-TAIL_COUNT; i<total; i++)); do
    [[ -n "${parts[i]}" ]] && result+="/${parts[i]}"
  done

  echo "$result"
}
# }}}
# some ideas:
# provide current port listening status (netstat -tuln)
