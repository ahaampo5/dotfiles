# 시스템 정보 확인 함수들

이 디렉토리에는 macOS와 Linux에서 시스템 정보를 확인할 수 있는 유용한 zsh 함수들이 포함되어 있습니다.

## 📁 함수 목록

### 🖥️ `check_os`
운영체제 정보를 확인합니다.
- macOS 버전, 빌드 번호
- 시스템 아키텍처 (Intel/Apple Silicon)
- 커널 버전
- 시스템 업타임

```bash
check_os
```

### 🔥 `check_cpu`
CPU 정보를 확인합니다.
- CPU 모델명과 사양
- 물리/논리 코어 수
- 최대 주파수
- 현재 사용률
- CPU 온도 (권한이 있을 경우)

```bash
check_cpu
```

### 💾 `check_ram`
메모리(RAM) 정보를 확인합니다.
- 총 메모리 용량
- 현재 사용량과 사용률
- Active, Inactive, Wired 메모리 세부 정보
- 메모리 압박 상태

```bash
check_ram
```

### 💿 `check_disk`
디스크 정보를 확인합니다.
- 마운트된 디스크 목록과 사용량
- 디스크 I/O 통계
- SSD 수명 정보
- 디스크 온도 (smartctl이 설치된 경우)

```bash
check_disk
```

### 🎮 `check_gpu`
GPU 정보를 확인합니다.
- 그래픽 카드 모델과 VRAM
- Metal 지원 여부
- GPU 사용률 (권한이 있을 경우)
- 외부 GPU(eGPU) 정보
- 연결된 디스플레이 정보

```bash
check_gpu
```

### 🖥️ `check_system` / `sysinfo`
모든 시스템 정보를 한 번에 확인하거나 개별 항목만 확인할 수 있습니다.

```bash
# 전체 시스템 정보 확인
check_system
sysinfo
sysinfo all

# 개별 정보 확인
sysinfo os          # 운영체제 정보
sysinfo cpu         # CPU 정보
sysinfo ram         # 메모리 정보
sysinfo memory      # 메모리 정보 (ram과 동일)
sysinfo disk        # 디스크 정보
sysinfo storage     # 디스크 정보 (disk와 동일)
sysinfo gpu         # GPU 정보
sysinfo graphics    # GPU 정보 (gpu와 동일)
```

## 🚀 설치 및 사용법

### 자동 로딩 (권장)
`zshrc` 파일에 함수 자동 로딩이 설정되어 있어 터미널을 새로 열거나 `source ~/.zshrc`를 실행하면 자동으로 모든 함수를 사용할 수 있습니다.

### 수동 로딩
특정 함수만 사용하고 싶다면:
```bash
source /path/to/dotfiles/zsh/functions/check_cpu
check_cpu
```

### 스크립트로 직접 실행
함수 파일을 직접 실행할 수도 있습니다:
```bash
./check_cpu
./check_system
```

## 🔧 필요한 도구들

대부분의 기능은 macOS 기본 도구를 사용하지만, 더 자세한 정보를 원한다면 다음 도구들을 설치할 수 있습니다:

### macOS
- `bc`: 계산용 (Homebrew: `brew install bc`)
- `smartctl`: 디스크 상태 확인 (Homebrew: `brew install smartmontools`)
- `iostat`: 디스크 I/O 통계 (기본 포함)
- `powermetrics`: CPU/GPU 상세 정보 (기본 포함, sudo 권한 필요)

### Linux
- `nvidia-smi`: NVIDIA GPU 정보
- `rocm-smi`: AMD GPU 정보
- `lspci`: PCI 디바이스 정보

## 📊 출력 예시

```
🖥️  운영체제 정보
====================
OS: macOS
버전: 14.1.1
빌드: 23B81
아키텍처: arm64
커널: 23.1.0
업타임: 2 days, 14:32

🔥 CPU 정보
================
CPU: Apple M2 Pro
물리 코어: 12
논리 코어: 12
현재 사용률: 15.2%

💾 메모리 정보
==================
총 메모리: 16.00 GB
사용 중: 8.45 GB
사용 가능: 7.55 GB
사용률: 52.8%
```

## 🛠️ 사용자 정의

각 함수는 독립적으로 작동하므로 필요에 따라 수정하거나 새로운 함수를 추가할 수 있습니다. 함수 파일은 실행 권한이 있어야 하며, zsh 함수 문법을 따라야 합니다.

## 🆘 문제 해결

### 권한 오류
일부 기능(CPU 온도, GPU 사용률 등)은 관리자 권한이 필요할 수 있습니다:
```bash
sudo check_cpu  # 또는
sudo sysinfo cpu
```

### 함수가 인식되지 않는 경우
```bash
# zsh 설정 다시 로드
source ~/.zshrc

# 또는 함수를 직접 로드
source /path/to/dotfiles/zsh/functions/check_system
```

### bc 명령어 오류
macOS에서 `bc` 명령어가 없다는 오류가 나올 경우:
```bash
brew install bc
```
