#!/bin/bash

# 클러스터 설정 스크립트
# 작성일: 2025년 8월 3일

# 네임스페이스 생성
create_namespaces() {
    log_info "네임스페이스 생성 중..."
    
    local namespaces=(
        "$PRODUCTION_NAMESPACE:production"
        "$STAGING_NAMESPACE:staging" 
        "$ARGOCD_NAMESPACE:system"
        "$MONITORING_NAMESPACE:system"
        "$INGRESS_NAMESPACE:system"
        "$CERT_MANAGER_NAMESPACE:system"
    )
    
    for ns_info in "${namespaces[@]}"; do
        local ns_name=${ns_info%%:*}
        local ns_type=${ns_info##*:}
        
        if namespace_exists "$ns_name"; then
            log_info "네임스페이스 $ns_name이 이미 존재합니다."
            continue
        fi
        
        if [[ "$DRY_RUN" == "true" ]]; then
            log_info "[DRY RUN] 네임스페이스 생성: $ns_name"
            continue
        fi
        
        kubectl create namespace "$ns_name"
        
        # 라벨 추가
        kubectl label namespace "$ns_name" \
            environment="$ns_type" \
            managed-by=k8s-manager \
            --overwrite
            
        if [[ "$ns_type" == "production" ]]; then
            kubectl label namespace "$ns_name" \
                security.level=restricted \
                --overwrite
        fi
        
        log_success "네임스페이스 $ns_name 생성 완료"
    done
}

# RBAC 설정
setup_rbac() {
    log_info "RBAC 설정 중..."
    
    local rbac_manifest="$MANIFESTS_DIR/rbac.yaml"
    
    cat > "$rbac_manifest" << 'EOF'
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: production-deployer
  namespace: production
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: production
  name: production-deployer
rules:
- apiGroups: [""]
  resources: ["pods", "services", "configmaps", "secrets"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
- apiGroups: ["apps"]
  resources: ["deployments", "replicasets"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
- apiGroups: ["networking.k8s.io"]
  resources: ["ingresses"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: production-deployer
  namespace: production
subjects:
- kind: ServiceAccount
  name: production-deployer
  namespace: production
roleRef:
  kind: Role
  name: production-deployer
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: monitoring-reader
rules:
- apiGroups: [""]
  resources: ["nodes", "nodes/proxy", "services", "endpoints", "pods"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["extensions"]
  resources: ["ingresses"]
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: monitoring-reader
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: monitoring-reader
subjects:
- kind: ServiceAccount
  name: prometheus
  namespace: monitoring
EOF
    
    apply_manifest "$rbac_manifest"
    log_success "RBAC 설정 완료"
}

# 리소스 쿼터 설정
setup_resource_quotas() {
    log_info "리소스 쿼터 설정 중..."
    
    local quota_manifest="$MANIFESTS_DIR/resource-quotas.yaml"
    
    cat > "$quota_manifest" << EOF
---
apiVersion: v1
kind: ResourceQuota
metadata:
  name: production-quota
  namespace: $PRODUCTION_NAMESPACE
spec:
  hard:
    requests.cpu: "${PROD_CPU_LIMIT}"
    requests.memory: ${PROD_MEMORY_LIMIT}
    limits.cpu: "$((PROD_CPU_LIMIT * 2))"
    limits.memory: $((${PROD_MEMORY_LIMIT%Gi} * 2))Gi
    persistentvolumeclaims: "20"
    services: "20"
    secrets: "100"
    configmaps: "100"
---
apiVersion: v1
kind: LimitRange
metadata:
  name: production-limits
  namespace: $PRODUCTION_NAMESPACE
spec:
  limits:
  - default:
      cpu: 500m
      memory: 512Mi
    defaultRequest:
      cpu: 100m
      memory: 128Mi
    type: Container
  - max:
      cpu: 2
      memory: 4Gi
    min:
      cpu: 50m
      memory: 64Mi
    type: Container
---
apiVersion: v1
kind: ResourceQuota
metadata:
  name: staging-quota
  namespace: $STAGING_NAMESPACE
spec:
  hard:
    requests.cpu: "${STAGING_CPU_LIMIT}"
    requests.memory: ${STAGING_MEMORY_LIMIT}
    limits.cpu: "$((STAGING_CPU_LIMIT * 2))"
    limits.memory: $((${STAGING_MEMORY_LIMIT%Gi} * 2))Gi
    persistentvolumeclaims: "10"
    services: "10"
    secrets: "50"
    configmaps: "50"
---
apiVersion: v1
kind: LimitRange
metadata:
  name: staging-limits
  namespace: $STAGING_NAMESPACE
spec:
  limits:
  - default:
      cpu: 200m
      memory: 256Mi
    defaultRequest:
      cpu: 50m
      memory: 64Mi
    type: Container
  - max:
      cpu: 1
      memory: 2Gi
    min:
      cpu: 25m
      memory: 32Mi
    type: Container
EOF
    
    apply_manifest "$quota_manifest"
    log_success "리소스 쿼터 설정 완료"
}

# Pod Security Standards 설정
setup_pod_security() {
    log_info "Pod Security Standards 설정 중..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Pod Security Standards 설정 스킵"
        return 0
    fi
    
    # 프로덕션 네임스페이스에 restricted 정책 적용
    kubectl label namespace "$PRODUCTION_NAMESPACE" \
        pod-security.kubernetes.io/enforce=restricted \
        pod-security.kubernetes.io/audit=restricted \
        pod-security.kubernetes.io/warn=restricted \
        --overwrite
    
    # 스테이징 네임스페이스에 baseline 정책 적용
    kubectl label namespace "$STAGING_NAMESPACE" \
        pod-security.kubernetes.io/enforce=baseline \
        pod-security.kubernetes.io/audit=baseline \
        pod-security.kubernetes.io/warn=baseline \
        --overwrite
    
    log_success "Pod Security Standards 설정 완료"
}

# 메인 클러스터 설정 함수
setup_cluster_environment() {
    log_info "🏗️ 클러스터 환경 설정 시작"
    
    # kubectl 연결 확인
    if ! check_kubectl_connection; then
        log_error "Kubernetes 클러스터에 연결할 수 없습니다."
        return 1
    fi
    
    # 단계별 설정
    local steps=(
        "create_namespaces:네임스페이스 생성"
        "setup_rbac:RBAC 설정"
        "setup_resource_quotas:리소스 쿼터 설정"
        "setup_pod_security:Pod Security 설정"
    )
    
    local total=${#steps[@]}
    local current=0
    
    for step_info in "${steps[@]}"; do
        ((current++))
        local step_func=${step_info%%:*}
        local step_desc=${step_info##*:}
        
        show_progress $current $total "$step_desc"
        
        if ! $step_func; then
            log_error "$step_desc 실패"
            return 1
        fi
    done
    
    log_success "✅ 클러스터 환경 설정 완료"
    
    # 설정 확인
    log_info "📋 생성된 리소스 확인:"
    if [[ "$DRY_RUN" != "true" ]]; then
        log_info "  네임스페이스: $(kubectl get namespaces --no-headers | wc -l)개"
        log_info "  리소스 쿼터: $(kubectl get resourcequota --all-namespaces --no-headers | wc -l)개"
        log_info "  서비스 계정: $(kubectl get serviceaccounts --all-namespaces --no-headers | wc -l)개"
    fi
}
