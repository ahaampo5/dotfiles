#!/bin/bash

# Kubernetes 프로덕션 환경 설정 - 메인 스크립트
# 작성일: 2025년 8월 3일

# 기본 설정
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/config"
SCRIPTS_DIR="$SCRIPT_DIR/scripts"
MANIFESTS_DIR="$SCRIPT_DIR/manifests"

# 기본 변수 설정
DOMAIN="${DOMAIN:-example.com}"
CLUSTER_NAME="${CLUSTER_NAME:-production}"
DRY_RUN="${DRY_RUN:-false}"
VERBOSE="${VERBOSE:-false}"

# 설정 파일 로드
if [[ -f "$CONFIG_DIR/config.sh" ]]; then
    source "$CONFIG_DIR/config.sh"
fi

if [[ -f "$SCRIPTS_DIR/utils.sh" ]]; then
    source "$SCRIPTS_DIR/utils.sh"
fi

# 도움말
show_help() {
    cat << EOF
Kubernetes 프로덕션 환경 설정 도구

사용법: $0 [명령] [옵션]

명령:
  install-tools     핵심 도구 설치 (kubectl, helm, terraform, argocd)
  setup-cluster     클러스터 설정 (네임스페이스, RBAC, 보안 정책)
  setup-argocd      ArgoCD 설치 및 설정
  setup-security    보안 정책 설정
  setup-monitoring  모니터링 스택 설치
  create-pipeline   CI/CD 파이프라인 생성
  cleanup           리소스 정리
  status            설치 상태 확인

옵션:
  --domain DOMAIN   도메인 설정 (기본값: example.com)
  --dry-run         실제 실행 없이 명령만 출력
  --verbose         상세 로그 출력
  --help, -h        도움말 표시

환경 변수:
  DOMAIN           사용할 도메인
  CLUSTER_NAME     클러스터 이름 (기본값: production)
  ARGOCD_VERSION   ArgoCD 버전 (기본값: v2.8.4)

예시:
  $0 install-tools --domain=mycompany.com
  $0 setup-cluster --dry-run
  $0 setup-argocd --verbose
EOF
}

# 메인 함수
main() {
    # 옵션 파싱
    while [[ $# -gt 0 ]]; do
        case $1 in
            --domain)
                DOMAIN="$2"
                shift 2
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --verbose)
                VERBOSE=true
                shift
                ;;
            --help|-h|help)
                show_help
                exit 0
                ;;
            install-tools)
                COMMAND="install-tools"
                shift
                ;;
            setup-cluster)
                COMMAND="setup-cluster"
                shift
                ;;
            setup-argocd)
                COMMAND="setup-argocd"
                shift
                ;;
            setup-security)
                COMMAND="setup-security"
                shift
                ;;
            setup-monitoring)
                COMMAND="setup-monitoring"
                shift
                ;;
            create-pipeline)
                COMMAND="create-pipeline"
                shift
                ;;
            cleanup)
                COMMAND="cleanup"
                shift
                ;;
            status)
                COMMAND="status"
                shift
                ;;
            *)
                log_error "알 수 없는 옵션: $1"
                show_help
                exit 1
                ;;
        esac
    done

    # 기본 설정
    setup_environment
    
    # 명령 실행
    case "$COMMAND" in
        install-tools)
            source "$SCRIPTS_DIR/install-tools.sh"
            install_core_tools
            ;;
        setup-cluster)
            source "$SCRIPTS_DIR/setup-cluster.sh"
            setup_cluster_environment
            ;;
        setup-argocd)
            source "$SCRIPTS_DIR/setup-argocd.sh"
            setup_production_argocd
            ;;
        setup-security)
            source "$SCRIPTS_DIR/setup-security.sh"
            setup_security_policies
            ;;
        setup-monitoring)
            source "$SCRIPTS_DIR/setup-monitoring.sh"
            setup_monitoring_stack
            ;;
        create-pipeline)
            source "$SCRIPTS_DIR/create-pipeline.sh"
            create_production_pipeline
            ;;
        cleanup)
            source "$SCRIPTS_DIR/cleanup.sh"
            cleanup_environment
            ;;
        status)
            source "$SCRIPTS_DIR/status.sh"
            check_installation_status
            ;;
        help|--help|-h)
            show_help
            exit 0
            ;;
        "")
            log_error "명령을 지정해주세요."
            show_help
            exit 1
            ;;
        *)
            log_error "알 수 없는 명령: $COMMAND"
            show_help
            exit 1
            ;;
    esac
}

# 스크립트 실행
main "$@"
