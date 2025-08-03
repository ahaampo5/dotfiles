# Kubernetes 환경별 관리 Makefile
# 작성일: 2025년 8월 3일

.DEFAULT_GOAL := help
.PHONY: help install setup clean status dev prod

# 변수 설정
ENVIRONMENT ?= development
DOMAIN ?= example.com
CLUSTER_NAME ?= k8s-cluster
DRY_RUN ?= false
VERBOSE ?= false

K8S_MANAGER = ./k8s-manager.sh
LOG_DIR = ./logs

# 색상 정의
GREEN = \033[0;32m
YELLOW = \033[1;33m
RED = \033[0;31m
BLUE = \033[0;34m
NC = \033[0m # No Color

## 도움말 출력
help:
	@echo "$(GREEN)Kubernetes 환경별 관리 도구$(NC)"
	@echo ""
	@echo "$(YELLOW)🏗️ 환경별 명령:$(NC)"
	@echo "  make dev                 - 개발환경 전체 설정"
	@echo "  make dev-setup           - 개발환경 클러스터 설정"
	@echo "  make dev-clean           - 개발환경 정리"
	@echo ""
	@echo "  make prod                - 프로덕션환경 배포"
	@echo "  make prod-validate       - 프로덕션 배포 전 검증"
	@echo "  make prod-backup         - 프로덕션 백업"
	@echo ""
	@echo "$(YELLOW)🔧 공통 명령:$(NC)"
	@echo "  make install             - 핵심 도구 설치"
	@echo "  make status              - 설치 상태 확인"
	@echo "  make clean               - 리소스 정리"
	@echo ""
	@echo "$(YELLOW)🐳 Docker 명령:$(NC)"
	@echo "  make docker-dev          - 개발환경 Docker 실행"
	@echo "  make docker-prod         - 프로덕션환경 Docker 실행"
	@echo ""
	@echo "$(YELLOW)옵션:$(NC)"
	@echo "  ENVIRONMENT=dev|prod     - 환경 설정"
	@echo "  DOMAIN=mydomain.com      - 도메인 설정"
	@echo "  DRY_RUN=true             - 실제 실행 없이 명령만 출력"
	@echo "  VERBOSE=true             - 상세 로그 출력"
	@echo ""
	@echo "$(YELLOW)예시:$(NC)"
	@echo "  make dev DOMAIN=dev.local"
	@echo "  make prod DOMAIN=mycompany.com DRY_RUN=true"
	@echo "  make docker-dev"

## 실행 전 확인
check:
	@echo "$(YELLOW)실행 환경 확인...$(NC)"
	@if [ ! -f "$(K8S_MANAGER)" ]; then \
		echo "$(RED)오류: k8s-manager.sh 파일을 찾을 수 없습니다.$(NC)"; \
		exit 1; \
	fi
	@chmod +x $(K8S_MANAGER)
	@chmod +x scripts/*.sh environments/*/*.sh 2>/dev/null || true
	@mkdir -p $(LOG_DIR)

## 개발환경 전체 설정
dev: check
	@echo "$(GREEN)🛠️ 개발환경 전체 설정 시작...$(NC)"
	@ENVIRONMENT=development DOMAIN=${DOMAIN} DRY_RUN=${DRY_RUN} VERBOSE=${VERBOSE} \
		$(K8S_MANAGER) install-tools
	@echo "$(GREEN)개발용 클러스터 및 도구 설정 중...$(NC)"
	@chmod +x environments/development/setup-dev.sh
	@ENVIRONMENT=development DOMAIN=${DOMAIN} DRY_RUN=${DRY_RUN} VERBOSE=${VERBOSE} \
		./environments/development/setup-dev.sh

## 개발환경 클러스터만 설정
dev-setup: check
	@echo "$(GREEN)🔧 개발환경 클러스터 설정...$(NC)"
	@chmod +x environments/development/setup-dev.sh
	@ENVIRONMENT=development DOMAIN=${DOMAIN} DRY_RUN=${DRY_RUN} VERBOSE=${VERBOSE} \
		./environments/development/setup-dev.sh

## 개발환경 정리
dev-clean: check
	@echo "$(YELLOW)⚠️ 개발환경을 정리합니다...$(NC)"
	@read -p "개발 클러스터를 삭제하시겠습니까? [y/N]: " confirm; \
	if [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ]; then \
		kind delete cluster --name dev-cluster 2>/dev/null || true; \
		docker-compose -f environments/development/docker-compose.dev.yml down -v 2>/dev/null || true; \
		echo "$(GREEN)개발환경 정리 완료$(NC)"; \
	else \
		echo "$(GREEN)정리 작업이 취소되었습니다.$(NC)"; \
	fi

## 프로덕션환경 배포
prod: check
	@echo "$(GREEN)🏭 프로덕션환경 배포 시작...$(NC)"
	@if [ "${DOMAIN}" = "example.com" ]; then \
		echo "$(RED)오류: 프로덕션 배포를 위해서는 실제 도메인을 설정해야 합니다.$(NC)"; \
		echo "$(YELLOW)예시: make prod DOMAIN=mycompany.com$(NC)"; \
		exit 1; \
	fi
	@ENVIRONMENT=production DOMAIN=${DOMAIN} DRY_RUN=${DRY_RUN} VERBOSE=${VERBOSE} \
		$(K8S_MANAGER) install-tools
	@chmod +x environments/production/setup-prod.sh
	@ENVIRONMENT=production DOMAIN=${DOMAIN} DRY_RUN=${DRY_RUN} VERBOSE=${VERBOSE} \
		./environments/production/setup-prod.sh

## 프로덕션 배포 전 검증
prod-validate: check
	@echo "$(GREEN)🔍 프로덕션 배포 전 검증...$(NC)"
	@ENVIRONMENT=production DOMAIN=${DOMAIN} DRY_RUN=true VERBOSE=true \
		./environments/production/setup-prod.sh

## 프로덕션 백업
prod-backup: check
	@echo "$(GREEN)💾 프로덕션 백업 실행...$(NC)"
	@if command -v velero >/dev/null 2>&1; then \
		velero backup create manual-backup-$(shell date +%Y%m%d-%H%M%S); \
		echo "$(GREEN)백업 완료$(NC)"; \
	else \
		echo "$(RED)Velero가 설치되지 않았습니다.$(NC)"; \
		exit 1; \
	fi

## Docker 개발환경
docker-dev: check
	@echo "$(GREEN)🐳 Docker 개발환경 시작...$(NC)"
	@docker-compose -f environments/development/docker-compose.dev.yml --profile development up -d
	@echo "$(GREEN)개발환경이 시작되었습니다.$(NC)"
	@echo "$(BLUE)접속 정보:$(NC)"
	@echo "  - Grafana: http://localhost:3000 (admin/dev)"
	@echo "  - PostgreSQL: localhost:5432 (dev/devpass)"
	@echo "  - Redis: localhost:6379"

## Docker 프로덕션환경
docker-prod: check
	@echo "$(GREEN)🐳 Docker 프로덕션환경 시작...$(NC)"
	@if [ "${DOMAIN}" = "example.com" ]; then \
		echo "$(RED)오류: 프로덕션 환경을 위해서는 실제 도메인을 설정해야 합니다.$(NC)"; \
		exit 1; \
	fi
	@DOMAIN=${DOMAIN} docker-compose -f environments/production/docker-compose.prod.yml --profile production up -d

## 핵심 도구 설치
install: check
	@echo "$(GREEN)🔧 핵심 도구 설치...$(NC)"
	@ENVIRONMENT=${ENVIRONMENT} DOMAIN=${DOMAIN} DRY_RUN=${DRY_RUN} VERBOSE=${VERBOSE} \
		$(K8S_MANAGER) install-tools

## 설치 상태 확인
status: check
	@echo "$(GREEN)📊 설치 상태 확인...$(NC)"
	@ENVIRONMENT=${ENVIRONMENT} DOMAIN=${DOMAIN} $(K8S_MANAGER) status

## 리소스 정리
clean: check
	@echo "$(YELLOW)⚠️ 리소스를 정리합니다...$(NC)"
	@read -p "모든 리소스를 정리하시겠습니까? [y/N]: " confirm; \
	if [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ]; then \
		ENVIRONMENT=${ENVIRONMENT} DOMAIN=${DOMAIN} DRY_RUN=${DRY_RUN} VERBOSE=${VERBOSE} \
			$(K8S_MANAGER) cleanup; \
	else \
		echo "$(GREEN)정리 작업이 취소되었습니다.$(NC)"; \
	fi

## 로그 확인
logs:
	@echo "$(GREEN)📄 최근 로그 파일들:$(NC)"
	@ls -la $(LOG_DIR)/ 2>/dev/null || echo "로그 파일이 없습니다."
	@echo ""
	@echo "$(YELLOW)최신 로그 내용:$(NC)"
	@tail -n 20 $(LOG_DIR)/*k8s-setup*.log 2>/dev/null || echo "로그 내용이 없습니다."

## 환경 정보 출력
info:
	@echo "$(GREEN)현재 설정:$(NC)"
	@echo "  환경: $(ENVIRONMENT)"
	@echo "  도메인: $(DOMAIN)"
	@echo "  클러스터: $(CLUSTER_NAME)"
	@echo "  DRY RUN: $(DRY_RUN)"
	@echo "  VERBOSE: $(VERBOSE)"
	@echo ""
	@echo "$(GREEN)시스템 정보:$(NC)"
	@uname -a
	@echo ""
	@if command -v kubectl >/dev/null 2>&1; then \
		echo "$(GREEN)Kubernetes 클러스터 정보:$(NC)"; \
		kubectl cluster-info 2>/dev/null || echo "클러스터에 연결할 수 없습니다."; \
	else \
		echo "$(YELLOW)kubectl이 설치되지 않았습니다.$(NC)"; \
	fi

## 별칭 설정
aliases:
	@echo "$(GREEN)kubectl 별칭 설정...$(NC)"
	@if [ -f ~/.zshrc ]; then \
		echo "# Kubernetes aliases" >> ~/.zshrc; \
		echo "alias k='kubectl'" >> ~/.zshrc; \
		echo "alias kgp='kubectl get pods'" >> ~/.zshrc; \
		echo "alias kgs='kubectl get services'" >> ~/.zshrc; \
		echo "alias kgd='kubectl get deployments'" >> ~/.zshrc; \
		echo "별칭이 ~/.zshrc에 추가되었습니다."; \
	elif [ -f ~/.bashrc ]; then \
		echo "# Kubernetes aliases" >> ~/.bashrc; \
		echo "alias k='kubectl'" >> ~/.bashrc; \
		echo "alias kgp='kubectl get pods'" >> ~/.bashrc; \
		echo "alias kgs='kubectl get services'" >> ~/.bashrc; \
		echo "별칭이 ~/.bashrc에 추가되었습니다."; \
	fi

## 실행 전 확인
check:
	@echo "$(YELLOW)실행 환경 확인...$(NC)"
	@if [ ! -f "$(K8S_MANAGER)" ]; then \
		echo "$(RED)오류: k8s-manager.sh 파일을 찾을 수 없습니다.$(NC)"; \
		exit 1; \
	fi
	@chmod +x $(K8S_MANAGER)
	@mkdir -p $(LOG_DIR)

## 핵심 도구 설치
install: check
	@echo "$(GREEN)핵심 도구 설치 시작...$(NC)"
	@DOMAIN=$(DOMAIN) DRY_RUN=$(DRY_RUN) VERBOSE=$(VERBOSE) $(K8S_MANAGER) install-tools

## 클러스터 환경 설정
setup: check
	@echo "$(GREEN)클러스터 환경 설정 시작...$(NC)"
	@DOMAIN=$(DOMAIN) DRY_RUN=$(DRY_RUN) VERBOSE=$(VERBOSE) $(K8S_MANAGER) setup-cluster

## ArgoCD 설치
argocd: check
	@echo "$(GREEN)ArgoCD 설치 시작...$(NC)"
	@DOMAIN=$(DOMAIN) DRY_RUN=$(DRY_RUN) VERBOSE=$(VERBOSE) $(K8S_MANAGER) setup-argocd

## 보안 정책 설정
security: check
	@echo "$(GREEN)보안 정책 설정 시작...$(NC)"
	@DOMAIN=$(DOMAIN) DRY_RUN=$(DRY_RUN) VERBOSE=$(VERBOSE) $(K8S_MANAGER) setup-security

## 모니터링 스택 설치
monitoring: check
	@echo "$(GREEN)모니터링 스택 설치 시작...$(NC)"
	@DOMAIN=$(DOMAIN) DRY_RUN=$(DRY_RUN) VERBOSE=$(VERBOSE) $(K8S_MANAGER) setup-monitoring

## CI/CD 파이프라인 생성
pipeline: check
	@echo "$(GREEN)CI/CD 파이프라인 생성 시작...$(NC)"
	@DOMAIN=$(DOMAIN) DRY_RUN=$(DRY_RUN) VERBOSE=$(VERBOSE) $(K8S_MANAGER) create-pipeline

## 전체 설치 및 설정
all: install setup security argocd monitoring pipeline
	@echo "$(GREEN)✅ 전체 설치 및 설정 완료!$(NC)"

## 설치 상태 확인
status: check
	@echo "$(GREEN)설치 상태 확인...$(NC)"
	@DOMAIN=$(DOMAIN) $(K8S_MANAGER) status

## 리소스 정리
clean: check
	@echo "$(YELLOW)⚠️  모든 리소스를 정리합니다. 정말 계속하시겠습니까? [y/N]$(NC)"
	@read -r confirm; \
	if [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ]; then \
		DOMAIN=$(DOMAIN) DRY_RUN=$(DRY_RUN) VERBOSE=$(VERBOSE) $(K8S_MANAGER) cleanup; \
	else \
		echo "$(GREEN)정리 작업이 취소되었습니다.$(NC)"; \
	fi

## 로그 확인
logs:
	@echo "$(GREEN)최근 로그 파일들:$(NC)"
	@ls -la $(LOG_DIR)/ 2>/dev/null || echo "로그 파일이 없습니다."
	@echo ""
	@echo "$(YELLOW)최신 로그 내용:$(NC)"
	@tail -n 20 $(LOG_DIR)/*k8s-setup*.log 2>/dev/null || echo "로그 내용이 없습니다."

## 개발자용 명령
dev-setup: check
	@echo "$(GREEN)개발 환경 설정...$(NC)"
	@DOMAIN=dev.local DRY_RUN=false VERBOSE=true $(K8S_MANAGER) install-tools
	@DOMAIN=dev.local DRY_RUN=false VERBOSE=true $(K8S_MANAGER) setup-cluster

## 테스트용 명령
test: check
	@echo "$(GREEN)테스트 실행...$(NC)"
	@DOMAIN=test.local DRY_RUN=true VERBOSE=true $(K8S_MANAGER) install-tools
	@DOMAIN=test.local DRY_RUN=true VERBOSE=true $(K8S_MANAGER) setup-cluster

## kubectl 별칭 설정
aliases:
	@echo "$(GREEN)kubectl 별칭 설정...$(NC)"
	@if [ -f ~/.zshrc ]; then \
		echo "# Kubernetes aliases" >> ~/.zshrc; \
		echo "alias k='kubectl'" >> ~/.zshrc; \
		echo "alias kgp='kubectl get pods'" >> ~/.zshrc; \
		echo "alias kgs='kubectl get services'" >> ~/.zshrc; \
		echo "별칭이 ~/.zshrc에 추가되었습니다. 새 터미널을 열거나 'source ~/.zshrc'를 실행하세요."; \
	elif [ -f ~/.bashrc ]; then \
		echo "# Kubernetes aliases" >> ~/.bashrc; \
		echo "alias k='kubectl'" >> ~/.bashrc; \
		echo "alias kgp='kubectl get pods'" >> ~/.bashrc; \
		echo "alias kgs='kubectl get services'" >> ~/.bashrc; \
		echo "별칭이 ~/.bashrc에 추가되었습니다. 새 터미널을 열거나 'source ~/.bashrc'를 실행하세요."; \
	fi

## 환경 정보 출력
info:
	@echo "$(GREEN)현재 설정:$(NC)"
	@echo "  도메인: $(DOMAIN)"
	@echo "  클러스터: $(CLUSTER_NAME)"
	@echo "  DRY RUN: $(DRY_RUN)"
	@echo "  VERBOSE: $(VERBOSE)"
	@echo ""
	@echo "$(GREEN)시스템 정보:$(NC)"
	@uname -a
	@echo ""
	@if command -v kubectl >/dev/null 2>&1; then \
		echo "$(GREEN)Kubernetes 클러스터 정보:$(NC)"; \
		kubectl cluster-info 2>/dev/null || echo "클러스터에 연결할 수 없습니다."; \
	else \
		echo "$(YELLOW)kubectl이 설치되지 않았습니다.$(NC)"; \
	fi
