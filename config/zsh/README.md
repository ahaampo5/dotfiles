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
- **zoxide**: 스마트한 cd 대체 도구 (빈도 기반 디렉토리 이동)

### 플러그인
- **zsh-autosuggestions**: 명령어 히스토리 기반 자동 완성 제안
- **zsh-syntax-highlighting**: 명령어 구문 하이라이팅
- **fzf-tab**: fzf를 이용한 탭 자동완성 개선
- **zsh-history-substring-search**: 히스토리에서 부분 문자열 검색

### 테마
- **커스텀 2줄 프롬프트**: 정보와 입력을 분리한 깔끔한 프롬프트

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
- `cd`: zoxide를 통한 스마트한 디렉토리 이동 (빈도 기반)

### 사용자 정의 함수
- `mkcd`: 디렉토리 생성 후 이동
- `check_cpu`: CPU 정보 확인
- `check_ram`: 메모리 정보 확인  
- `check_disk`: 디스크 정보 확인
- `check_gpu`: GPU 정보 확인
- `check_os`: 운영체제 정보 확인
- `check_system`: 전체 시스템 정보 확인

### 환경 설정
- 에디터: neovim
- 언어: UTF-8
- FZF 통합
- Zoxide 통합 (스마트한 디렉토리 이동)
- 2줄 프롬프트 (정보와 입력 분리)

## 🎨 프롬프트 설정

### 커스텀 2줄 agnoster 스타일 프롬프트
현재 설정은 agnoster 스타일의 배경색과 구분자를 사용한 2줄 프롬프트입니다:

**첫 번째 줄 세그먼트들**:
- � **사용자@호스트**: 노란 배경 (`admin@MacBook-Pro`)
- �📂 **경로**: 파란 배경 (`~/projects/myproject`)
- 🌿 **Git**: 초록/빨간 배경 (`⎇ main` 또는 `⎇ main●`)
  - 초록색: 깨끗한 상태
  - 빨간색: 변경사항 있음
- 🐍 **Conda**: 노란 배경 (`🐍 myenv`)
- 🐍 **Python venv**: 초록 배경 (`🐍 venv-name`)

**두 번째 줄**:
- 명령어 입력 프롬프트 (`❯`) - 항상 첫 번째 위치부터 시작

### 프롬프트 예시
```
 admin@MacBook-Pro  ~/projects/myproject  ⎇ main●  🐍 data-science 
❯ 
```

### 특징
- ✨ **Powerline 스타일**: 삼각형 구분자와 배경색으로 세그먼트 분리
- 🎨 **색상 구분**: 각 정보 유형별로 다른 배경색 사용
- 📍 **고정 입력 위치**: 명령어 입력은 항상 두 번째 줄 첫 번째 위치
- 🔍 **상태 인식**: Git 상태, 환경 활성화 여부 등을 시각적으로 표시

## 🗂️ Zoxide 사용법

Zoxide는 자주 사용하는 디렉토리를 기억하여 빠른 이동을 지원합니다:

```bash
# 기본 사용법
cd /path/to/directory  # 처음 방문하여 데이터베이스에 추가
cd dir                 # 이후 부분 이름으로 이동 가능 (자동완성 지원)

# Tab 키를 눌러 자동완성 확인
cd proj<Tab>           # 'proj'로 시작하는 디렉토리들이 표시됨

# 추가 zoxide 명령어
zi                     # 대화형 디렉토리 선택 (fzf 스타일)
zb                     # 자주 방문한 디렉토리 목록 보기
cd ..                  # 일반적인 상위 디렉토리 이동도 계속 작동
```

### 💡 자동완성 팁
- **Tab 키**: `cd proj<Tab>`으로 자동완성 확인
- **부분 매칭**: 디렉토리 이름의 일부만 입력해도 매칭
- **빈도 기반**: 자주 방문하는 디렉토리가 우선 순위로 표시
- **대화형 선택**: `zi` 명령으로 fzf 스타일 선택 가능
