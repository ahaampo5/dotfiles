#!/bin/bash

# 개발환경 설정 스크립트
# 작성일: 2025년 8월 3일

# 개발환경 전용 함수들
setup_dev_cluster() {
    log_info "🔧 개발용 로컬 클러스터 설정 중..."
    
    # Kind 클러스터 생성 (로컬 개발용)
    if ! kind get clusters | grep -q "dev-cluster"; then
        log_info "Kind 클러스터 생성 중..."
        
        cat > /tmp/kind-config.yaml << EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: dev-cluster
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 8080
    protocol: TCP
  - containerPort: 443
    hostPort: 8443
    protocol: TCP
- role: worker
EOF
        
        if [[ "$DRY_RUN" != "true" ]]; then
            kind create cluster --config=/tmp/kind-config.yaml
            rm /tmp/kind-config.yaml
        fi
        
        log_success "Kind 클러스터 생성 완료"
    else
        log_info "Kind 클러스터가 이미 존재합니다."
    fi
}

setup_dev_namespaces() {
    log_info "개발용 네임스페이스 생성 중..."
    
    local dev_namespaces=(
        "development:개발"
        "testing:테스트"
        "preview:프리뷰"
        "tools:개발도구"
    )
    
    for ns_info in "${dev_namespaces[@]}"; do
        local ns_name=${ns_info%%:*}
        local ns_desc=${ns_info##*:}
        
        if namespace_exists "$ns_name"; then
            log_info "네임스페이스 $ns_name이 이미 존재합니다."
            continue
        fi
        
        if [[ "$DRY_RUN" != "true" ]]; then
            kubectl create namespace "$ns_name"
            kubectl label namespace "$ns_name" \
                environment=development \
                purpose="$ns_desc" \
                managed-by=dev-k8s-manager \
                --overwrite
        fi
        
        log_success "네임스페이스 $ns_name 생성 완료"
    done
}

install_dev_tools() {
    log_info "🛠️ 개발용 도구 설치 중..."
    
    # Ingress NGINX (개발용)
    if ! resource_exists "deployment" "ingress-nginx-controller" "ingress-nginx"; then
        log_info "Ingress NGINX 설치 중..."
        if [[ "$DRY_RUN" != "true" ]]; then
            kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
            wait_for_resource "deployment" "ingress-nginx-controller" "ingress-nginx" "available" 300
        fi
        log_success "Ingress NGINX 설치 완료"
    fi
    
    # MetalLB (로드밸런서)
    if ! namespace_exists "metallb-system"; then
        log_info "MetalLB 설치 중..."
        if [[ "$DRY_RUN" != "true" ]]; then
            kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.12/config/manifests/metallb-native.yaml
            
            # IP 풀 설정
            cat << EOF | kubectl apply -f -
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: dev-pool
  namespace: metallb-system
spec:
  addresses:
  - 172.18.255.200-172.18.255.250
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: dev-advertisement
  namespace: metallb-system
spec:
  ipAddressPools:
  - dev-pool
EOF
        fi
        log_success "MetalLB 설치 완료"
    fi
}

setup_dev_monitoring() {
    log_info "📊 개발용 모니터링 설정 중..."
    
    # 간단한 Prometheus 설치
    if ! namespace_exists "monitoring"; then
        kubectl create namespace monitoring
    fi
    
    # Prometheus (개발용 간단 버전)
    cat > /tmp/prometheus-dev.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: prometheus
  namespace: monitoring
spec:
  replicas: 1
  selector:
    matchLabels:
      app: prometheus
  template:
    metadata:
      labels:
        app: prometheus
    spec:
      containers:
      - name: prometheus
        image: prom/prometheus:latest
        ports:
        - containerPort: 9090
        volumeMounts:
        - name: config
          mountPath: /etc/prometheus
      volumes:
      - name: config
        configMap:
          name: prometheus-config
---
apiVersion: v1
kind: Service
metadata:
  name: prometheus
  namespace: monitoring
spec:
  selector:
    app: prometheus
  ports:
  - port: 9090
    targetPort: 9090
  type: NodePort
EOF
    
    if [[ "$DRY_RUN" != "true" ]]; then
        kubectl apply -f /tmp/prometheus-dev.yaml
        rm /tmp/prometheus-dev.yaml
    fi
    
    log_success "개발용 모니터링 설정 완료"
}

setup_dev_database() {
    log_info "🗄️ 개발용 데이터베이스 설정 중..."
    
    # PostgreSQL (개발용)
    cat > /tmp/postgres-dev.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres
  namespace: development
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:15-alpine
        env:
        - name: POSTGRES_DB
          value: devdb
        - name: POSTGRES_USER
          value: dev
        - name: POSTGRES_PASSWORD
          value: devpass
        ports:
        - containerPort: 5432
        volumeMounts:
        - name: postgres-data
          mountPath: /var/lib/postgresql/data
      volumes:
      - name: postgres-data
        emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: postgres
  namespace: development
spec:
  selector:
    app: postgres
  ports:
  - port: 5432
    targetPort: 5432
  type: ClusterIP
EOF
    
    if [[ "$DRY_RUN" != "true" ]]; then
        kubectl apply -f /tmp/postgres-dev.yaml
        rm /tmp/postgres-dev.yaml
    fi
    
    log_success "개발용 데이터베이스 설정 완료"
}

# 개발환경 전체 설정
setup_dev_environment() {
    log_info "🚀 개발환경 전체 설정 시작"
    
    # 환경 설정 로드
    source "$SCRIPT_DIR/environments/development/config.sh"
    
    local steps=(
        "setup_dev_cluster:로컬 클러스터 생성"
        "setup_dev_namespaces:네임스페이스 생성"
        "install_dev_tools:개발 도구 설치"
        "setup_dev_monitoring:모니터링 설정"
        "setup_dev_database:데이터베이스 설정"
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
    
    log_success "✅ 개발환경 설정 완료"
    
    # 접속 정보 출력
    echo ""
    echo "🎯 개발환경 접속 정보:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  🌐 Kubernetes Dashboard: http://localhost:8080"
    echo "  📊 Prometheus: http://localhost:9090"
    echo "  🗄️ PostgreSQL: localhost:5432 (dev/devpass)"
    echo "  ⚡ Redis: localhost:6379"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "💡 개발 팁:"
    echo "  kubectl config use-context kind-dev-cluster"
    echo "  kubectl get pods --all-namespaces"
    echo "  k9s  # 클러스터 모니터링"
}
