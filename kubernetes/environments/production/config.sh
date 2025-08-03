#!/bin/bash

# 프로덕션환경 전용 설정
# 작성일: 2025년 8월 3일

# 프로덕션 기본 설정
ENVIRONMENT="production"
CLUSTER_NAME="${CLUSTER_NAME:-prod-cluster}"
DOMAIN="${DOMAIN:-yourdomain.com}"

# 강화된 보안 설정
POD_SECURITY_STANDARD="restricted"     # 엄격한 보안
ENABLE_NETWORK_POLICIES="true"         # 네트워크 격리
ENABLE_STRICT_RBAC="true"              # 엄격한 권한 관리
ENABLE_OPA_GATEKEEPER="true"           # 정책 엔진
ENABLE_ADMISSION_CONTROLLERS="true"     # 입학 제어기

# 고가용성 설정
CLUSTER_HA_MODE="true"                 # 고가용성 모드
MIN_REPLICAS="3"                       # 최소 복제본 수
MULTI_AZ_DEPLOYMENT="true"             # 다중 가용 영역
ENABLE_AUTO_SCALING="true"             # 자동 스케일링

# 리소스 설정 (프로덕션 규모)
PROD_CPU_LIMIT="500"                   # 500 CPU 코어
PROD_MEMORY_LIMIT="1000Gi"             # 1TB 메모리
PROD_STORAGE_LIMIT="10Ti"              # 10TB 스토리지

# 프로덕션 네임스페이스
PROD_NAMESPACE="production"
STAGING_NAMESPACE="staging"
MONITORING_NAMESPACE="monitoring"
SECURITY_NAMESPACE="security"
INGRESS_NAMESPACE="ingress-nginx"
CERT_MANAGER_NAMESPACE="cert-manager"

# 보안 도구들
ENABLE_FALCO="true"                    # 런타임 보안
ENABLE_TRIVY="true"                    # 취약점 스캔
ENABLE_VAULT="true"                    # 시크릿 관리
ENABLE_CERT_MANAGER="true"             # 인증서 자동 관리

# 모니터링 (완전한 스택)
ENABLE_PROMETHEUS="true"               # 메트릭 수집
ENABLE_GRAFANA="true"                  # 대시보드
ENABLE_ALERTMANAGER="true"             # 알림 관리
ENABLE_JAEGER="true"                   # 분산 트레이싱
ENABLE_ELK_STACK="true"                # 로그 관리

# 백업 및 재해복구
ENABLE_VELERO="true"                   # 클러스터 백업
BACKUP_SCHEDULE="0 2 * * *"            # 매일 새벽 2시 백업
BACKUP_RETENTION="30d"                 # 30일 보관

# CI/CD (GitOps)
ENABLE_ARGOCD="true"                   # GitOps 배포
ENABLE_TEKTON="false"                  # CI 파이프라인 (선택)
AUTO_DEPLOY="false"                    # 수동 승인 필요
ENABLE_CANARY_DEPLOYMENT="true"        # 카나리 배포

# 네트워크 설정
ENABLE_ISTIO="true"                    # 서비스 메시
ENABLE_INGRESS_NGINX="true"            # 인그레스 컨트롤러
ENABLE_EXTERNAL_DNS="true"             # DNS 자동 관리
ENABLE_CERT_MANAGER="true"             # TLS 인증서 자동 관리

# 데이터베이스 (관리형 서비스)
USE_MANAGED_DB="true"                  # AWS RDS, GCP CloudSQL 등
USE_MANAGED_REDIS="true"               # AWS ElastiCache 등
ENABLE_DB_BACKUP="true"                # 데이터베이스 백업

# 성능 및 안정성
ENABLE_HPA="true"                      # 수평 파드 자동 스케일링
ENABLE_VPA="true"                      # 수직 파드 자동 스케일링
ENABLE_PDB="true"                      # 파드 중단 예산
ENABLE_RESOURCE_QUOTAS="true"          # 리소스 할당량

# 컴플라이언스
ENABLE_AUDIT_LOGGING="true"            # 감사 로깅
ENABLE_POLICY_ENFORCEMENT="true"       # 정책 강제 적용
GDPR_COMPLIANCE="true"                 # GDPR 준수
SOC2_COMPLIANCE="true"                 # SOC2 준수
