# 🛠️ 개발환경 설정

개발자를 위한 로컬 Kubernetes 환경 설정 가이드

## 🎯 개발환경 특징

- **빠른 시작**: Kind 클러스터로 로컬 환경 구성
- **디버깅 도구**: k9s, stern 등 개발용 도구 포함
- **로컬 서비스**: PostgreSQL, Redis 등 개발용 데이터베이스
- **간편한 모니터링**: 기본적인 Grafana/Prometheus 설정
- **유연한 설정**: 개발 편의성 우선

## 🚀 빠른 시작

```bash
# 개발환경 전체 설정
make dev

# 또는 단계별 실행
make dev-setup
make docker-dev
```

## 📋 포함된 도구

### 클러스터 도구
- **Kind**: 로컬 Kubernetes 클러스터
- **kubectl**: Kubernetes CLI
- **helm**: 패키지 매니저

### 디버깅 도구
- **k9s**: 터미널 기반 Kubernetes UI
- **stern**: 멀티 포드 로그 추적
- **kubectx/kubens**: 컨텍스트/네임스페이스 전환

### 개발 서비스
- **PostgreSQL**: 개발용 데이터베이스
- **Redis**: 캐시 및 세션 저장소
- **Grafana**: 모니터링 대시보드
- **Prometheus**: 메트릭 수집

## 🔧 설정 파일

- `config.sh`: 개발환경 변수
- `docker-compose.dev.yml`: 개발용 서비스
- `setup-dev.sh`: 개발환경 설정 스크립트

## 📊 접속 정보

개발 서비스 실행 후:
- **Grafana**: http://localhost:3000 (admin/dev)
- **PostgreSQL**: localhost:5432 (dev/devpass)
- **Redis**: localhost:6379

## 🔄 일반적인 작업

```bash
# 클러스터 상태 확인
kubectl cluster-info

# 포드 목록 확인
kubectl get pods -A

# k9s로 클러스터 관리
k9s

# 로그 실시간 추적
stern my-app
```

## 🧹 정리

```bash
# 개발환경 정리
make dev-clean

# 또는 수동 정리
kind delete cluster --name dev-cluster
docker-compose -f docker-compose.dev.yml down -v
```
