#!/bin/bash

# ================================
# Kitty Terminal Emulator 설정 마스터 스크립트
# ================================

set -e

echo "🐱 Kitty Terminal Emulator 설정을 시작합니다..."
echo ""

# 현재 스크립트의 디렉토리 확인
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KITTY_DIR="$SCRIPT_DIR/kitty"

# kitty 디렉토리가 존재하는지 확인
if [[ ! -d "$KITTY_DIR" ]]; then
    echo "❌ kitty 디렉토리를 찾을 수 없습니다: $KITTY_DIR"
    echo "   다음 명령어로 직접 실행해보세요:"
    echo "   cd kitty && ./install_kitty.sh"
    exit 1
fi

echo "📁 Kitty 설정 디렉토리: $KITTY_DIR"
echo ""

# 단계별 설치 진행
echo "1️⃣  Kitty 설치 중..."
if [[ -x "$KITTY_DIR/install_kitty.sh" ]]; then
    "$KITTY_DIR/install_kitty.sh"
else
    echo "❌ install_kitty.sh를 찾을 수 없거나 실행할 수 없습니다."
    exit 1
fi

echo ""
echo "2️⃣  설정 파일 복사 중..."
if [[ -f "$KITTY_DIR/kitty.conf" ]]; then
    mkdir -p ~/.config/kitty
    cp "$KITTY_DIR/kitty.conf" ~/.config/kitty/kitty.conf
    echo "✅ 설정 파일이 복사되었습니다: ~/.config/kitty/kitty.conf"
else
    echo "❌ kitty.conf 파일을 찾을 수 없습니다."
    exit 1
fi

echo ""
echo "3️⃣  Shell aliases 설정 중..."
if [[ -x "$KITTY_DIR/setup_aliases.sh" ]]; then
    "$KITTY_DIR/setup_aliases.sh"
else
    echo "❌ setup_aliases.sh를 찾을 수 없거나 실행할 수 없습니다."
    exit 1
fi

echo ""
echo "🎉 Kitty 설정이 모두 완료되었습니다!"
echo ""
echo "📖 자세한 정보는 다음 파일을 참조하세요:"
echo "   $KITTY_DIR/README.md"
echo ""
echo "🔄 설정을 즉시 적용하려면 다음 명령어를 실행하세요:"
if [[ -f ~/.zshrc ]]; then
    echo "   source ~/.zshrc"
elif [[ -f ~/.bashrc ]]; then
    echo "   source ~/.bashrc"
fi