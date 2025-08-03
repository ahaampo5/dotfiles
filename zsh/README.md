# Zsh 설정

이 디렉토리는 Zsh 셸의 설정과 설치를 관리합니다.

## 📁 파일 구조

```
zsh/
├── install_zsh.sh    # Zsh 자동 설치 및 설정 스크립트
├── zshrc            # .zshrc 설정 파일 (대화형 셸 설정)
├── zshenv           # .zshenv 설정 파일 (환경 변수)
└── README.md        # 이 파일
```

## 🚀 사용법

### 1. 자동 설치
```bash
./install_zsh.sh
```

### 2. 수동 설정
설정 파일을 수동으로 심볼릭 링크로 연결:
```bash
ln -sf $(pwd)/zshrc ~/.zshrc
ln -sf $(pwd)/zshenv ~/.zshenv
```

## 📋 설치되는 내용

### 패키지
- **zsh**: Z Shell - 강력한 명령행 셸
- **git**: 분산 버전 관리 시스템
- **curl**: URL을 통한 데이터 전송 도구
- **wget**: 웹에서 파일 다운로드 도구
- **fzf**: 커맨드라인 퍼지 파인더
- **tree**: 디렉토리 구조를 트리 형태로 표시
- **neofetch**: 시스템 정보 표시 도구
- **tmux**: 터미널 멀티플렉서
- **neovim**: 향상된 Vim 에디터

### 플러그인
- **zsh-autosuggestions**: 명령어 히스토리 기반 자동 완성 제안
- **zsh-syntax-highlighting**: 명령어 구문 하이라이팅
- **fzf-tab**: fzf를 이용한 탭 자동완성 개선
- **zsh-history-substring-search**: 히스토리에서 부분 문자열 검색

### 테마
- **agnoster**: 깔끔하고 정보가 풍부한 프롬프트 테마

## 🔧 파일 설명

### `.zshrc` (zshrc)
- Oh My Zsh 설정
- 플러그인 설정
- 별칭(alias) 정의
- 사용자 정의 함수

### `.zshenv` (zshenv)
- 환경 변수 설정
- PATH 설정
- 크로스 플랫폼 호환성을 위한 OS별 설정

## 💡 크로스 플랫폼 지원

이 설정은 다음 운영체제에서 동작합니다:
- macOS (Homebrew)
- Ubuntu/Debian (apt)
- Fedora (dnf)
- Arch Linux (pacman)

## 🔄 업데이트

설정을 변경한 후:
```bash
source ~/.zshrc
# 또는
exec zsh
```

## 🎯 주요 기능

### 유용한 별칭
- `ll`, `la`, `l`: 파일 목록 표시
- `..`, `...`: 상위 디렉토리 이동
- `gs`, `ga`, `gc`: Git 명령어 단축

### 사용자 정의 함수
- `mkcd`: 디렉토리 생성 후 이동

### 환경 설정
- 에디터: neovim
- 언어: UTF-8
- FZF 통합
