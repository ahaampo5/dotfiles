#!/bin/bash

# 유틸리티 함수들
# 작성일: 2025년 8월 3일

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# 로그 함수들
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
    [[ "$VERBOSE" == "true" ]] && echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" >> "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
    [[ "$VERBOSE" == "true" ]] && echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" >> "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
    [[ "$VERBOSE" == "true" ]] && echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" >> "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
    [[ "$VERBOSE" == "true" ]] && echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" >> "$LOG_FILE"
}

log_debug() {
    [[ "$DEBUG" == "true" ]] && echo -e "${PURPLE}[DEBUG]${NC} $1"
}

# 진행률 표시
show_progress() {
    local current=$1
    local total=$2
    local task=$3
    local percentage=$((current * 100 / total))
    
    printf "\r${BLUE}[%3d%%]${NC} (%d/%d) %s" "$percentage" "$current" "$total" "$task"
    
    if [[ $current -eq $total ]]; then
        echo ""
    fi
}

# 명령어 존재 확인
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# OS 감지
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [[ -f /etc/debian_version ]]; then
            OS="ubuntu"
        elif [[ -f /etc/redhat-release ]]; then
            OS="centos"
        else
            OS="linux"
        fi
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ -n "$WSL_DISTRO_NAME" ]]; then
        OS="windows"
    else
        OS="unknown"
    fi
    
    log_debug "감지된 OS: $OS"
}

# kubectl 연결 확인
check_kubectl_connection() {
    if ! command_exists kubectl; then
        log_error "kubectl이 설치되지 않았습니다."
        return 1
    fi
    
    if ! kubectl cluster-info >/dev/null 2>&1; then
        log_error "Kubernetes 클러스터에 연결할 수 없습니다."
        log_error "kubeconfig가 올바르게 설정되어 있는지 확인하세요."
        return 1
    fi
    
    log_success "Kubernetes 클러스터 연결 확인"
    return 0
}

# 네임스페이스 존재 확인
namespace_exists() {
    local namespace=$1
    kubectl get namespace "$namespace" >/dev/null 2>&1
}

# 리소스 존재 확인
resource_exists() {
    local resource_type=$1
    local resource_name=$2
    local namespace=${3:-""}
    
    if [[ -n "$namespace" ]]; then
        kubectl get "$resource_type" "$resource_name" -n "$namespace" >/dev/null 2>&1
    else
        kubectl get "$resource_type" "$resource_name" >/dev/null 2>&1
    fi
}

# 대기 함수
wait_for_resource() {
    local resource_type=$1
    local resource_name=$2
    local namespace=$3
    local condition=$4
    local timeout=${5:-300}
    
    log_info "$resource_type/$resource_name 준비 대기 중... (최대 ${timeout}초)"
    
    if kubectl wait --for=condition="$condition" --timeout="${timeout}s" "$resource_type/$resource_name" -n "$namespace" >/dev/null 2>&1; then
        log_success "$resource_type/$resource_name 준비 완료"
        return 0
    else
        log_error "$resource_type/$resource_name 준비 실패 (타임아웃)"
        return 1
    fi
}

# 매니페스트 적용
apply_manifest() {
    local manifest_file=$1
    local namespace=${2:-""}
    
    if [[ ! -f "$manifest_file" ]]; then
        log_error "매니페스트 파일을 찾을 수 없습니다: $manifest_file"
        return 1
    fi
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] 매니페스트 적용: $manifest_file"
        if [[ -n "$namespace" ]]; then
            kubectl apply -f "$manifest_file" -n "$namespace" --dry-run=client
        else
            kubectl apply -f "$manifest_file" --dry-run=client
        fi
    else
        log_info "매니페스트 적용: $manifest_file"
        if [[ -n "$namespace" ]]; then
            kubectl apply -f "$manifest_file" -n "$namespace"
        else
            kubectl apply -f "$manifest_file"
        fi
    fi
}

# 환경 설정 초기화
setup_environment() {
    # 로그 디렉토리 생성
    export LOG_DIR="$SCRIPT_DIR/logs"
    mkdir -p "$LOG_DIR"
    export LOG_FILE="$LOG_DIR/k8s-setup-$(date '+%Y%m%d_%H%M%S').log"
    
    # OS 감지
    detect_os
    
    # 환경 정보 출력
    log_info "🚀 Kubernetes 프로덕션 환경 설정 시작"
    log_info "클러스터 이름: $CLUSTER_NAME"
    log_info "도메인: $DOMAIN"
    log_info "ArgoCD 버전: $ARGOCD_VERSION"
    log_info "OS: $OS"
    [[ "$DRY_RUN" == "true" ]] && log_warning "DRY RUN 모드 활성화"
    [[ "$VERBOSE" == "true" ]] && log_info "로그 파일: $LOG_FILE"
}

# 확인 프롬프트
confirm_action() {
    local message=$1
    local auto_confirm=${2:-false}
    
    if [[ "$auto_confirm" == "true" || "$DRY_RUN" == "true" ]]; then
        return 0
    fi
    
    echo -e "${YELLOW}$message (y/N):${NC} "
    read -r response
    case "$response" in
        [yY][eE][sS]|[yY])
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# 버전 비교
version_compare() {
    local version1=$1
    local version2=$2
    
    if [[ "$version1" == "$version2" ]]; then
        return 0
    fi
    
    local IFS=.
    local i ver1=($version1) ver2=($version2)
    
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++)); do
        ver1[i]=0
    done
    
    for ((i=0; i<${#ver1[@]}; i++)); do
        if [[ -z ${ver2[i]} ]]; then
            ver2[i]=0
        fi
        if ((10#${ver1[i]} > 10#${ver2[i]})); then
            return 1
        fi
        if ((10#${ver1[i]} < 10#${ver2[i]})); then
            return 2
        fi
    done
    return 0
}
