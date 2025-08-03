#!/bin/bash

# Kitty Terminal Emulator 설치 스크립트
# 지원 OS: macOS, Ubuntu, Debian, Fedora, CentOS, RHEL, Arch, Manjaro

set -e  # 에러 발생시 스크립트 중단

echo "🐱 Kitty Terminal Emulator 설치를 시작합니다..."

# OS 감지 및 설치
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "📱 macOS 감지됨 - Homebrew로 설치 중..."
    if ! command -v brew &> /dev/null; then
        echo "❌ Homebrew가 설치되어 있지 않습니다."
        echo "   먼저 Homebrew를 설치해주세요: https://brew.sh/"
        exit 1
    fi
    brew install kitty
    
elif [[ -f /etc/os-release ]]; then
    . /etc/os-release
    echo "🐧 Linux 배포판 감지됨: $ID"
    
    case $ID in
        ubuntu|debian)
            echo "📦 apt 패키지 매니저로 설치 중..."
            sudo apt update
            sudo apt install -y kitty
            ;;
        fedora|centos|rhel)
            if command -v dnf &> /dev/null; then
                echo "📦 dnf 패키지 매니저로 설치 중..."
                sudo dnf install -y kitty
            else
                echo "📦 yum 패키지 매니저로 설치 중..."
                sudo yum install -y kitty
            fi
            ;;
        arch|manjaro)
            echo "📦 pacman 패키지 매니저로 설치 중..."
            sudo pacman -S --noconfirm kitty
            ;;
        *)
            echo "❌ 지원되지 않는 Linux 배포판: $ID"
            echo "   수동으로 kitty를 설치해주세요."
            echo "   공식 문서: https://sw.kovidgoyal.net/kitty/binary/"
            exit 1
            ;;
    esac
else
    echo "❌ OS를 감지할 수 없습니다."
    echo "   지원되는 OS: macOS, Ubuntu, Debian, Fedora, CentOS, RHEL, Arch, Manjaro"
    exit 1
fi

# Kitty 설정 디렉토리 생성
echo "📁 Kitty 설정 디렉토리 생성 중..."
mkdir -p ~/.config/kitty

# 설치 완료 확인
if command -v kitty &> /dev/null; then
    echo "✅ Kitty 설치가 완료되었습니다!"
    echo "   버전: $(kitty --version)"
    echo ""
    echo "다음 단계:"
    echo "1. 설정 파일 복사: cp kitty.conf ~/.config/kitty/kitty.conf"
    echo "2. Shell aliases 설정: ./setup_aliases.sh"
else
    echo "❌ Kitty 설치에 실패했습니다."
    exit 1
fi
