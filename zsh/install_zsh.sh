#!/bin/bash

set -e  # 에러 발생 시 스크립트 중단

echo "=== Zsh 설치 및 설정 스크립트 ==="

# 필수 패키지 목록
PACKAGES="zsh git curl wget fzf tree neofetch tmux neovim"

# 패키지 설치
install_packages() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "📦 macOS에서 Homebrew로 패키지 설치 중..."
        brew install $PACKAGES
    elif command -v apt &> /dev/null; then
        echo "📦 Ubuntu/Debian에서 apt로 패키지 설치 중..."
        sudo apt update && sudo apt install -y $PACKAGES
    elif command -v dnf &> /dev/null; then
        echo "📦 Fedora에서 dnf로 패키지 설치 중..."
        sudo dnf install -y $PACKAGES
    elif command -v pacman &> /dev/null; then
        echo "📦 Arch Linux에서 pacman으로 패키지 설치 중..."
        sudo pacman -S --noconfirm $PACKAGES
    else
        echo "❌ 지원되지 않는 패키지 매니저입니다."
        exit 1
    fi
}

# 패키지 설치 실행
install_packages

# 기본 셸을 zsh로 변경
if command -v zsh &> /dev/null; then
    echo "🔧 기본 셸을 zsh로 변경 중..."
    chsh -s $(which zsh)
    echo "✅ 기본 셸이 zsh로 변경되었습니다."
fi

# Oh My Zsh 설치
echo "🎨 Oh My Zsh 설치 중..."
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# 테마 변경
echo "🎨 테마를 agnoster로 변경 중..."
sed -i.bak 's/ZSH_THEME="robbyrussell"/ZSH_THEME="agnoster"/' ~/.zshrc

# 플러그인 설치
echo "🔌 플러그인 설치 중..."
PLUGIN_DIR="${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins"

# 플러그인 목록과 저장소
declare -A PLUGINS=(
    ["zsh-autosuggestions"]="https://github.com/zsh-users/zsh-autosuggestions"
    ["zsh-syntax-highlighting"]="https://github.com/zsh-users/zsh-syntax-highlighting"
    ["zsh-history-substring-search"]="https://github.com/zsh-users/zsh-history-substring-search"
    ["fzf-tab"]="https://github.com/Aloxaf/fzf-tab"
)

for plugin in "${!PLUGINS[@]}"; do
    if [ ! -d "$PLUGIN_DIR/$plugin" ]; then
        echo "  설치 중: $plugin"
        git clone "${PLUGINS[$plugin]}" "$PLUGIN_DIR/$plugin"
    fi
done

# 플러그인 활성화
echo "🔌 플러그인 활성화 중..."
sed -i.bak 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting fzf-tab zsh-history-substring-search)/' ~/.zshrc

# 설정 디렉토리 생성
mkdir -p ~/.config/nvim

# 설정 파일 심볼릭 링크 생성
echo "🔗 설정 파일 심볼릭 링크 생성 중..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 기존 파일 백업
if [ -f ~/.zshrc ]; then
    cp ~/.zshrc ~/.zshrc.backup.$(date +%Y%m%d_%H%M%S)
    echo "  기존 .zshrc를 백업했습니다."
fi

if [ -f ~/.zshenv ]; then
    cp ~/.zshenv ~/.zshenv.backup.$(date +%Y%m%d_%H%M%S)
    echo "  기존 .zshenv를 백업했습니다."
fi

# 심볼릭 링크 생성
ln -sf "$SCRIPT_DIR/zshrc" ~/.zshrc
ln -sf "$SCRIPT_DIR/zshenv" ~/.zshenv

echo "✅ Zsh 설치 및 설정이 완료되었습니다!"
echo "🔗 설정 파일들이 심볼릭 링크로 연결되었습니다:"
echo "  ~/.zshrc -> $SCRIPT_DIR/zshrc"
echo "  ~/.zshenv -> $SCRIPT_DIR/zshenv"
echo "💡 터미널을 다시 시작하거나 'exec zsh' 명령을 실행하세요."
