#!/bin/bash

# Kitty 관련 Shell Aliases 설정 스크립트

set -e

echo "🔧 Kitty 관련 shell aliases를 설정합니다..."

# 사용자의 기본 shell 확인
SHELL_CONFIG=""
if [[ -f ~/.zshrc ]]; then
    SHELL_CONFIG="$HOME/.zshrc"
    echo "📝 zsh 설정 파일 발견: ~/.zshrc"
elif [[ -f ~/.bashrc ]]; then
    SHELL_CONFIG="$HOME/.bashrc"
    echo "📝 bash 설정 파일 발견: ~/.bashrc"
else
    echo "❌ shell 설정 파일을 찾을 수 없습니다."
    echo "   ~/.zshrc 또는 ~/.bashrc 파일이 필요합니다."
    exit 1
fi

# Kitty aliases 추가 (중복 방지)
echo ""
echo "📦 Kitty aliases 추가 중..."

# 기존 aliases 확인 및 제거 (있다면)
if grep -q "# Kitty aliases" "$SHELL_CONFIG" 2>/dev/null; then
    echo "⚠️  기존 Kitty aliases가 발견되었습니다. 업데이트합니다..."
    # 임시 파일 생성하여 기존 Kitty aliases 제거
    sed '/# Kitty aliases/,/# End of Kitty aliases/d' "$SHELL_CONFIG" > "${SHELL_CONFIG}.tmp"
    mv "${SHELL_CONFIG}.tmp" "$SHELL_CONFIG"
fi

# 새로운 aliases 추가
cat >> "$SHELL_CONFIG" << 'EOL'

# Kitty aliases
alias diff='kitten diff'
alias icat='kitten icat'
alias ssh='kitten ssh'
# End of Kitty aliases
EOL

echo "✅ Kitty aliases가 추가되었습니다!"

# Welcome 메시지 추가 (선택사항)
echo ""
read -p "🎉 터미널 시작시 welcome 메시지를 추가하시겠습니까? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    
    # 기존 welcome 메시지 확인 및 제거
    if grep -q "# Kitty welcome message" "$SHELL_CONFIG" 2>/dev/null; then
        sed '/# Kitty welcome message/,/# End of Kitty welcome message/d' "$SHELL_CONFIG" > "${SHELL_CONFIG}.tmp"
        mv "${SHELL_CONFIG}.tmp" "$SHELL_CONFIG"
    fi
    
    # Welcome 메시지 추가
    cat >> "$SHELL_CONFIG" << 'EOL'

# Kitty welcome message
if [ -x "$(command -v neofetch)" ]; then
    neofetch --stdout
fi
echo "*******************************"
echo "   Welcome, $(whoami)! $(date +"%Y-%m-%d %H:%M:%S")"
echo "*******************************"
# End of Kitty welcome message
EOL
    
    echo "✅ Welcome 메시지가 추가되었습니다!"
else
    echo "⏭️  Welcome 메시지를 건너뜁니다."
fi

echo ""
echo "🎯 설정 완료! 다음 명령어로 설정을 적용하세요:"
echo "   source $SHELL_CONFIG"
echo ""
echo "🐱 사용 가능한 새로운 명령어:"
echo "   • diff file1 file2    - 파일 차이점 비교"
echo "   • icat image.png      - 터미널에서 이미지 보기"
echo "   • ssh user@host       - 향상된 SSH 연결"
