#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

echo "=== Zsh install/setup ==="

# true 로 바꾸면 기본 쉘을 zsh로 변경
SET_ZSH_AS_DEFAULT=false

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log()  { printf '[INFO] %s\n' "$1"; }
warn() { printf '[WARN] %s\n' "$1"; }
err()  { printf '[ERROR] %s\n' "$1" >&2; }

has_cmd() {
  command -v "$1" >/dev/null 2>&1
}

run_privileged() {
  if [[ "$(id -u)" -eq 0 ]]; then
    "$@"
  elif has_cmd sudo; then
    sudo "$@"
  else
    err "sudo가 필요합니다: $*"
    exit 1
  fi
}

OS_ID=""
OS_VERSION_ID=""
OS_ID_LIKE=""

detect_os() {
  if [[ "${OSTYPE:-}" == darwin* ]]; then
    OS_ID="macos"
    OS_VERSION_ID="$(sw_vers -productVersion 2>/dev/null || echo unknown)"
    OS_ID_LIKE="darwin"
    return
  fi

  if [[ -f /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    OS_ID="${ID:-unknown}"
    OS_VERSION_ID="${VERSION_ID:-unknown}"
    OS_ID_LIKE="${ID_LIKE:-}"
  else
    err "/etc/os-release 를 찾을 수 없어 OS 판별 실패"
    exit 1
  fi
}

install_homebrew_if_needed() {
  if has_cmd brew; then
    return
  fi

  log "Homebrew가 없어 설치를 진행합니다."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
}

install_packages_macos() {
  install_homebrew_if_needed

  local packages=(
    zsh git curl wget
    bat fzf fd ripgrep tree
    tmux neovim zoxide
    fontconfig unzip
  )

  log "macOS: Homebrew 패키지 설치"
  brew install "${packages[@]}"

  if brew info fastfetch >/dev/null 2>&1; then
    brew install fastfetch || true
  fi
}

install_packages_apt() {
  log "Debian/Ubuntu: apt 패키지 설치"
  run_privileged apt-get update

  local packages=(
    zsh git curl wget
    bat fd-find ripgrep fzf tree
    tmux neovim zoxide
    fontconfig unzip
  )

  run_privileged apt-get install -y "${packages[@]}"

  # fastfetch는 일부 버전 repo에 없을 수 있으므로 optional
  if apt-cache show fastfetch >/dev/null 2>&1; then
    run_privileged apt-get install -y fastfetch || true
  else
    warn "fastfetch 패키지를 공식 repo에서 찾지 못해 건너뜁니다."
  fi
}

install_packages_dnf() {
  log "RHEL/Fedora 계열: dnf 패키지 설치"

  local packages=(
    zsh git curl wget
    bat fd-find ripgrep fzf tree
    tmux neovim zoxide
    fontconfig unzip
  )

  run_privileged dnf install -y "${packages[@]}" || {
    warn "일부 패키지 설치 실패 가능성이 있습니다. 가능한 패키지만 재시도합니다."
    run_privileged dnf install -y zsh git curl wget fzf tree tmux neovim fontconfig unzip
  }

  if dnf info fastfetch >/dev/null 2>&1; then
    run_privileged dnf install -y fastfetch || true
  else
    warn "fastfetch 패키지를 repo에서 찾지 못해 건너뜁니다."
  fi
}

install_packages_yum() {
  log "CentOS/RHEL(legacy): yum 패키지 설치"

  run_privileged yum install -y epel-release || true

  local packages=(
    zsh git curl wget
    fzf tree
    tmux neovim
    fontconfig unzip
  )

  run_privileged yum install -y "${packages[@]}" || true

  # 선택 패키지 개별 시도
  run_privileged yum install -y ripgrep || true
  run_privileged yum install -y fd-find || true
  run_privileged yum install -y bat || true
  run_privileged yum install -y zoxide || true
  run_privileged yum install -y fastfetch || true
}

install_packages_pacman() {
  log "Arch Linux: pacman 패키지 설치"

  local packages=(
    zsh git curl wget
    bat fzf fd ripgrep tree
    tmux neovim zoxide
    fontconfig unzip
    fastfetch
  )

  run_privileged pacman -Sy --noconfirm "${packages[@]}"
}

install_packages() {
  detect_os
  log "Detected OS: ${OS_ID} ${OS_VERSION_ID}"

  case "$OS_ID" in
    macos)
      install_packages_macos
      ;;
    ubuntu|debian)
      install_packages_apt
      ;;
    fedora|rocky|almalinux)
      install_packages_dnf
      ;;
    rhel)
      if has_cmd dnf; then
        install_packages_dnf
      else
        install_packages_yum
      fi
      ;;
    centos)
      if has_cmd dnf; then
        install_packages_dnf
      else
        install_packages_yum
      fi
      ;;
    arch|manjaro)
      install_packages_pacman
      ;;
    *)
      if [[ "$OS_ID_LIKE" == *debian* ]] && has_cmd apt-get; then
        install_packages_apt
      elif [[ "$OS_ID_LIKE" == *rhel* ]] && has_cmd dnf; then
        install_packages_dnf
      elif [[ "$OS_ID_LIKE" == *rhel* ]] && has_cmd yum; then
        install_packages_yum
      else
        err "지원되지 않는 OS입니다: ID=$OS_ID, ID_LIKE=$OS_ID_LIKE"
        exit 1
      fi
      ;;
  esac
}

ensure_local_bin() {
  mkdir -p "$HOME/.local/bin"
}

setup_binary_compat_links() {
  ensure_local_bin

  # Ubuntu/Debian: fd-find -> fd
  if ! has_cmd fd && has_cmd fdfind; then
    ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
    log "fd compatibility symlink created: ~/.local/bin/fd -> fdfind"
  fi

  # Ubuntu/Debian: bat -> batcat
  if ! has_cmd bat && has_cmd batcat; then
    ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
    log "bat compatibility symlink created: ~/.local/bin/bat -> batcat"
  fi
}

set_default_shell_if_requested() {
  if [[ "$SET_ZSH_AS_DEFAULT" != "true" ]]; then
    log "기본 쉘 변경은 생략합니다. 필요하면 SET_ZSH_AS_DEFAULT=true 로 변경하세요."
    return
  fi

  if ! has_cmd zsh; then
    warn "zsh가 설치되지 않아 기본 쉘 변경을 건너뜁니다."
    return
  fi

  local zsh_path
  zsh_path="$(command -v zsh)"

  if [[ -f /etc/shells ]] && ! grep -qx "$zsh_path" /etc/shells; then
    log "/etc/shells 에 zsh 경로 추가: $zsh_path"
    echo "$zsh_path" | run_privileged tee -a /etc/shells >/dev/null
  fi

  if [[ "${SHELL:-}" == "$zsh_path" ]]; then
    log "이미 기본 쉘이 zsh 입니다."
    return
  fi

  if has_cmd chsh; then
    log "기본 쉘을 zsh로 변경"
    chsh -s "$zsh_path" "$USER" || warn "chsh 실패. 수동 변경이 필요할 수 있습니다."
  else
    warn "chsh 명령이 없어 기본 쉘 변경을 건너뜁니다."
  fi
}

install_oh_my_zsh() {
  local omz_dir="$HOME/.oh-my-zsh"

  if [[ -d "$omz_dir" ]]; then
    log "기존 Oh My Zsh 유지"
    return
  fi

  log "Oh My Zsh 설치"
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || {
      err "Oh My Zsh 설치 실패"
      exit 1
    }
}

install_plugin() {
  local plugin_name="$1"
  local plugin_url="$2"
  local plugin_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/$plugin_name"

  if [[ -d "$plugin_dir" ]]; then
    log "plugin already exists: $plugin_name"
    return
  fi

  log "plugin install: $plugin_name"
  git clone --depth=1 "$plugin_url" "$plugin_dir"
}

install_plugins() {
  install_plugin "zsh-autosuggestions" "https://github.com/zsh-users/zsh-autosuggestions"
  install_plugin "zsh-syntax-highlighting" "https://github.com/zsh-users/zsh-syntax-highlighting"
  install_plugin "zsh-history-substring-search" "https://github.com/zsh-users/zsh-history-substring-search"
  install_plugin "fzf-tab" "https://github.com/Aloxaf/fzf-tab"
}

install_nerd_font() {
  local font_name="JetBrainsMono"
  local version="v3.2.1"
  local zip_name="${font_name}.zip"
  local url="https://github.com/ryanoasis/nerd-fonts/releases/download/${version}/${zip_name}"

  if has_cmd fc-list && fc-list | grep -qi "JetBrainsMono Nerd Font"; then
    log "JetBrainsMono Nerd Font already installed"
    return
  fi

  log "Nerd Font 설치: JetBrainsMono Nerd Font"

  local tmp_dir
  tmp_dir="$(mktemp -d)"
  local fonts_dir="$HOME/.local/share/fonts"

  mkdir -p "$fonts_dir"

  if has_cmd curl; then
    curl -fsSL -o "$tmp_dir/$zip_name" "$url"
  elif has_cmd wget; then
    wget -q -O "$tmp_dir/$zip_name" "$url"
  else
    warn "curl/wget이 없어 Nerd Font 설치를 건너뜁니다."
    rm -rf "$tmp_dir"
    return
  fi

  unzip -oq "$tmp_dir/$zip_name" -d "$fonts_dir"

  if [[ "${OSTYPE:-}" == darwin* ]]; then
    mkdir -p "$HOME/Library/Fonts"
    find "$fonts_dir" -type f \( -name "*.ttf" -o -name "*.otf" \) -exec cp -f {} "$HOME/Library/Fonts/" \; 2>/dev/null || true
  fi

  if has_cmd fc-cache; then
    fc-cache -f >/dev/null 2>&1 || true
  fi

  rm -rf "$tmp_dir"
  log "Nerd Font 설치 완료"
}

main() {
  install_packages
  setup_binary_compat_links
  set_default_shell_if_requested
  install_oh_my_zsh
  install_plugins
  install_nerd_font

  cat <<EOF
[OK] zsh setup finished

Next steps:
1. dotfiles의 zshrc, zshenv를 홈 디렉토리에 symlink 하세요
2. 새 터미널을 열거나 아래 명령 실행:
   exec zsh
EOF
}

main "$@"