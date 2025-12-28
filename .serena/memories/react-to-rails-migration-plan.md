# React → Rails 마이그레이션 계획

## 개요
GitHub 레포지토리 `wonyteria/Routine-Finders` (React/TypeScript)의 커밋 `ad95b9f`를 현재 Rails 프로젝트에 적용하는 작업.

커밋 메시지: `feat: Add comprehensive user profile and application types`

## 참조 커밋 정보
- Repository: https://github.com/wonyteria/Routine-Finders
- Commit: ad95b9f
- 변경 파일 수: 17개
- 주요 변경: 사용자 프로필 확장, 챌린지 신청 시스템, 랭킹/공개 프로필 기능

## 주요 변경사항 요약

### 1. 새로운 타입/모델

#### ChallengeApplication (신청 관리) ⭐ 핵심
```
- challenge_id, user_id (FK)
- status: enum (pending, approved, rejected)
- message: text (신청 메시지)
- depositor_name: string (입금자명)
- reject_reason: text (거절 사유)
- applied_at: datetime
```

#### Review (챌린지 리뷰)
```
- challenge_id, user_id (FK)
- rating: integer (1-5)
- content: text
- likes_count: integer
```

#### Announcement (챌린지 공지사항)
```
- challenge_id (FK)
- title: string
- content: text
```

### 2. User 모델 확장
```
- bio: text (자기소개)
- sns_links: json {instagram, threads, blog, youtube, twitter}
- saved_bank_name: string
- saved_account_number: string
- saved_account_holder: string
```

### 3. Challenge 모델 확장
```
- invitation_code: string (unique, 비공개 챌린지용)
- is_private: boolean (default: false)
- meeting_link: string (화상 미팅 링크)
- requires_application_message: boolean
- re_verification_allowed: boolean
- verification_start_time: time
- verification_end_time: time
- likes_count: integer
- average_rating: decimal
```

### 4. 새로운 페이지
| 페이지 | 설명 | Rails 경로 예상 |
|--------|------|----------------|
| ApplyChallenge | 챌린지 신청 | `/challenges/:id/apply` |
| Ranking | 랭킹 (주간/명예의전당) | `/ranking` |
| PublicProfile | 공개 프로필 | `/users/:id` |
| CreateGathering | 오프라인 모임 생성 | `/gatherings/new` |
| CreateRoutine | 개인 루틴 생성 | `/personal_routines/new` |

### 5. 기존 페이지 수정
| 페이지 | 변경 내용 |
|--------|----------|
| CreatorConsole (호스트 콘솔) | 신청 관리 탭, 공지사항/리뷰 관리 |
| Profile | bio/SNS 편집, 저장 계좌, 신청 내역 |
| ChallengeDetail | 리뷰/평점, 호스트 정보 |

## 구현 단계 (15 Steps)

### Phase 1: 데이터베이스/모델 (Step 1-5) ✅ 완료
1. **ChallengeApplication 모델 생성** ✅
   - 마이그레이션: `20251227154817_create_challenge_applications.rb`
   - 모델: `app/models/challenge_application.rb`
   - 테스트: `test/models/challenge_application_test.rb`
   
2. **User 모델 확장** ✅
   - 마이그레이션: `20251227155423_add_profile_fields_to_users.rb`
   - 추가 컬럼: bio, sns_links(json), saved_bank_name, saved_account_number, saved_account_holder
   
3. **Challenge 모델 확장** ✅
   - 마이그레이션: `20251227155557_add_extended_fields_to_challenges.rb`
   - 추가 컬럼: invitation_code, is_private, meeting_link, requires_application_message, re_verification_allowed, verification_start_time, verification_end_time, likes_count, average_rating
   
4. **Review 모델 생성** ✅
   - 마이그레이션: `20251227155745_create_reviews.rb`
   - 모델: `app/models/review.rb`
   
5. **Announcement 모델 생성** ✅
   - 마이그레이션: `20251227155941_create_announcements.rb`
   - 모델: `app/models/announcement.rb`

### Phase 2: 컨트롤러/API (Step 6) ✅ 완료
6. **ChallengeApplicationsController** ✅
   - 컨트롤러: `app/controllers/challenge_applications_controller.rb`
   - 뷰: `app/views/challenge_applications/new.html.erb`, `index.html.erb`
   - 라우트: `/challenges/:id/applications` (index, new, create, approve, reject)
   - Notification 타입 `application` 추가

### Phase 3: 뷰/페이지 (Step 7-14)
7. **호스트 콘솔 수정** ✅
   - 탭 구조로 재구성: dashboard, applications, participants, announcements, reviews
   - `app/views/hosted_challenges/tabs/*.html.erb` 생성
   - AnnouncementsController 생성 및 라우트 추가
   
8. **챌린지 신청 페이지** ✅
   - 동의 체크박스 시스템 추가
   - Stimulus 컨트롤러: `app/javascript/controllers/application_form_controller.js`
   - 저장된 입금자명 사용 기능
   - message 필수 validation 추가

9. **프로필 페이지 수정** ✅
   - 컨트롤러: `app/controllers/profiles_controller.rb` (edit, update 액션 추가)
   - 뷰: `app/views/profiles/edit.html.erb` (새 파일), `show.html.erb` (수정)
   - 라우트: `resource :profile, only: [:show, :edit, :update]`
   - 기능: bio/SNS 편집, 저장된 계좌 관리, 신청 내역 표시
10. **랭킹 페이지** ✅
   - 컨트롤러: `app/controllers/rankings_controller.rb`
   - 뷰: `app/views/rankings/index.html.erb`
   - 라우트: `/rankings`
   - Stimulus: `tabs_controller.js` (새 파일)
   - 기능: 주간 랭킹 (이번 주 인증 기준), 명예의 전당 (전체 기간 인증 기준)
11. **공개 프로필 페이지** ✅
   - 컨트롤러: `app/controllers/users_controller.rb`
   - 뷰: `app/views/users/show.html.erb`
   - 라우트: `/users/:id`
   - 기능: SNS 링크, 업적/통계, 참여 챌린지, 최근 활동 피드
12. **Reviews 컨트롤러/뷰** ✅
   - 컨트롤러: `app/controllers/reviews_controller.rb`
   - 뷰: `app/views/reviews/*.html.erb`
   - 라우트: `/challenges/:challenge_id/reviews`
   - Stimulus: `rating_controller.js` (별점 선택)
13. **Announcements 컨트롤러/뷰** ✅ (Step 7에서 호스트 콘솔과 함께 구현됨)
14. **챌린지 상세 수정** ✅
   - 뷰: `app/views/challenges/tabs/_info.html.erb` 수정
   - 기능: 호스트 정보 섹션, 리뷰/평점 섹션 추가

### Phase 4: 검증 (Step 15) ✅
15. **테스트 작성** ✅
   - 모델 테스트: `review_test.rb`, `user_test.rb`
   - 컨트롤러 테스트: `profiles_controller_test.rb`, `rankings_controller_test.rb`, `users_controller_test.rb`, `reviews_controller_test.rb`
   - Fixture: `participants.yml`
   - 총 51개 테스트, 100개 assertions

## Gemfile 변경사항
- minitest를 5.x로 고정 (Rails 8.1 호환성)

## 디자인 시스템 (동일)
- Tailwind CSS
- 카드: `rounded-[48px]`, `rounded-[40px]`
- 색상: indigo-600, slate-200/400/900, orange-600 (offline)
- 버튼: `rounded-3xl font-black`
- 폰트: `uppercase tracking-widest`

## React → Rails 변환 패턴
| React | Rails |
|-------|-------|
| `useState` | Stimulus Controller |
| `onClick={fn}` | `data-action="click->ctrl#method"` |
| `className` | `class` |
| `{condition && <div>}` | `<% if condition %>` |
| Component | Partial `render "partial"` |
| `map()` | `<% items.each do \|item\| %>` |

## 기존 Rails 프로젝트 상태
- Notification 타입: approval, rejection 이미 존재
- Challenge.admission_type: first_come, approval 이미 존재 (실제 로직 미구현)
- 디자인 시스템 동일 적용됨

## 명령어 참고
```bash
# 마이그레이션 생성
bin/rails generate migration CreateChallengeApplications

# 모델 생성
bin/rails generate model Review challenge:references user:references rating:integer content:text

# 테스트 실행
bin/rails test
bin/rails test:system
```
