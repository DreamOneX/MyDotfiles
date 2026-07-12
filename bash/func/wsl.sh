#!/usr/bin/env bash
# vim:ft=bash:foldmethod=marker

# {{{ clipboard
_wsl_require_powershell() {
  local name="$1"

  command -v powershell.exe >/dev/null 2>&1 && return 0
  printf '%s\n' "$name: powershell.exe not found; run this inside WSL with Windows interop enabled." >&2
  return 127
}

wslcopy() {
  _wsl_require_powershell wslcopy || return
  powershell.exe -NoLogo -NoProfile -NonInteractive -Command '[Console]::InputEncoding = [System.Text.UTF8Encoding]::new($false); $text = [Console]::In.ReadToEnd(); Set-Clipboard -Value $text'
}

wslpaste() {
  _wsl_require_powershell wslpaste || return
  powershell.exe -NoLogo -NoProfile -NonInteractive -Command '[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false); [Console]::Out.Write((Get-Clipboard -Raw))'
}
# }}}
