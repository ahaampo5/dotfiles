
# Dotfiles

개인 개발 환경 설정을 위한 dotfiles 모음입니다.

## 디렉토리 구조

```
├── zsh/                 # Zsh 설정
│   ├── install_zsh.sh   # Zsh 설치 스크립트
│   ├── zshrc           # Zsh 설정 파일
│   ├── zshenv          # 환경 변수 설정
│   └── README.md       # Zsh 설정 가이드
├── kitty/              # Kitty 터미널 설정
│   ├── install_kitty.sh # Kitty 설치 스크립트
│   ├── kitty.conf      # Kitty 설정 파일
│   ├── setup_aliases.sh # Shell aliases 설정
│   └── README.md       # Kitty 설정 가이드
├── kitty_setting.sh    # Kitty 통합 설치 스크립트
├── backend_dir.sh      # 백엔드 개발환경 설정
└── README.md          # 이 파일
```

## 빠른 설치

### 전체 설치
```bash
# Zsh 설정
./zsh/install_zsh.sh

# Kitty 터미널 설정
./kitty_setting.sh

# 기타 설정
cp .tmux_config ~/.tmux.conf
cp .nvim_config ~/.config/nvim/init.vim
```

### 개별 설치
```bash
# Zsh만 설치
cd zsh && ./install_zsh.sh

# Kitty만 설치  
cd kitty && ./install_kitty.sh
```

