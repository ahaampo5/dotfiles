#!/bin/bash

# 상태 확인 스크립트
# 작성일: 2025년 8월 3일

# 설치 상태 확인
check_tool_installation() {
    log_info "도구 설치 상태 확인 중..."
    
    local tools=(
        "kubectl:Kubernetes CLI"
        "helm:Helm Package Manager"
        "terraform:Infrastructure as Code"
        "argocd:ArgoCD CLI"
        "docker:Docker"
        "kustomize:Kustomize"
        "yq:YAML Processor"
        "jq:JSON Processor"
    )
    
    local installed=0
    local total=${#tools[@]}
    
    echo ""
    echo "📦 도구 설치 상태:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    for tool_info in "${tools[@]}"; do
        local tool_name=${tool_info%%:*}
        local tool_desc=${tool_info##*:}
        
        if command_exists "$tool_name"; then
            local version=""
            case "$tool_name" in
                "kubectl")
                    version=$(kubectl version --client --short 2>/dev/null | head -1 | cut -d' ' -f3 || echo "설치됨")
                    ;;
                "helm")
                    version=$(helm version --short 2>/dev/null | cut -d'+' -f1 || echo "설치됨")
                    ;;
                "terraform")
                    version=$(terraform version -json 2>/dev/null | jq -r .terraform_version 2>/dev/null || echo "설치됨")
                    ;;
                "docker")
                    version=$(docker --version 2>/dev/null | cut -d' ' -f3 | sed 's/,//' || echo "설치됨")
                    ;;
                *)
                    version="설치됨"
                    ;;
            esac
            
            printf "  ✅ %-15s %s (%s)\n" "$tool_name" "$tool_desc" "$version"
            ((installed++))
        else
            printf "  ❌ %-15s %s\n" "$tool_name" "$tool_desc"
        fi
    done
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "설치된 도구: $installed/$total"
    echo ""
}

# Kubernetes 클러스터 상태 확인
check_cluster_status() {
    log_info "Kubernetes 클러스터 상태 확인 중..."
    
    if ! command_exists kubectl; then
        log_warning "kubectl이 설치되지 않았습니다."
        return 1
    fi
    
    echo ""
    echo "☸️  Kubernetes 클러스터 상태:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # 클러스터 연결 확인
    if kubectl cluster-info >/dev/null 2>&1; then
        local context=$(kubectl config current-context 2>/dev/null || echo "unknown")
        local cluster=$(kubectl config view --minify --output jsonpath='{.clusters[0].name}' 2>/dev/null || echo "unknown")
        
        echo "  ✅ 클러스터 연결: $cluster"
        echo "  ✅ 현재 컨텍스트: $context"
        
        # 노드 상태 확인
        local nodes_ready=$(kubectl get nodes --no-headers 2>/dev/null | grep " Ready " | wc -l || echo "0")
        local nodes_total=$(kubectl get nodes --no-headers 2>/dev/null | wc -l || echo "0")
        echo "  📊 노드 상태: $nodes_ready/$nodes_total Ready"
        
        # 네임스페이스 확인
        local namespaces=(
            "production:프로덕션"
            "staging:스테이징"
            "argocd:ArgoCD"
            "monitoring:모니터링"
            "ingress-nginx:인그레스"
            "cert-manager:인증서 관리"
        )
        
        echo ""
        echo "  📦 네임스페이스 상태:"
        for ns_info in "${namespaces[@]}"; do
            local ns_name=${ns_info%%:*}
            local ns_desc=${ns_info##*:}
            
            if namespace_exists "$ns_name"; then
                local pod_count=$(kubectl get pods -n "$ns_name" --no-headers 2>/dev/null | wc -l || echo "0")
                printf "    ✅ %-15s %s (Pod: %s개)\n" "$ns_name" "$ns_desc" "$pod_count"
            else
                printf "    ❌ %-15s %s\n" "$ns_name" "$ns_desc"
            fi
        done
        
    else
        echo "  ❌ 클러스터에 연결할 수 없습니다."
        echo "  💡 kubeconfig를 확인하거나 클러스터를 시작하세요."
        return 1
    fi
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

# ArgoCD 상태 확인
check_argocd_status() {
    if ! namespace_exists "argocd"; then
        return 0
    fi
    
    log_info "ArgoCD 상태 확인 중..."
    
    echo ""
    echo "🚀 ArgoCD 상태:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # ArgoCD 서버 상태
    if resource_exists "deployment" "argocd-server" "argocd"; then
        local ready_replicas=$(kubectl get deployment argocd-server -n argocd -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
        local desired_replicas=$(kubectl get deployment argocd-server -n argocd -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "0")
        
        if [[ "$ready_replicas" == "$desired_replicas" && "$ready_replicas" != "0" ]]; then
            echo "  ✅ ArgoCD 서버: $ready_replicas/$desired_replicas Ready"
        else
            echo "  ⚠️  ArgoCD 서버: $ready_replicas/$desired_replicas Ready"
        fi
    else
        echo "  ❌ ArgoCD 서버: 설치되지 않음"
    fi
    
    # ArgoCD 애플리케이션 상태
    if command_exists argocd && kubectl get pods -n argocd --no-headers 2>/dev/null | grep -q "argocd-server.*Running"; then
        local app_count=$(kubectl get applications -n argocd --no-headers 2>/dev/null | wc -l || echo "0")
        echo "  📊 ArgoCD 애플리케이션: ${app_count}개"
    fi
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

# 리소스 사용량 확인
check_resource_usage() {
    if ! command_exists kubectl || ! kubectl cluster-info >/dev/null 2>&1; then
        return 0
    fi
    
    log_info "리소스 사용량 확인 중..."
    
    echo ""
    echo "📊 리소스 사용량:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # 노드 리소스 사용량
    if kubectl top nodes >/dev/null 2>&1; then
        echo "  💾 노드 리소스 사용량:"
        kubectl top nodes --no-headers 2>/dev/null | while read -r line; do
            local node_name=$(echo "$line" | awk '{print $1}')
            local cpu_usage=$(echo "$line" | awk '{print $2}')
            local memory_usage=$(echo "$line" | awk '{print $4}')
            printf "    - %-20s CPU: %s, Memory: %s\n" "$node_name" "$cpu_usage" "$memory_usage"
        done
    else
        echo "  ⚠️  노드 리소스 사용량을 확인할 수 없습니다. (metrics-server 필요)"
    fi
    
    # 네임스페이스별 Pod 수
    echo ""
    echo "  📦 네임스페이스별 Pod 수:"
    kubectl get pods --all-namespaces --no-headers 2>/dev/null | \
        awk '{print $1}' | sort | uniq -c | sort -nr | head -10 | \
        while read -r count namespace; do
            printf "    - %-20s %s개\n" "$namespace" "$count"
        done
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

# 보안 설정 확인
check_security_status() {
    if ! command_exists kubectl || ! kubectl cluster-info >/dev/null 2>&1; then
        return 0
    fi
    
    log_info "보안 설정 확인 중..."
    
    echo ""
    echo "🔒 보안 설정 상태:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # RBAC 확인
    local rbac_count=$(kubectl get clusterroles,clusterrolebindings,roles,rolebindings --all-namespaces --no-headers 2>/dev/null | wc -l || echo "0")
    echo "  🔐 RBAC 리소스: ${rbac_count}개"
    
    # 네트워크 정책 확인
    local netpol_count=$(kubectl get networkpolicies --all-namespaces --no-headers 2>/dev/null | wc -l || echo "0")
    echo "  🛡️  네트워크 정책: ${netpol_count}개"
    
    # 리소스 쿼터 확인
    local quota_count=$(kubectl get resourcequotas --all-namespaces --no-headers 2>/dev/null | wc -l || echo "0")
    echo "  📊 리소스 쿼터: ${quota_count}개"
    
    # Pod Security Standards 확인
    local pss_count=$(kubectl get namespaces -o json 2>/dev/null | jq '[.items[] | select(.metadata.labels["pod-security.kubernetes.io/enforce"]) | .metadata.name] | length' 2>/dev/null || echo "0")
    echo "  🔒 Pod Security Standards: ${pss_count}개 네임스페이스"
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

# 전체 상태 요약
print_status_summary() {
    echo ""
    echo "📋 전체 상태 요약:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # 설치 상태
    local kubectl_status="❌"
    local helm_status="❌"
    local cluster_status="❌"
    local argocd_status="❌"
    
    command_exists kubectl && kubectl_status="✅"
    command_exists helm && helm_status="✅"
    kubectl cluster-info >/dev/null 2>&1 && cluster_status="✅"
    namespace_exists "argocd" && resource_exists "deployment" "argocd-server" "argocd" && argocd_status="✅"
    
    echo "  ${kubectl_status} kubectl 설치"
    echo "  ${helm_status} Helm 설치"
    echo "  ${cluster_status} Kubernetes 클러스터 연결"
    echo "  ${argocd_status} ArgoCD 설치"
    
    # 권장 사항
    echo ""
    echo "💡 권장 사항:"
    
    if [[ "$kubectl_status" == "❌" ]]; then
        echo "  🔧 ./k8s-manager.sh install-tools 를 실행하여 도구를 설치하세요"
    fi
    
    if [[ "$cluster_status" == "❌" ]]; then
        echo "  ☸️  Kubernetes 클러스터를 시작하거나 kubeconfig를 설정하세요"
    fi
    
    if [[ "$argocd_status" == "❌" && "$cluster_status" == "✅" ]]; then
        echo "  🚀 ./k8s-manager.sh setup-argocd 를 실행하여 ArgoCD를 설치하세요"
    fi
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# 메인 상태 확인 함수
check_installation_status() {
    log_info "🔍 설치 상태 확인 시작"
    
    check_tool_installation
    check_cluster_status
    check_argocd_status
    check_resource_usage
    check_security_status
    print_status_summary
    
    log_success "✅ 상태 확인 완료"
}
