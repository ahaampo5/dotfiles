# 🏭 프로덕션환경 설정

프로덕션 환경을 위한 보안 강화된 Kubernetes 설정 가이드

## 🎯 프로덕션 특징

- **보안 우선**: 보안 스캐닝, 정책 적용
- **고가용성**: HA 구성의 모니터링 스택
- **클라우드 통합**: EKS/GKE/AKS 지원
- **GitOps**: ArgoCD를 통한 배포 관리
- **백업**: Velero를 통한 자동 백업
- **컴플라이언스**: OPA Gatekeeper 정책

## 🚀 배포 전 준비

### 1. 필수 요구사항
- 실제 도메인 (example.com 사용 불가)
- 클라우드 클러스터 (EKS/GKE/AKS)
- 적절한 RBAC 권한

### 2. 검증 실행
```bash
# 배포 전 반드시 검증
make prod-validate DOMAIN=mycompany.com
```

## 🔐 보안 구성

### 포함된 보안 도구
- **Trivy**: 컨테이너 이미지 보안 스캐닝
- **OPA Gatekeeper**: 정책 기반 거버넌스
- **Falco**: 런타임 보안 모니터링
- **Pod Security Standards**: 포드 보안 표준 적용

### 보안 정책
- 권한 있는 컨테이너 금지
- 루트 사용자 실행 금지
- 리소스 제한 강제
- 네트워크 정책 적용

## 📊 모니터링 스택

### 고가용성 구성
- **Prometheus**: HA 모드 메트릭 수집
- **Grafana**: 대시보드 및 알림
- **AlertManager**: 알림 라우팅
- **Jaeger**: 분산 추적

### 로깅
- **Fluentd**: 로그 수집 및 전송
- **Elasticsearch**: 로그 저장 (선택사항)

## 🔄 GitOps 배포

### ArgoCD 구성
- 자동 동기화
- 롤백 기능
- 다중 클러스터 지원
- RBAC 통합

## 💾 백업 전략

### Velero 설정
- 자동 백업 스케줄링
- 재해 복구 절차
- 클라우드 스토리지 통합

```bash
# 수동 백업 실행
make prod-backup
```

## 🚀 배포 절차

### 1. 환경 변수 확인
```bash
# production/config.sh 설정 확인
CLUSTER_PROVIDER="eks"  # eks/gke/aks
DOMAIN="mycompany.com"
ENABLE_SECURITY="true"
```

### 2. 배포 실행
```bash
# 프로덕션 배포
make prod DOMAIN=mycompany.com
```

### 3. 배포 후 검증
```bash
# 상태 확인
make status

# 보안 스캔 실행
trivy k8s --report summary cluster
```

## 📋 체크리스트

### 배포 전
- [ ] 도메인 설정 확인
- [ ] 클라우드 자격 증명 설정
- [ ] 백업 스토리지 구성
- [ ] DNS 설정 확인

### 배포 후
- [ ] 모든 포드 Running 상태 확인
- [ ] 모니터링 대시보드 접속 확인
- [ ] 보안 정책 적용 확인
- [ ] 백업 작업 정상 동작 확인

## 🔧 문제해결

### 일반적인 문제

1. **클러스터 연결 실패**
   ```bash
   # kubeconfig 확인
   kubectl config current-context
   ```

2. **ArgoCD 접속 불가**
   ```bash
   # 포트 포워딩으로 임시 접속
   kubectl port-forward svc/argocd-server -n argocd 8080:443
   ```

3. **모니터링 대시보드 접속 불가**
   ```bash
   # Grafana 포트 포워딩
   kubectl port-forward svc/grafana -n monitoring 3000:80
   ```

## 📞 운영 지원

- **알림**: Slack/Teams 통합
- **로그**: 중앙 집중식 로깅
- **메트릭**: 커스텀 대시보드
- **보안**: 실시간 보안 모니터링
