#!/usr/bin/env bash
# zsh config installer & setup script
# Usage: bash scripts/run_zsh.sh

set -euo pipefail

log() {
  printf '[INFO] %s\n' "$1"
}

warn() {
  printf '[WARN] %s\n' "$1"
}

err() {
  printf '[ERROR] %s\n' "$1" >&2
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1
}

run_as_root() {
  if [ "$(id -u)" -eq 0 ]; then
    "$@"
  elif require_cmd sudo; then
    sudo "$@"
  else
    err "root 권한이 필요하지만 sudo를 찾을 수 없습니다: $*"
    exit 1
  fi
}

detect_os() {
  if [ -f /etc/os-release ]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    OS_ID="${ID:-unknown}"
    OS_VERSION_ID="${VERSION_ID:-unknown}"
    OS_ID_LIKE="${ID_LIKE:-}"
  else
    err "/etc/os-release 파일을 찾을 수 없어 OS를 판별할 수 없습니다."
    exit 1
  fi
}

install_zsh_by_os() {
  detect_os

  log "Detected OS: ${OS_ID} ${OS_VERSION_ID}"

  case "$OS_ID" in
    ubuntu|debian)
      run_as_root apt-get update
      run_as_root apt-get install -y zsh git curl
      ;;
    centos)
      if [[ "${OS_VERSION_ID%%.*}" -ge 8 ]]; then
        if require_cmd dnf; then
          run_as_root dnf install -y zsh git curl
        else
          run_as_root yum install -y zsh git curl
        fi
      else
        # CentOS 7 이하
        run_as_root yum install -y epel-release || true
        run_as_root yum install -y zsh git curl
      fi
      ;;
    rhel)
      if [[ "${OS_VERSION_ID%%.*}" -ge 8 ]]; then
        if require_cmd dnf; then
          run_as_root dnf install -y zsh git curl
        else
          run_as_root yum install -y zsh git curl
        fi
      else
        run_as_root yum install -y epel-release || true
        run_as_root yum install -y zsh git curl
      fi
      ;;
    rocky|almalinux)
      if require_cmd dnf; then
        run_as_root dnf install -y zsh git curl
      else
        run_as_root yum install -y zsh git curl
      fi
      ;;
    amzn)
      # Amazon Linux 2 / 2023 대응
      if require_cmd dnf; then
        run_as_root dnf install -y zsh git curl
      else
        run_as_root yum install -y zsh git curl
      fi
      ;;
    *)
      # ID_LIKE 기반 fallback
      if [[ "$OS_ID_LIKE" == *debian* ]]; then
        run_as_root apt-get update
        run_as_root apt-get install -y zsh git curl
      elif [[ "$OS_ID_LIKE" == *rhel* ]] || [[ "$OS_ID_LIKE" == *fedora* ]]; then
        if require_cmd dnf; then
          run_as_root dnf install -y zsh git curl
        elif require_cmd yum; then
          run_as_root yum install -y zsh git curl
        else
          err "지원 가능한 패키지 매니저(dnf/yum)를 찾지 못했습니다."
          exit 1
        fi
      else
        err "지원하지 않는 OS입니다: ID=$OS_ID, ID_LIKE=$OS_ID_LIKE"
        exit 1
      fi
      ;;
  esac
}

ensure_zsh_installed() {
  if require_cmd zsh; then
    log "zsh is already installed: $(command -v zsh)"
    return
  fi

  log "zsh가 설치되어 있지 않아 설치를 진행합니다."
  install_zsh_by_os

  if ! require_cmd zsh; then
    err "zsh 설치에 실패했습니다."
    exit 1
  fi
}

install_cli_tools() {
  . /etc/os-release

  case "$ID" in
    ubuntu|debian)
      sudo apt update
      sudo apt install -y \
        fd-find \
        ripgrep

      # fd alias
      if command -v fdfind >/dev/null; then
        mkdir -p ~/.local/bin
        ln -sf "$(which fdfind)" ~/.local/bin/fd
      fi
      ;;
    centos|rocky|almalinux|rhel)
      sudo dnf install -y fd-find ripgrep || sudo yum install -y fd-find ripgrep
      ;;
  esac
}

change_default_shell_if_needed() {
  local zsh_path
  zsh_path="$(command -v zsh)"

  if [ -z "$zsh_path" ]; then
    err "zsh 경로를 찾을 수 없습니다."
    exit 1
  fi

  if [ "${SHELL:-}" = "$zsh_path" ]; then
    log "기본 쉘이 이미 zsh 입니다."
    return
  fi

  if ! grep -qx "$zsh_path" /etc/shells 2>/dev/null; then
    log "/etc/shells 에 zsh 경로를 추가합니다: $zsh_path"
    run_as_root sh -c "echo '$zsh_path' >> /etc/shells"
  fi

  if require_cmd chsh; then
    log "기본 쉘을 zsh로 변경합니다."
    chsh -s "$zsh_path" "$USER" || warn "chsh 실행에 실패했습니다. 수동으로 변경해야 할 수 있습니다."
  else
    warn "chsh 명령어가 없어 기본 쉘 변경을 건너뜁니다."
  fi
}

backup_and_link_zshrc() {
  local target="$HOME/.zshrc"
  local source="$ZSH_CONFIG_DIR/zshrc"

  if [ ! -f "$source" ]; then
    err "zshrc 파일을 찾을 수 없습니다: $source"
    exit 1
  fi

  if [ -f "$target" ] || [ -L "$target" ]; then
    local backup_path="$HOME/.zshrc.backup.$(date +%Y%m%d%H%M%S)"
    mv "$target" "$backup_path"
    log "기존 ~/.zshrc 백업 완료: $backup_path"
  fi

  ln -sf "$source" "$target"
  log "~/.zshrc -> $source 심볼릭 링크 생성 완료"
}

copy_config_files() {
  mkdir -p "$ZSH_TARGET_DIR"

  # README.md, install_zsh.sh, zshrc는 제외
  while IFS= read -r -d '' file; do
    cp "$file" "$ZSH_TARGET_DIR/"
  done < <(
    find "$ZSH_CONFIG_DIR" \
      -maxdepth 1 \
      -type f \
      ! -name "README.md" \
      ! -name "install_zsh.sh" \
      ! -name "zshrc" \
      -print0
  )

  if [ -d "$ZSH_CONFIG_DIR/functions" ]; then
    mkdir -p "$ZSH_TARGET_DIR/functions"
    cp -r "$ZSH_CONFIG_DIR/functions/." "$ZSH_TARGET_DIR/functions/"
  fi
}

main() {
  # Get absolute path to config/zsh
  SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
  ZSH_CONFIG_DIR="$SCRIPT_DIR/../config/zsh"
  ZSH_CONFIG_DIR="$(cd "$ZSH_CONFIG_DIR" && pwd)"
  ZSH_TARGET_DIR="$HOME/.config/zsh"

  ensure_zsh_installed
  install_cli_tools

  # 기존 install_zsh.sh가 있으면 추가 설정용으로 실행
  if [ -x "$ZSH_CONFIG_DIR/install_zsh.sh" ]; then
    log "config/zsh/install_zsh.sh 실행"
    "$ZSH_CONFIG_DIR/install_zsh.sh"
  elif [ -f "$ZSH_CONFIG_DIR/install_zsh.sh" ]; then
    log "config/zsh/install_zsh.sh 실행 (bash)"
    bash "$ZSH_CONFIG_DIR/install_zsh.sh"
  fi

  copy_config_files
  backup_and_link_zshrc
  change_default_shell_if_needed

  cat <<EOF
Zsh config installed successfully!
- OS detected: ${OS_ID} ${OS_VERSION_ID}
- zsh installed: $(command -v zsh)
- Config files copied to: $ZSH_TARGET_DIR
- ~/.zshrc symlinked to: $ZSH_CONFIG_DIR/zshrc
- Previous ~/.zshrc backed up if it existed

To apply changes:
  exec zsh
or
  source ~/.zshrc
EOF
}

main "$@"