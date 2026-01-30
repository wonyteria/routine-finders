---
description: Prototype을 메인 서비스로 전환하는 마이그레이션 가이드
---

# Prototype → Main Service 마이그레이션 가이드

이 문서는 현재 `/prototype/*` 경로로 운영 중인 프로토타입 페이지들을 메인 서비스 경로로 전환하는 절차를 정리한 것입니다.

## 📋 현재 상태 분석

### Prototype 경로 (앞으로 메인으로 사용할 페이지들)
- `/prototype/home` - 프로토타입 홈 (루파 클럽 중심 대시보드)
- `/prototype/my` - 마이 페이지 (개인 루틴 + 챌린지 통합)
- `/prototype/explore` - 탐색 페이지
- `/prototype/synergy` - 시너지 페이지
- `/prototype/notifications` - 알림
- `/prototype/record` - 루틴 기록
- `/prototype/admin` - 시스템 명령 센터
- `/prototype/admin/clubs` - 루파 클럽 통합 관리
- `/prototype/live` - 라이브 룸
- `/prototype/lecture_intro` - 강의 소개
- `/prototype/routine_builder` - 루틴 빌더
- `/prototype/challenge_builder` - 챌린지 빌더
- `/prototype/gathering_builder` - 모임 빌더
- `/prototype/club_join` - 클럽 가입

### 기존 Production 경로 (삭제 예정)
- `/` (root) → `home#index`
- `/challenges` → `challenges#index`
- `/personal_routines` → `personal_routines#index`
- `/gatherings` → `gatherings#index`
- `/rankings` → `rankings#index`
- `/profile` → `profiles#show`
- 기타 RESTful 리소스 경로들

---

## 🚀 마이그레이션 단계별 실행 계획

### Phase 1: 백업 및 준비 (사전 작업)
```bash
# 1. 현재 상태 커밋
git add .
git commit -m "Pre-migration backup: Save current state before prototype migration"

# 2. 마이그레이션 브랜치 생성
git checkout -b feature/migrate-prototype-to-main

# 3. 데이터베이스 백업 (운영 환경)
# Kamal을 통해 DB 덤프 생성
bundle exec kamal app exec "pg_dump -U postgres routine_finders_production > /tmp/backup_$(date +%Y%m%d).sql"
```

### Phase 2: Routes 재구성
**파일**: `config/routes.rb`

**작업 내용**:
1. 기존 root 경로를 prototype/home으로 변경
2. prototype 네임스페이스 제거하고 직접 경로로 변경
3. 사용하지 않는 구형 컨트롤러 라우트 주석 처리

**예시**:
```ruby
# Before
root "home#index"
get "prototype/home", to: "prototype#home"

# After
root "prototype#home"
get "explore", to: "prototype#explore"
get "my", to: "prototype#my"
# ... 나머지 prototype 경로들도 동일하게 변경
```

### Phase 3: Controller 이름 변경 (선택사항)
현재 `PrototypeController`를 더 명확한 이름으로 변경할 수 있습니다.

**옵션 A**: 그대로 유지 (가장 안전)
- `PrototypeController` 이름 유지
- 라우트만 변경하여 `/home`, `/my` 등으로 접근

**옵션 B**: 컨트롤러 분리 (권장)
- `PrototypeController`를 기능별로 분리
  - `DashboardController` (home, my, explore, synergy)
  - `AdminController` (admin 관련)
  - `BuildersController` (routine_builder, challenge_builder 등)

### Phase 4: View 경로 정리
**작업 내용**:
- `app/views/prototype/` 폴더를 유지하거나
- 새로운 폴더 구조로 이동 (컨트롤러 분리 시)

### Phase 5: 기존 파일 정리
**삭제 대상**:
```
app/controllers/
  - home_controller.rb (기존 홈)
  - challenges_controller.rb (일부 기능만 사용 중이므로 검토 필요)
  - gatherings_controller.rb (검토 필요)
  - personal_routines_controller.rb (검토 필요)

app/views/
  - home/ (기존 홈 뷰)
  - 기타 사용하지 않는 뷰 폴더들
```

**⚠️ 주의**: 
- `challenges_controller.rb`, `routine_clubs_controller.rb` 등은 실제 CRUD 로직이 있으므로 **삭제하지 말고 유지**
- Prototype은 주로 "보여주기" 역할, 실제 데이터 처리는 기존 컨트롤러 사용

### Phase 6: 네비게이션 및 링크 업데이트
**파일**: `app/views/layouts/application.html.erb`, `app/views/shared/_bottom_nav.html.erb`

**작업 내용**:
- 모든 `prototype_*_path` 헬퍼를 새 경로로 변경
- 예: `prototype_home_path` → `root_path`
- 예: `prototype_my_path` → `my_path`

### Phase 7: 테스트 및 검증
```bash
# 로컬 환경에서 테스트
bundle exec rails s

# 주요 페이지 접속 확인
# - / (홈)
# - /my (마이페이지)
# - /explore (탐색)
# - /admin (관리자)
# - /routine_clubs (루파 클럽)

# 모든 링크 클릭 테스트
# 폼 제출 테스트
# 인증 플로우 테스트
```

### Phase 8: 배포
```bash
# 1. 변경사항 커밋
git add .
git commit -m "Migrate prototype to main service routes"

# 2. 메인 브랜치 병합
git checkout main
git merge feature/migrate-prototype-to-main

# 3. 배포
git push origin main

# 4. Kamal 배포 (자동 트리거 또는 수동)
bundle exec kamal deploy
```

---

## 📝 체크리스트

### 사전 준비
- [ ] 현재 상태 Git 커밋
- [ ] 데이터베이스 백업
- [ ] 마이그레이션 브랜치 생성

### 코드 변경
- [ ] `config/routes.rb` 업데이트
- [ ] 컨트롤러 이름 변경 (선택)
- [ ] View 경로 정리
- [ ] 네비게이션 링크 업데이트
- [ ] 사용하지 않는 파일 삭제/주석

### 테스트
- [ ] 로컬 환경 동작 확인
- [ ] 모든 주요 페이지 접속 테스트
- [ ] 인증 플로우 테스트
- [ ] 폼 제출 및 CRUD 동작 확인
- [ ] 관리자 기능 테스트

### 배포
- [ ] 변경사항 커밋 및 푸시
- [ ] 운영 환경 배포
- [ ] 배포 후 동작 확인
- [ ] 롤백 계획 준비

---

## 🔄 롤백 계획

만약 마이그레이션 후 문제가 발생하면:

```bash
# 1. 이전 커밋으로 되돌리기
git revert HEAD

# 2. 또는 브랜치 전체 되돌리기
git checkout main
git reset --hard <이전_커밋_해시>

# 3. 재배포
git push origin main --force
bundle exec kamal deploy
```

---

## 💡 권장사항

1. **점진적 마이그레이션**: 한 번에 모든 것을 바꾸지 말고, 먼저 홈 페이지만 변경 후 테스트
2. **A/B 테스트**: 가능하다면 일부 사용자에게만 새 경로 노출
3. **리다이렉트 설정**: 기존 경로 접속 시 새 경로로 자동 리다이렉트 추가
4. **문서화**: 변경된 경로 목록을 README에 정리

---

## 📌 참고사항

- 현재 `PrototypeController`는 약 800줄의 대형 컨트롤러입니다
- 나중에 기능별로 분리하는 것을 고려하세요 (DashboardController, AdminController 등)
- 실제 데이터 처리 로직은 기존 컨트롤러(`ChallengesController`, `RoutineClubsController` 등)를 계속 사용합니다
- Prototype은 주로 "통합 대시보드" 역할을 하며, 실제 CRUD는 기존 RESTful 컨트롤러에 위임합니다

---

**작성일**: 2026-01-31  
**최종 수정**: 2026-01-31
