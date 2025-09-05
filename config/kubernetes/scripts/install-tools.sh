#!/bin/bash

# 핵심 도구 설치 스크립트
# 작성일: 2025년 8월 3일

# 패키지 매니저별 설치
install_homebrew() {
    if [[ "$OS" == "macos" ]]; then
        if ! command_exists brew; then
            log_info "Homebrew 설치 중..."
            if [[ "$DRY_RUN" == "true" ]]; then
                log_info "[DRY RUN] Homebrew 설치 스킵"
                return 0
            fi
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            eval "$(/opt/homebrew/bin/brew shellenv)"
            log_success "Homebrew 설치 완료"
        else
            log_info "Homebrew가 이미 설치되어 있습니다."
            [[ "$DRY_RUN" != "true" ]] && brew update
        fi
    fi
}

install_package_manager() {
    case "$OS" in
        "macos")
            install_homebrew
            ;;
        "ubuntu")
            log_info "패키지 목록 업데이트 중..."
            [[ "$DRY_RUN" != "true" ]] && sudo apt-get update
            [[ "$DRY_RUN" != "true" ]] && sudo apt-get install -y curl wget gnupg software-properties-common apt-transport-https ca-certificates
            ;;
        "windows")
            if ! command_exists choco; then
                log_warning "Chocolatey가 설치되지 않았습니다."
                log_warning "PowerShell 관리자 권한으로 실행하여 Chocolatey를 설치하세요."
                return 1
            fi
            ;;
        *)
            log_error "지원하지 않는 운영체제입니다: $OS"
            return 1
            ;;
    esac
}

# kubectl 설치
install_kubectl() {
    if command_exists kubectl; then
        local current_version
        current_version=$(kubectl version --client --output=yaml 2>/dev/null | grep gitVersion | cut -d'"' -f4)
        log_info "kubectl이 이미 설치되어 있습니다. 버전: $current_version"
        return 0
    fi
    
    log_info "kubectl 설치 중..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] kubectl 설치 스킵"
        return 0
    fi
    
    case "$OS" in
        "macos")
            brew install kubectl
            ;;
        "ubuntu")
            curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
            sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
            rm kubectl
            ;;
        "windows")
            choco install -y kubernetes-cli
            ;;
    esac
    
    log_success "kubectl 설치 완료"
}

# Helm 설치
install_helm() {
    if command_exists helm; then
        local current_version
        current_version=$(helm version --short 2>/dev/null | cut -d'+' -f1)
        log_info "Helm이 이미 설치되어 있습니다. 버전: $current_version"
        return 0
    fi
    
    log_info "Helm 설치 중..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Helm 설치 스킵"
        return 0
    fi
    
    case "$OS" in
        "macos")
            brew install helm
            ;;
        "ubuntu")
            curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
            sudo apt-get update
            sudo apt-get install -y helm
            ;;
        "windows")
            choco install -y kubernetes-helm
            ;;
    esac
    
    log_success "Helm 설치 완료"
}

# Terraform 설치
install_terraform() {
    if command_exists terraform; then
        local current_version
        current_version=$(terraform version -json 2>/dev/null | grep terraform_version | cut -d'"' -f4)
        log_info "Terraform이 이미 설치되어 있습니다. 버전: $current_version"
        return 0
    fi
    
    log_info "Terraform 설치 중..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Terraform 설치 스킵"
        return 0
    fi
    
    case "$OS" in
        "macos")
            brew install terraform
            ;;
        "ubuntu")
            wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
            echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
            sudo apt-get update && sudo apt-get install -y terraform
            ;;
        "windows")
            choco install -y terraform
            ;;
    esac
    
    log_success "Terraform 설치 완료"
}

# ArgoCD CLI 설치
install_argocd_cli() {
    if command_exists argocd; then
        local current_version
        current_version=$(argocd version --client --grpc-web 2>/dev/null | grep client | cut -d':' -f2 | tr -d ' ')
        log_info "ArgoCD CLI가 이미 설치되어 있습니다. 버전: $current_version"
        return 0
    fi
    
    log_info "ArgoCD CLI 설치 중..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] ArgoCD CLI 설치 스킵"
        return 0
    fi
    
    case "$OS" in
        "macos")
            brew install argocd
            ;;
        "ubuntu")
            VERSION=$(curl --silent "https://api.github.com/repos/argoproj/argo-cd/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
            curl -sSL -o argocd https://github.com/argoproj/argo-cd/releases/download/$VERSION/argocd-linux-amd64
            chmod +x argocd
            sudo mv argocd /usr/local/bin/argocd
            ;;
        "windows")
            choco install -y argocd-cli
            ;;
    esac
    
    log_success "ArgoCD CLI 설치 완료"
}

# 추가 도구들 설치
install_additional_tools() {
    local tools=("kustomize" "yq" "jq")
    local total=${#tools[@]}
    local current=0
    
    for tool in "${tools[@]}"; do
        ((current++))
        show_progress $current $total "설치 중: $tool"
        
        if command_exists "$tool"; then
            log_debug "$tool이 이미 설치되어 있습니다."
            continue
        fi
        
        if [[ "$DRY_RUN" == "true" ]]; then
            log_debug "[DRY RUN] $tool 설치 스킵"
            continue
        fi
        
        case "$OS" in
            "macos")
                brew install "$tool"
                ;;
            "ubuntu")
                case "$tool" in
                    "kustomize")
                        curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash
                        sudo mv kustomize /usr/local/bin/
                        ;;
                    "yq")
                        sudo snap install yq
                        ;;
                    "jq")
                        sudo apt-get install -y jq
                        ;;
                esac
                ;;
            "windows")
                case "$tool" in
                    "kustomize")
                        choco install -y kustomize
                        ;;
                    "yq")
                        choco install -y yq
                        ;;
                    "jq")
                        choco install -y jq
                        ;;
                esac
                ;;
        esac
    done
    
    log_success "추가 도구 설치 완료"
}

# 메인 설치 함수
install_core_tools() {
    log_info "🔧 핵심 도구 설치 시작"
    
    # 패키지 매니저 설치
    install_package_manager || { log_error "패키지 매니저 설치 실패"; return 1; }
    
    # 핵심 도구들 설치
    local tools=(
        "kubectl:install_kubectl"
        "helm:install_helm" 
        "terraform:install_terraform"
        "argocd:install_argocd_cli"
    )
    
    local total=${#tools[@]}
    local current=0
    
    for tool_info in "${tools[@]}"; do
        ((current++))
        local tool_name=${tool_info%%:*}
        local install_func=${tool_info##*:}
        
        show_progress $current $total "설치 중: $tool_name"
        
        if ! $install_func; then
            log_error "$tool_name 설치 실패"
            return 1
        fi
    done
    
    # 추가 도구들 설치
    install_additional_tools
    
    log_success "✅ 모든 핵심 도구 설치 완료"
    
    # 설치 확인
    log_info "📋 설치된 도구 버전 확인:"
    command_exists kubectl && log_info "  kubectl: $(kubectl version --client --short 2>/dev/null || echo '설치됨')"
    command_exists helm && log_info "  helm: $(helm version --short 2>/dev/null || echo '설치됨')"
    command_exists terraform && log_info "  terraform: $(terraform version -json 2>/dev/null | jq -r .terraform_version 2>/dev/null || echo '설치됨')"
    command_exists argocd && log_info "  argocd: $(argocd version --client --grpc-web 2>/dev/null | grep client | cut -d':' -f2 | tr -d ' ' || echo '설치됨')"
}
