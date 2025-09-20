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
        lan_ipv4) host="$()"
        lan_ipv6) host="$(hostname -I | awk '{for(i=1;i<=NF;i++) if($i ~ /:/) {print $i; exit}}')" ;;
        wan_ipv4) host="TODO_wan_ipv4" ;; # TODO
        wan_ipv6) host="TODO_wan_ipv6" ;; # TODO
        *)        host="${PS_HOSTNAME_PREFER}" ;; # just the value of PS_HOSTNAME_PREFER
    esac
    echo "$host"
}
# }}}
# ps_conn() { # TODO: detect SSH/VPN/TTY state }
# ps_root() { # TODO: show '#' if root, else '' }
# }}}

# {{{ Path & Environment
# ps_path() { # TODO: shortened PWD via path_prompt_generate }
# ps_chroot() { # TODO: detect chroot/container marker }
# ps_venv() { # TODO: python venv/conda }
# ps_lang() { # TODO: language version (node/go/ruby/rust/etc.) }
# ps_kube() { # TODO: kubectl context/namespace }
# ps_tf() { # TODO: terraform workspace }
# }}}

# {{{ VCS & Project
# ps_git() { # TODO: git branch/status }
# ps_hg() { # TODO: hg branch/status }
# ps_svn() { # TODO: svn info }
# ps_pkg() { # TODO: project/package version }
# }}}

# {{{ System & Status
# ps_status() { # TODO: exit code of last command }
# ps_jobs() { # TODO: background job count }
# ps_load() { # TODO: load average }
# ps_mem() { # TODO: memory usage }
# ps_battery() { # TODO: battery info }
# ps_temp() { # TODO: cpu/gpu temperature }
# ps_uptime() { # TODO: uptime }
# ps_net() { # TODO: IP/wifi/vpn info }
# }}}

# {{{ Time & Session
# ps_time() { # TODO: current time }
# ps_date() { # TODO: current date }
# ps_timer() { # TODO: elapsed time since last command }
# ps_hist() { # TODO: history number }
# }}}

# {{{ Decorations
# ps_char() { # TODO: prompt character }
# ps_sep() { # TODO: separator symbol }
# ps_newline() { # TODO: newline in PS1 }
# ps_color() { # TODO: handle ANSI color codes safely }
# }}}



# {{{ path_prompt_generate
path_prompt_generate() {
  local fullpath="$PWD"
  local IFS='/'
  read -ra parts <<< "$fullpath"

  local HEAD_COUNT=2         # 头部完整保留的目录数量
  local TAIL_COUNT=2         # 尾部完整保留的目录数量
  local ABBREV_LEN=1         # 中间目录缩写保留几个字母

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
