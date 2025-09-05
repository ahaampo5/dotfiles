#!/bin/bash

# 프로덕션환경 배포 스크립트
# 작성일: 2025년 8월 3일

# 프로덕션 배포 전 검증
validate_production_readiness() {
    log_info "🔍 프로덕션 배포 준비 상태 검증 중..."
    
    local validation_errors=()
    
    # 필수 환경변수 확인
    local required_vars=(
        "DOMAIN"
        "CLUSTER_NAME"
        "AWS_REGION"
    )
    
    for var in "${required_vars[@]}"; do
        if [[ -z "${!var}" ]]; then
            validation_errors+=("환경변수 $var가 설정되지 않았습니다.")
        fi
    done
    
    # 클러스터 연결 확인
    if ! kubectl cluster-info >/dev/null 2>&1; then
        validation_errors+=("Kubernetes 클러스터에 연결할 수 없습니다.")
    fi
    
    # 노드 상태 확인
    local ready_nodes=$(kubectl get nodes --no-headers | grep " Ready " | wc -l)
    if [[ "$ready_nodes" -lt 3 ]]; then
        validation_errors+=("Ready 상태의 노드가 3개 미만입니다. (현재: $ready_nodes)")
    fi
    
    # 보안 정책 확인
    if [[ "$ENABLE_NETWORK_POLICIES" != "true" ]]; then
        validation_errors+=("네트워크 정책이 비활성화되어 있습니다.")
    fi
    
    if [[ ${#validation_errors[@]} -gt 0 ]]; then
        log_error "프로덕션 배포 준비 상태 검증 실패:"
        for error in "${validation_errors[@]}"; do
            log_error "  - $error"
        done
        return 1
    fi
    
    log_success "프로덕션 배포 준비 상태 검증 완료"
    return 0
}

setup_production_namespaces() {
    log_info "프로덕션 네임스페이스 설정 중..."
    
    local prod_namespaces=(
        "production:프로덕션:restricted"
        "staging:스테이징:baseline"
        "monitoring:모니터링:privileged"
        "security:보안:restricted"
        "ingress-nginx:인그레스:privileged"
        "cert-manager:인증서관리:restricted"
        "argocd:GitOps:restricted"
        "velero:백업:privileged"
    )
    
    for ns_info in "${prod_namespaces[@]}"; do
        local ns_name=$(echo "$ns_info" | cut -d':' -f1)
        local ns_desc=$(echo "$ns_info" | cut -d':' -f2)
        local security_level=$(echo "$ns_info" | cut -d':' -f3)
        
        if namespace_exists "$ns_name"; then
            log_info "네임스페이스 $ns_name이 이미 존재합니다."
            continue
        fi
        
        if [[ "$DRY_RUN" != "true" ]]; then
            kubectl create namespace "$ns_name"
            
            # 라벨 설정
            kubectl label namespace "$ns_name" \
                environment=production \
                purpose="$ns_desc" \
                managed-by=prod-k8s-manager \
                security.level="$security_level" \
                --overwrite
            
            # Pod Security Standards 적용
            kubectl label namespace "$ns_name" \
                pod-security.kubernetes.io/enforce="$security_level" \
                pod-security.kubernetes.io/audit="$security_level" \
                pod-security.kubernetes.io/warn="$security_level" \
                --overwrite
        fi
        
        log_success "네임스페이스 $ns_name 생성 완료 (보안수준: $security_level)"
    done
}

deploy_security_stack() {
    log_info "🔒 보안 스택 배포 중..."
    
    # OPA Gatekeeper
    if [[ "$ENABLE_OPA_GATEKEEPER" == "true" ]]; then
        log_info "OPA Gatekeeper 설치 중..."
        if [[ "$DRY_RUN" != "true" ]]; then
            kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/release-3.14/deploy/gatekeeper.yaml
            wait_for_resource "deployment" "gatekeeper-controller-manager" "gatekeeper-system" "available" 300
        fi
        log_success "OPA Gatekeeper 설치 완료"
    fi
    
    # Falco (런타임 보안)
    if [[ "$ENABLE_FALCO" == "true" ]]; then
        log_info "Falco 설치 중..."
        if [[ "$DRY_RUN" != "true" ]]; then
            helm repo add falcosecurity https://falcosecurity.github.io/charts
            helm repo update
            helm install falco falcosecurity/falco \
                --namespace security \
                --create-namespace \
                --set falco.grpc.enabled=true \
                --set falco.grpcOutput.enabled=true
        fi
        log_success "Falco 설치 완료"
    fi
}

deploy_monitoring_stack() {
    log_info "📊 모니터링 스택 배포 중..."
    
    # Prometheus Stack
    if [[ "$ENABLE_PROMETHEUS" == "true" ]]; then
        log_info "Prometheus Stack 설치 중..."
        if [[ "$DRY_RUN" != "true" ]]; then
            helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
            helm repo update
            
            # Prometheus 설정
            cat > /tmp/prometheus-values.yaml << EOF
prometheus:
  prometheusSpec:
    retention: 30d
    storageSpec:
      volumeClaimTemplate:
        spec:
          storageClassName: gp3
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 100Gi
    resources:
      requests:
        memory: 2Gi
        cpu: 1000m
      limits:
        memory: 4Gi
        cpu: 2000m

grafana:
  adminPassword: "${GRAFANA_ADMIN_PASSWORD}"
  persistence:
    enabled: true
    storageClassName: gp3
    size: 10Gi
  resources:
    requests:
      memory: 512Mi
      cpu: 250m
    limits:
      memory: 1Gi
      cpu: 500m

alertmanager:
  alertmanagerSpec:
    storage:
      volumeClaimTemplate:
        spec:
          storageClassName: gp3
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 10Gi
EOF
            
            helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
                --namespace monitoring \
                --create-namespace \
                --values /tmp/prometheus-values.yaml
                
            rm /tmp/prometheus-values.yaml
        fi
        log_success "Prometheus Stack 설치 완료"
    fi
}

deploy_backup_solution() {
    log_info "💾 백업 솔루션 배포 중..."
    
    # Velero (클러스터 백업)
    if [[ "$ENABLE_VELERO" == "true" ]]; then
        log_info "Velero 설치 중..."
        if [[ "$DRY_RUN" != "true" ]]; then
            # Velero 설치
            curl -L https://github.com/vmware-tanzu/velero/releases/latest/download/velero-linux-amd64.tar.gz | tar xz
            sudo mv velero-*/velero /usr/local/bin/
            rm -rf velero-*
            
            # AWS S3 백업 설정
            velero install \
                --provider aws \
                --plugins velero/velero-plugin-for-aws:v1.8.0 \
                --bucket "${CLUSTER_NAME}-backup" \
                --secret-file ./credentials-velero \
                --backup-location-config region="${AWS_REGION}" \
                --snapshot-location-config region="${AWS_REGION}"
            
            # 백업 스케줄 설정
            velero schedule create daily-backup \
                --schedule="${BACKUP_SCHEDULE}" \
                --ttl "${BACKUP_RETENTION}"
        fi
        log_success "Velero 설치 완료"
    fi
}

deploy_gitops_stack() {
    log_info "🚀 GitOps 스택 배포 중..."
    
    # ArgoCD (고가용성 모드)
    if [[ "$ENABLE_ARGOCD" == "true" ]]; then
        log_info "ArgoCD HA 설치 중..."
        if [[ "$DRY_RUN" != "true" ]]; then
            kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
            kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/ha/install.yaml
            
            # ArgoCD 설정
            cat > /tmp/argocd-config.yaml << EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-server-config
  namespace: argocd
  labels:
    app.kubernetes.io/name: argocd-server-config
    app.kubernetes.io/part-of: argocd
data:
  url: https://argocd.${DOMAIN}
  policy.default: role:readonly
  policy.csv: |
    p, role:admin, applications, *, */*, allow
    p, role:admin, clusters, *, *, allow
    p, role:admin, repositories, *, *, allow
    g, argocd-admins, role:admin
  oidc.config: |
    name: OIDC
    issuer: https://your-oidc-provider.com
    clientId: argocd
    clientSecret: \$oidc.clientSecret
    requestedScopes: ["openid", "profile", "email"]
    requestedIDTokenClaims: {"groups": {"essential": true}}
EOF
            
            kubectl apply -f /tmp/argocd-config.yaml
            rm /tmp/argocd-config.yaml
            
            wait_for_resource "deployment" "argocd-server" "argocd" "available" 600
        fi
        log_success "ArgoCD 설치 완료"
    fi
}

# 프로덕션 배포 메인 함수
deploy_production() {
    log_info "🏭 프로덕션 환경 배포 시작"
    
    # 환경 설정 로드
    source "$SCRIPT_DIR/environments/production/config.sh"
    
    # 배포 전 검증
    if ! validate_production_readiness; then
        log_error "프로덕션 배포 준비 상태 검증 실패"
        return 1
    fi
    
    # 배포 확인
    if ! confirm_action "프로덕션 환경에 배포하시겠습니까? 이 작업은 되돌릴 수 없습니다."; then
        log_warning "프로덕션 배포가 취소되었습니다."
        return 0
    fi
    
    local steps=(
        "setup_production_namespaces:네임스페이스 설정"
        "deploy_security_stack:보안 스택 배포"
        "deploy_monitoring_stack:모니터링 스택 배포"
        "deploy_backup_solution:백업 솔루션 배포"
        "deploy_gitops_stack:GitOps 스택 배포"
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
    
    log_success "✅ 프로덕션 환경 배포 완료"
    
    # 배포 결과 출력
    echo ""
    echo "🎯 프로덕션 환경 접속 정보:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  🚀 ArgoCD: https://argocd.${DOMAIN}"
    echo "  📊 Grafana: https://grafana.${DOMAIN}"
    echo "  🔍 Prometheus: https://prometheus.${DOMAIN}"
    echo "  🚨 AlertManager: https://alertmanager.${DOMAIN}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "⚠️  보안 주의사항:"
    echo "  1. ArgoCD admin 비밀번호를 즉시 변경하세요"
    echo "  2. OIDC 인증을 설정하세요"
    echo "  3. 네트워크 정책을 검토하세요"
    echo "  4. 백업 상태를 확인하세요"
}
