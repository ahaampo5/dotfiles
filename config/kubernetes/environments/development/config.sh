#!/bin/bash

# 개발환경 전용 설정
# 작성일: 2025년 8월 3일

# 개발환경 기본 설정
ENVIRONMENT="development"
CLUSTER_NAME="${CLUSTER_NAME:-dev-cluster}"
DOMAIN="${DOMAIN:-dev.local}"

# 개발용 클러스터 설정 (느슨한 보안)
POD_SECURITY_STANDARD="privileged"  # 개발 편의성 우선
ENABLE_NETWORK_POLICIES="false"     # 네트워크 제한 없음
ENABLE_STRICT_RBAC="false"          # 느슨한 권한

# 리소스 제한 (로컬 환경 고려)
DEV_CPU_LIMIT="4"                   # 로컬 머신 기준
DEV_MEMORY_LIMIT="8Gi"              
DEV_STORAGE_LIMIT="20Gi"

# 개발용 네임스페이스
DEV_NAMESPACE="development"
TEST_NAMESPACE="testing"
PREVIEW_NAMESPACE="preview"

# 개발 도구들
ENABLE_DEBUG_TOOLS="true"           # k9s, stern 등 디버깅 도구
ENABLE_HOT_RELOAD="true"            # 실시간 코드 반영
ENABLE_PORT_FORWARD="true"          # 로컬 포트 포워딩

# 모니터링 (간단한 버전)
MONITORING_LITE="true"              # 가벼운 모니터링
LOG_LEVEL="debug"                   # 상세한 로그

# 데이터베이스 (로컬 테스트용)
USE_LOCAL_DB="true"                 # 로컬 PostgreSQL, Redis
PERSISTENT_VOLUMES="false"          # 임시 데이터

# CI/CD (간단한 버전)
ENABLE_GITOPS="false"               # 수동 배포
AUTO_DEPLOY="true"                  # 코드 변경시 즉시 반영
