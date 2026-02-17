# Routine Finders - Homepage Functional Specification

## 1. 개요 (Overview)

Routine Finders의 메인 홈페이지는 사용자의 성장과 몰입을 시각화하고, 핵심 활동(루틴, 챌린지, 커뮤니티)으로 연결하는 허브 역할을 합니다. 특히 "디지털 가든(Digital Garden)" 컨셉을 도입하여 사용자의 활동을 시각적으로 아름답게 표현합니다.

## 2. 사용자 역할 (User Roles)

- **Guest (비로그인)**: 일부 기능 제한, 로그인 유도.
- **User (일반 회원)**: 기본 루틴 및 챌린지 참여 가능.
- **Member (루파 클럽 멤버)**: 유료 멤버십 회원. 전용 혜택(라운지, 휴식/세이브권, 배지 등) 및 관리 시스템(경고/제명) 적용.
- **Host (호스트)**: 챌린지 개설 및 관리 권한 보유.
- **Admin (관리자)**: 전체 시스템 관리.

## 3. UI/UX 아키텍처 (UI/UX Architecture)

### 3.1. 헤더 (Header)

- **좌측 (Logo)**: 홈으로 이동.
- **중앙 (Profile/Login)**:
  - 로그인 시: 프로필 이미지, 닉네임, "현재 활동 중" 상태 표시. 클릭 시 마이페이지 이동.
  - 비로그인 시: 로그인/회원가입 버튼 (플로팅 스타일).
- **우측 (Notification)**: 알림 센터 이동. 읽지 않은 알림 개수(배지) 표시.

### 3.2. 라이브 피드 (Live Feed & Commitment)

- **다짐 입력창**: 사용자가 오늘의 확언을 입력하고 제출 기능. (비로그인 시 로그인 유도)
- **Live Ticker**: 다른 유저들의 실시간 활동(루틴 완료, 다짐, 챌린지 참여)을 세로 롤링 효과로 노출.

### 3.3. 디지털 가든 (Digital Garden - Aura)

홈페이지의 핵심 시각화 영역 (`_garden.html.erb`).

- **Bloom Aura (중앙 구체)**: 오늘 루틴 달성률(%)에 따라 구체의 색상, 크기, 파동 효과가 변화.
- **Petals (꽃잎)**: 오늘의 할 일(루틴 + 챌린지)이 방사형으로 배치됨.
  - 완료 시: 아이콘이 밝게 빛나며 아우라 생성. 체크 마크 표시.
- **Active Users**: 현재 접속 중인(활동 중인) 유저 수 표시.
- **Community Footer**:
  - **경고/제명 인디케이터**: (클럽 멤버 전용) 이번 달 누적 경고 수 표시. 클릭 시 규정 모달.
  - **전체 평균**: 전체 유저의 평균 달성률 표시 (Benchmarking).

### 3.4. 위클리 목표 (Weekly Goal)

- 사용자가 설정한 주간 목표 표시.
- 미설정 시 설정 유도 카드 노출.

### 3.5. 오늘의 루틴 (Routine List)

- **날짜 및 요약**: 오늘 날짜 표시.
- **아이템 관리 (PASS)**:
  - **휴식권**: 루틴을 쉬고 출석 인정.
  - **세이브권**: 지나간 결석을 복구.
  - 클럽 멤버 여부에 따라 잔여 개수 표시 또는 잠금 아이콘 표시.
- **루틴 리스트**:
  - 개별 루틴 카드 (아이콘, 카테고리, 제목).
  - **체크 버튼**: 완료/미완료 토글. 비동기 처리 (`turbo_stream`).
  - **미완료 시**: 클릭하여 완료하거나, 아이템 사용 모달(`pass-confirm`) 호출 가능.

### 3.6. 클럽 라운지 (Club Lounge)

- **배너**: 루파 클럽 멤버 전용 공간(Live 세션 등)으로 이동.
- **참여자 미리보기**: 라운지에 참여 중인 유저 프로필(Facepile) 노출.

### 3.7. 호스트 센터 (Host Content)

- 호스트 권한이 있고 개설한 챌린지가 있을 경우에만 노출.
- 운영 중인 챌린지 개수 요약 및 호스트 센터 바로가기.

### 3.8. 참여 중인 챌린지 (Joined Challenges)

- 가로 스크롤 카드 형태.
- 각 챌린지의 진행률, D-Day, 상태 표시.

### 3.9. 글로벌 & 레이아웃 기능 (Global & Layout Features) - `layouts/prototype.html.erb`

홈페이지뿐만 아니라 서비스 전반에 걸쳐 제공되는 핵심 기능들입니다.

- **Global Navigation (Bottom Tab Bar)**:
  - `Home`, `Explore`, `Synergy`, `My` 탭으로 구성.
  - **Master FAB (+) Button**: 중앙에 위치하여 주요 생성 액션(루틴, 챌린지, 모임) 메뉴를 호출.
- **FAB Menu Sheet (`#fab-menu-sheet`)**:
  - 루틴 만들기, 챌린지 만들기, 모임 만들기 메뉴 제공.
  - **레벨/멤버십 제한**: 챌린지/모임 개설은 Lv.10 이상 또는 클럽 멤버만 가능하도록 제어 (Premium Nudge).
  - **멤버십 혜택 확인**: 클럽 멤버인 경우 멤버십 혜택 요약 카드로 대체 노출.
- **Global Modals**:
  - `#premium-item-nudge`: 멤버십 전용 기능 접근 시 업셀링 모달.
  - `#record-sheet`: 루틴 기록 작성용 바텀 시트.
  - `#commitment-sheet`: 하루 다짐 작성용 바텀 시트.
  - `#term-modal`, `#privacy-modal`: 약관 및 개인정보 처리방침.
  - `#badge-celebration`: 획득한 배지를 축하하는 연쇄 팝업 (Confetti 효과).
  - `#rufa-pending-modal`: 클럽 가입 승인 대기 중 안내.
  - `#membership-master-modal`: 클럽 멤버 전용 혜택 및 아이템 관리 통합 팝업.
  - `#club-welcome-celebration`: 클럽 가입 승인 완료 시 최초 1회 환영 팝업.
- **Flash Messages**: `flash-alert`, `flash-notice`를 메타 태그로 렌더링하여 JS(`toast` controller)에서 토스트 메시지로 출력.
- **Daily Greeting (`_daily_greeting`)**: 로그인 시 하루 1회, 레벨 및 활동 요약을 보여주는 환영 모달.

## 4. 상세 기능 로직 (Detailed Feature Logic)

### 4.1. 데이터 로딩 (`PrototypeController#home` & `ApplicationController`)

1.  **Global Filters (`ApplicationController`)**:
    - `set_unviewed_badges`: 미확인 배지 로딩 -> `#badge-celebration` 렌더링.
    - `set_pending_welcome_membership`: 가입 승인된 멤버십 로딩 -> `#club-welcome-celebration` 렌더링.
    - `set_time_zone`: 사용자별 타임존 설정 적용.
2.  **권한 확인**: `PermissionService`를 통해 클럽 멤버십 여부(`@is_club_member`) 확인.
3.  **공식 클럽 데이터**: 사용자가 속한 공식 클럽(`@official_club`) 및 멤버십 정보 로드.
4.  **루틴 데이터**:
    - `personal_routines`: 요일별 설정(`days`)을 파싱하여 오늘 수행해야 할 루틴 필터링.
    - `participations`: 현재 진행 중인 챌린지 참여 내역 필터링.
5.  **진행률 계산**:
    - `@progress`: (오늘 완료한 루틴 수 / 전체 루틴 수) \* 100.
    - `@aura_tasks`: 루틴과 챌린지를 통합하여 시각화 데이터 생성.
6.  **글로벌 스탯**:
    - `@orbit_users`: 오늘 활동 기록(`rufa_activities`)이 있는 유저.
    - `@global_average_progress`: 전체 클럽 멤버의 평균 달성률(캐싱 적용).

### 4.2. 클라이언트 인터랙션 (`proto_ui_controller.js`)

- **로그인 체크 (`checkLogin`)**:
  - `data-logged-in` 속성 확인.
  - 로그인하지 않은 상태에서 액션(좋아요, 기록 등) 시도 시 로그인 페이지로 리다이렉트.
- **인증 심화 (Advanced Auth)** (`SessionsController`):
  - **계정 복구 (Restoration)**: 탈퇴한 계정 이메일로 재가입 시도 시, 복구 프로세스로 유도 (`restore_account`).
  - **온보딩 (Onboarding)**: 신규 가입자에게만 온보딩 모달(`complete_onboarding`) 노출.
  - **Dev Login**: 개발 환경(`Rails.env.development?`)에서 테스트 계정 원클릭 로그인 지원.
- **프로필 관리 (Profile Management)** (`ProfilesController`, `my.html.erb`):
  - **호스트 스탯**: 개최한 챌린지 수, 총 참여자, 대기 중인 인증/신청 건수 요약.
  - **계좌 정보 저장**: 환급/용돈 받기용 계좌 정보(은행, 번호, 예금주) 암호화 저장 및 불러오기 (`save_account`).
  - **회원 탈퇴**: 진행 중인 챌린지/호스팅이 없을 때만 가능. Soft Delete(`deleted_at`) 처리 및 세션 초기화.
- **모달 관리 (`openModal`, `closeModal`)**:
  - `hidden` 클래스 토글 및 `body` 스크롤 제어 (`overflow-hidden`).
- **FAB (Floating Action Button)**:
  - 글로벌 메뉴 토글 기능.

### 4.3. 주요 모달 (Modals)

- **Global Pass Manager (`#global-pass-modal`)**:
  - 날짜 선택(과거/오늘/미래)에 따라 사용 가능한 아이템(휴식권/세이브권) 활성화/비활성화.
  - 아이템 사용 시 폼 제출.
- **Club Rules (`#club-rules-modal`)**:
  - 경고 및 제명 규정 안내.
- **Notification Modals**:
  - 클럽 가입 완료, 챌린지 개설 완료 등 특정 파라미터(`params[:joined_club]`) 존재 시 자동 팝업.
- **Global Update Notice**:
  - 쿠키(`update_notice_seen_YYYYMMDD`)를 확인하여 공지사항 팝업 노출 제어.

### 4.4. 루파 클럽 시스템 (Rufa Club System)

루틴 파인더스의 핵심 유료 멤버십 서비스인 '루파 클럽'의 기능 명세입니다.

#### 4.4.1. 멤버십 가입 및 관리 (`PrototypeController#club_join`)

- **기수제 운영**: 2개월 단위로 기수(Generation)가 운영되며, 정해진 모집 기간(D-15 ~ D+5)에만 가입 가능.
- **가입 프로세스**:
  1.  **Sales Page**: 이번 기수(`@recruiting_gen`)의 혜택, 기간, 가격(일 300원), 규정 안내.
  2.  **신청 폼**: 입금자명, 연락처, Threads ID, 가입 포부 입력 및 계좌번호 확인.
  3.  **승인 대기**: 신청 후 `payment_status: :pending` 상태. 호스트가 입금 확인 후 승인(`confirmed`)해야 정식 멤버 전환.
- **운영 규정 (Rules)**:
  - **3-Strike System**: 월간 경고 3회 누적 시 자동 제명 (`RoutineClubMember#check_kick_condition!`).
  - **주간 점검**: 매주 루틴 달성률 70% 미만 시 경고 부여 (`check_weekly_performance!`).

#### 4.4.2. 클럽 라운지 (`PrototypeController#live`)

멤버십 회원 전용의 실시간 소통 및 활동 공간입니다. (`live.html.erb`)

- **Dashboard**:
  - **Today's Vitality**: 클럽 멤버들의 오늘 평균 루틴 달성률 실시간 집계.
  - **Season Pace**: 시즌 누적 평균 출석률.
- **Live/Lecture Rooms**:
  - **Live Room**: Zoom 등 실시간 공동 몰입 세션 링크 제공 (호스트가 활성화 시 노출).
  - **Lecture Room**: 멤버 전용 특강/인사이트 세션 링크 제공.
- **Hall of Fame**: 현재 활동 중인 정예 멤버 리스트(Facepile).
- **Communication**: 공식 오픈채팅방 링크 제공.
- **Notice**: 클럽 공식 공지사항(`RoutineClubAnnouncement`) 최근 게시글 노출.

#### 4.4.3. 클럽 관리자 (Admin Dashboard - `PrototypeController#club_management`)

호스트 및 관리자가 클럽을 운영하기 위한 통합 대시보드입니다.

- **회원 관리 (Members)**:
  - **승인 대기 목록**: 입금 내용(예금주, 금액) 확인 후 승인/거부 처리.
  - **회원 현황표**: 전체 회원의 주간/월간 달성률, 출석률 조회 및 정렬(Sortable).
  - **페널티 관리**: 특정 회원에게 경고 부여(`warn!`) 또는 강제 제명(`kick!`) 기능.
- **라운지 설정 (Lounge)**:
  - Live Room 및 Lecture Room의 제목, 설명, 링크, 활성화 여부 실시간 제어.
- **공지사항 (Announcements)**:
  - 공지 작성, 수정, 삭제 기능. 작성 시 라운지에 즉시 반영.
- **클럽 설정 (Settings)**:
  - 기본 정보(타이틀, 설명), 계좌 정보, 운영 임계치(휴식권 개수, 제명 기준 등) 설정.

### 4.5. 개인 루틴 시스템 (Personal Routine System)

사용자가 일상적인 습관을 관리하고 성장을 기록하는 핵심 기능입니다. (`PersonalRoutinesController`)

- **루틴 생성/관리 (Routine Builder)**:
  - **Categories**: HEALTH, LIFE, MIND, HOBBY, STUDY, MONEY (6종).
  - **Icons**: 23종의 커스텀 이모지 아이콘 지원.
  - 요일별(Mon-Sun) 반복 설정, 카테고리(Health, Study 등), 아이콘/색상 커스터마이징.
  - **Routine Template**: 전문가 추천 루틴(템플릿)을 원클릭으로 내 루틴에 복사 (`RoutineTemplatesController`).
  - **Goal Tracking**: 주간/월간/연간 목표 설정 및 달성률 시각화.
- **실시간 기록 (Toggle Check)**:
  - 당일 루틴만 체크 가능 (과거/미래 불가).
  - 체크 시 `VerificationLog` 생성 및 `UserBadge` 획득 조건 실시간 체크 (`BadgeService`).
  - **Streak System**: 연속 달성일(Current Streak) 계산 및 불꽃 아이콘 표시.
- **성장 분석 (Growth Analytics)**:
  - 주간/월간/연간 달성률 그래프 제공.
  - 카테고리별 누적 달성 횟수(Identity Wallet) 시각화.

### 4.6. 챌린지 & 모임 시스템 (Challenge & Gathering System)

사용자들이 함께 목표를 달성하거나 오프라인에서 만나는 소셜 기능입니다. (`ChallengesController`, `GatheringsController`)

- **챌린지 빌더 (Challenge Builder)**:
  - **인증 타입**: 사진 인증(Camera), 간편 인증(Check), 수치 기록(Metric), 링크 제출(URL).
  - **은행 목록**: 주요 시중은행(신한, 국민, 토스 등) 7종 지원.
- **챌린지 (Online)**:
  - **유형**: 기상, 운동, 독서 등 온라인 인증 기반.
  - **인증 방식**: 사진 인증, 수치 기록, 링크 제출 등 다양한 타입 지원.
  - **검증 시스템**: 호스트 승인 필요 여부(`mission_requires_host_approval`) 설정 가능.
  - **보증금/환급**: 100% 달성 시 전액 환급 + 상금(실패자 벌금 배분) 로직 (`Pot System`).
  - **리뷰 시스템 (Reviews)**: 참여자만 작성 가능, 1인 1회, 수정 횟수 제한(2회), 호스트 답글 기능 (`ReviewsController`).
- **모임 (Offline Gathering)**:
  - **위치 기반**: 지도/장소 정보(`MeetingInfo`) 제공.
  - **모집 관리**: 선착순/승인제 모집, 참가비 결제.
- **호스트 센터 (Host Center)** (`HostedChallengesController`):
  - **Dashboard**: 실시간 인증 현황, 정산 시뮬레이션(예상 상금/보너스), 7일간의 트렌드 그래프.
  - **Batch Actions**: 인증 로그 및 참가 신청서 일괄 승인/거절 기능.
  - **Nudge System**: 미인증자, 저조한 멤버, 전체 멤버 등 타겟 그룹별 독려 메시지 발송.
  - **Edit Logic**: 중요 정보 수정 시 변경 내역(Change Log) 트래킹 및 참가자 자동 공지.

### 4.7. 커뮤니티 & 시너지 (Community & Synergy)

사용자 간의 동기 부여와 경쟁을 유도하는 게이미피케이션 요소입니다. (`PrototypeController#synergy`)

- **명예의 전당 (Hall of Fame)**:
  - 주간/월간 활동 점수(`rufa_club_score`) 기준 상위 유저 랭킹 표시.
  - 클럽 멤버와 일반 유저를 구분하여 리스트업.
- **피드 (Synergy Feed)**:
  - 다른 유저의 루틴 완료, 배지 획득, 챌린지 달성 소식을 실시간 타임라인으로 제공.
  - '응원하기' 기능을 통해 상호작용 유도.
- **배지 시스템 (Badge System)**:
  - 활동(최초 가입, 100회 달성, 7일 연속 등)에 따른 배지 자동 수여 및 콜렉션 제공.

### 4.8. 랭킹 시스템 (Ranking System)

다양한 활동 지표를 기반으로 유저 간의 선의의 경쟁을 유도하는 시스템입니다. (`RankingsController`, `PrototypeController#synergy`)

- **주간 랭킹 (Weekly Ranking)**:
  - 매주 월요일~일요일 사이 승인된 인증 로그 수로 산정.
- **명예의 전당 (Hall of Fame)**:
  - 누적 인증 수 기준 전체 랭킹.
- **배지 랭킹 (Badge Ranking)**:
  - 획득한 배지 개수 및 가입일(동점자 처리) 기준.
- **카테고리별 랭킹**:
  - **챌린지 (Online)**: 참여 횟수, 평균 달성률 등을 종합 점수화.
  - **루틴 (Routine)**: 누적 완료 수 및 Streak 합산.
  - **모임 (Gathering)**: 오프라인 모임 참여 횟수 기준.
- **호스트 랭킹 (Host Ranking)**:
  - 개설 챌린지의 참여자 수, 완료율, 개설 수를 종합하여 호스트 등급 산정.

### 4.9. 통합 관리자 시스템 (Super Admin System)

서비스 전체를 관제하는 슈퍼 관리자 전용 대시보드입니다. (`Admin::DashboardController`)

- **대시보드 (Dashboard)**:
  - **Core Stats**: 전체 유저 수, 신규 가입, 활성 챌린지 등 핵심 지표 모니터링.
  - **Action Center**: 입금 확인, 인증 승인 대기 등 관리자 개입이 필요한 항목 카운트.
  - **Revenue (매출 관리)**: 월간 매출 추세 및 성장률 확인.
- **배너 관리 (Banner Management)**:
  - 메인/광고 배너 업로드, 우선순위 조절, 활성화 여부 토글 (`Admin::BannersController`).

### 4.10. PWA 및 알림 시스템 (PWA & Notification)

사용자 재방문(Retention)을 유도하는 기술적 장치입니다. (`PwaController`, `WebPushService`)

- **PWA (Progressive Web App)**:
  - `manifest.json`: 앱 설치(A2HS) 지원.
  - `service-worker.js`: 오프라인 페이지(`offline.html`) 제공 및 캐싱 전략.
- **푸시 알림 (Web Push)**:
  - **VAPID Protocol**: 브라우저 표준 푸시 프로토콜 사용.
  - **스마트 알림**:
    - **Nudge**: 호스트가 참여자에게 보내는 "콕 찌르기" 알림.
    - **System**: 가입 승인, 챌린지 시작 등 시스템 이벤트 알림.

### 4.11. 리포트 시스템 (Reporting System)

데이터 기반의 피드백을 통해 사용자의 지속적인 성장을 돕습니다. (`RoutineClubReportsController`)

- **기간별 리포트 (Weekly/Monthly)**:
  - `RoutineClubReportService`를 통해 자동 생성.
  - **Log Rate (성실도)** vs **Achievement Rate (효율성)** 2축 분석.
  - **Identity Title**:
    - **빈틈없는 완벽주의자 (90/90)**: 성실도 90% + 달성률 90% 이상.
    - **성실한 루틴 마스터**: 달성률 80% 이상.
    - **끈기있는 개척자**: 성실도 80% 이상.
    - 그 외: **성장하는 가이드**, **잠재력 넘치는 도전자**.
  - **Peak Time Analysis**: 주 활동 시간대를 분석하여 맞춤형 코멘트 제공.

### 4.12. API 시스템 (API System)

모바일 앱 및 외부 클라이언트 연동을 위한 RESTful API를 제공합니다. (`Api::V1`)

- **Authentication**: 세션 기반 인증 (`POST /api/v1/login`, `DELETE /logout`).
- **User Data**: 유저 정보, 지갑 잔액, 참여 통계 조회 (`GET /me`).
- **Feature APIs**: 챌린지, 루틴, 인증 로그, 알림 등 주요 기능에 대한 CRUD Endpoints 제공.

### 4.13. 루틴 로드맵 (Routine Roadmap)

초보 사용자가 쉽게 루틴을 형성할 수 있도록 돕는 가이드 시스템입니다. (`RoutineRoadmapHelper`)

- **단계별 추천 (Levels)**:
  - **SEED(씨앗)**: 아주 쉬운 시작 (e.g., 물 한 잔, 이불 정리).
  - **SPROUT(새싹)**: 조금 더 발전된 습관 (e.g., 스트레칭 10분, 내일 할 일 적기).
  - **TREE(나무)**: 본격적인 몰입 (e.g., 스쿼트 50개, 독서 30분).
- **6대 영역**: HEALTH, LIFE, MIND, STUDY, HOBBY, MONEY 카테고리별 추천 로드맵 제공.

### 4.14. 기타 유틸리티 (Other Utilities)

서비스 운영 및 유지보수를 위한 부가 기능들입니다.

- **Admin Broadcast**: 전체 유저에게 시스템 공지 또는 푸시 알림 일괄 전송 (`Admin::DashboardController#broadcast`).
- **Cache Purge**: 관리자 권한으로 서버 캐시 강제 초기화.
- **User Reset**: (개발용) 유저 데이터를 초기 상태로 리셋.
- **Public Profile (`user_card`)**: 다른 유저의 프로필, 배지 컬렉션, 최근 활동 내역 조회.

### 4.15. 백그라운드 처리 및 자동화 (Background Processing & Automation)

서비스의 무결성과 연속성을 보장하는 배치 작업 및 비동기 프로세스입니다. (`lib/tasks`, `app/jobs`)

- **Daily Scheduler (`challenges:process_daily`)**:
  - **Daily Reset**: 모든 참가자의 `today_verified` 상태 초기화 (자정).
  - **Status Update**: 챌린지 및 모임의 상태(진행중/종료) 자동 변경.
  - **End Processing**: 종료된 챌린지의 최종 달성률 계산, 환급액 산정, 종료 알림 발송.
  - **Review Reminder**: 어제 종료된 챌린지 참가자에게 후기 작성 독려 알림 발송.
- **Club Management Jobs**:
  - `ClubPerformanceCheckJob`: 매주 월요일, 클럽 멤버의 주간 달성률 체크 및 경고 부여.
  - `ClubPushNotificationJob`: 클럽 공지사항 등록 시 전체 멤버에게 비동기 푸시 발송.
- **Report Generation Job**:
  - `GenerateRoutineClubReportsJob`: 매주/매월 초 리포트 자동 생성 및 발행.

## 5. 기술 스택 및 파일 구조 (Tech Stack)

- **Controller**: `app/controllers/prototype_controller.rb`
- **View**: `app/views/prototype/home.html.erb`
- **Partial**: `app/views/prototype/_garden.html.erb` (Digital Garden Visualization)
- **Styling**: TailwindCSS (Utility classes) & Custom Animations (`animate-shimmer`, `aura-float`).
- **JavaScript**: Hotwired Stimulus (`proto_ui_controller.js`).
- **Interaction**: Turbo Drive & Turbo Stream (for partial updates like toggling routines).
