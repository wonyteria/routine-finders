# React → Rails 마이그레이션 계획

> **참조 커밋**: [wonyteria/Routine-Finders@ad95b9f](https://github.com/wonyteria/Routine-Finders/commit/ad95b9f)
>
> **커밋 메시지**: `feat: Add comprehensive user profile and application types`

---

## 📋 구현 단계 체크리스트

### Phase 1: 데이터베이스/모델

- [ ] **Step 1**: ChallengeApplication 모델 생성
- [ ] **Step 2**: User 모델 확장 (bio, sns_links, saved_account)
- [ ] **Step 3**: Challenge 모델 확장 (invitation_code, is_private 등)
- [ ] **Step 4**: Review 모델 생성
- [ ] **Step 5**: Announcement 모델 생성

### Phase 2: 컨트롤러

- [ ] **Step 6**: ChallengeApplicationsController 생성

### Phase 3: 뷰/페이지

- [ ] **Step 7**: 호스트 콘솔 - 신청 관리 탭 추가
- [ ] **Step 8**: 챌린지 신청 페이지 (ApplyChallenge)
- [ ] **Step 9**: 프로필 페이지 수정
- [ ] **Step 10**: 랭킹 페이지
- [ ] **Step 11**: 공개 프로필 페이지
- [ ] **Step 12**: Reviews 컨트롤러/뷰
- [ ] **Step 13**: Announcements 컨트롤러/뷰
- [ ] **Step 14**: 챌린지 상세 수정

### Phase 4: 검증

- [ ] **Step 15**: 테스트 작성 및 검증

---

## 🗃️ 데이터베이스 스키마 변경

### 1. ChallengeApplication (신규) ⭐

```ruby
# db/migrate/xxx_create_challenge_applications.rb
create_table :challenge_applications do |t|
  t.references :challenge, null: false, foreign_key: true
  t.references :user, null: false, foreign_key: true
  t.integer :status, null: false, default: 0  # pending: 0, approved: 1, rejected: 2
  t.text :message                              # 신청 메시지
  t.string :depositor_name                     # 입금자명
  t.text :reject_reason                        # 거절 사유
  t.datetime :applied_at, null: false

  t.timestamps
end

add_index :challenge_applications, [:challenge_id, :user_id], unique: true
add_index :challenge_applications, :status
```

### 2. User 확장

```ruby
# db/migrate/xxx_add_profile_fields_to_users.rb
add_column :users, :bio, :text
add_column :users, :sns_links, :json, default: {}
add_column :users, :saved_bank_name, :string
add_column :users, :saved_account_number, :string
add_column :users, :saved_account_holder, :string
```

### 3. Challenge 확장

```ruby
# db/migrate/xxx_add_extended_fields_to_challenges.rb
add_column :challenges, :invitation_code, :string
add_column :challenges, :is_private, :boolean, default: false
add_column :challenges, :meeting_link, :string
add_column :challenges, :requires_application_message, :boolean, default: false
add_column :challenges, :re_verification_allowed, :boolean, default: true
add_column :challenges, :verification_start_time, :time
add_column :challenges, :verification_end_time, :time
add_column :challenges, :likes_count, :integer, default: 0
add_column :challenges, :average_rating, :decimal, precision: 3, scale: 2, default: 0.0

add_index :challenges, :invitation_code, unique: true
add_index :challenges, :is_private
```

### 4. Review (신규)

```ruby
# db/migrate/xxx_create_reviews.rb
create_table :reviews do |t|
  t.references :challenge, null: false, foreign_key: true
  t.references :user, null: false, foreign_key: true
  t.integer :rating, null: false  # 1-5
  t.text :content
  t.integer :likes_count, default: 0

  t.timestamps
end

add_index :reviews, [:challenge_id, :user_id], unique: true
```

### 5. Announcement (신규)

```ruby
# db/migrate/xxx_create_announcements.rb
create_table :announcements do |t|
  t.references :challenge, null: false, foreign_key: true
  t.string :title, null: false
  t.text :content

  t.timestamps
end
```

---

## 🎨 모델 정의

### ChallengeApplication

```ruby
# app/models/challenge_application.rb
class ChallengeApplication < ApplicationRecord
  enum :status, { pending: 0, approved: 1, rejected: 2 }

  belongs_to :challenge
  belongs_to :user

  validates :user_id, uniqueness: { scope: :challenge_id }
  validates :applied_at, presence: true
  validates :message, presence: true, if: -> { challenge&.requires_application_message }

  before_validation :set_applied_at, on: :create

  # 승인 시 Participant 생성
  def approve!
    transaction do
      update!(status: :approved)
      challenge.participants.create!(
        user: user,
        joined_at: Time.current,
        paid_amount: challenge.amount
      )
      # 알림 발송
      user.notifications.create!(
        notification_type: :approval,
        title: '신청 승인 완료',
        content: "[#{challenge.title}] 신청이 승인되었습니다."
      )
    end
  end

  def reject!(reason = nil)
    update!(status: :rejected, reject_reason: reason)
    user.notifications.create!(
      notification_type: :rejection,
      title: '신청 거절 안내',
      content: "[#{challenge.title}] 신청이 거절되었습니다. #{reason}"
    )
  end

  private

  def set_applied_at
    self.applied_at ||= Time.current
  end
end
```

### Review

```ruby
# app/models/review.rb
class Review < ApplicationRecord
  belongs_to :challenge
  belongs_to :user

  validates :rating, presence: true, inclusion: { in: 1..5 }
  validates :user_id, uniqueness: { scope: :challenge_id, message: "이미 리뷰를 작성했습니다" }

  after_save :update_challenge_rating
  after_destroy :update_challenge_rating

  private

  def update_challenge_rating
    avg = challenge.reviews.average(:rating) || 0
    challenge.update(average_rating: avg)
  end
end
```

---

## 🛣️ 라우트

```ruby
# config/routes.rb
resources :challenges do
  resource :application, only: [:new, :create], controller: 'challenge_applications'
  resources :reviews, only: [:index, :create, :destroy]
  resources :announcements, only: [:index, :create, :update, :destroy]
end

resources :users, only: [:show]  # 공개 프로필
get '/ranking', to: 'ranking#index'
```

---

## 📄 새로운 페이지 구조

### 1. 챌린지 신청 페이지

**경로**: `/challenges/:id/application/new`

**구성요소**:
- 입금 계좌 정보 카드 (복사 버튼)
- 입금자명 입력 필드
- 신청 메시지 textarea
- 동의 체크박스 3개 (규칙, 보증금, 개인정보)
- 제출 버튼

### 2. 랭킹 페이지

**경로**: `/ranking`

**탭**:
- 주간 랭킹 (streak, exp 기준)
- 명예의 전당 (총 완료 챌린지 수, 레벨)

### 3. 공개 프로필

**경로**: `/users/:id`

**구성요소**:
- 프로필 카드 (사진, 닉네임, bio, SNS 링크)
- 통계 (streak, completed, level)
- 탭: 업적 인사이트 / 활동 피드

### 4. 호스트 콘솔 신청 관리 탭

**구성요소**:
- 대기 중인 신청 목록
- 각 신청: 닉네임, 입금자명 (복사), 메시지
- 승인/거절 버튼
- 거절 시 사유 입력 모달

---

## 🔄 React → Rails 변환 패턴

| React | Rails |
|-------|-------|
| `useState` | Stimulus Controller |
| `onClick={fn}` | `data-action="click->ctrl#method"` |
| `className` | `class` |
| `{condition && <Component/>}` | `<% if condition %>...<% end %>` |
| `items.map(i => ...)` | `<% items.each do \|i\| %>...<% end %>` |
| Component import | `<%= render "partial" %>` |
| `useEffect` | Turbo Frame / Stimulus `connect()` |
| `localStorage` | Session / Cookie |

---

## 📝 diff 확인 명령어

```bash
# 전체 diff 저장
gh api repos/wonyteria/Routine-Finders/commits/ad95b9f \
  -H "Accept: application/vnd.github.diff" > /tmp/ad95b9f.diff

# 특정 파일 diff 보기
sed -n '5883,$p' /tmp/ad95b9f.diff  # types.ts
sed -n '1394,1566p' /tmp/ad95b9f.diff  # ApplyChallenge.tsx
sed -n '5071,5253p' /tmp/ad95b9f.diff  # Ranking.tsx
sed -n '4852,5070p' /tmp/ad95b9f.diff  # PublicProfile.tsx
```

---

## ✅ 이미 적용된 사항

- `Notification` 타입: `approval`, `rejection` 존재
- `Challenge.admission_type`: `first_come`, `approval` enum 존재
- 디자인 시스템: Tailwind CSS, 동일한 컴포넌트 스타일
