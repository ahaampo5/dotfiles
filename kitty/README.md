# Kitty Terminal Emulator 설정

이 디렉토리는 Kitty 터미널 에뮬레이터의 설치 및 설정을 위한 파일들을 포함합니다.

## 파일 구성

- `install_kitty.sh` - Kitty 설치 스크립트 (다양한 OS 지원)
- `kitty.conf` - Kitty 설정 파일 템플릿
- `setup_aliases.sh` - Kitty 관련 shell aliases 설정

## 설치 방법

### 1. Kitty 설치
```bash
./install_kitty.sh
```

### 2. 설정 파일 적용
```bash
cp kitty.conf ~/.config/kitty/kitty.conf
```

### 3. Shell aliases 설정
```bash
./setup_aliases.sh
```

## 지원 운영체제

- **macOS**: Homebrew를 통한 설치
- **Ubuntu/Debian**: apt 패키지 매니저
- **Fedora/CentOS/RHEL**: dnf/yum 패키지 매니저  
- **Arch/Manjaro**: pacman 패키지 매니저

## 주요 설정 특징

- **테마**: Dracula 컬러 스킴
- **폰트**: MesloLGS NF (Nerd Font)
- **투명도**: 92% 불투명도 with blur 효과
- **GPU 가속**: 활성화
- **단축키**: macOS/Linux 호환 키 맵핑

## 사용법

Kitty 설치 후 다음 명령어들을 사용할 수 있습니다:

```bash
# 파일 차이점 비교
kitten diff file1 file2

# 이미지 터미널에서 보기
kitten icat image.png
```

## 문제 해결

설치 중 문제가 발생하면:

1. 운영체제가 지원되는지 확인
2. 패키지 매니저가 최신 상태인지 확인
3. 권한 문제의 경우 sudo 사용 여부 확인

자세한 내용은 [Kitty 공식 문서](https://sw.kovidgoyal.net/kitty/)를 참조하세요.
