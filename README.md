# 🌿 Routine Finders (루틴 파인더스)

> **함께 습관을 만들어가는 루틴 챌린지 플랫폼**

루틴 파인더스는 개인의 성장을 돕고, 함께 도전하며 성취하는 즐거움을 나누는 루틴 관리 및 챌린지 플랫폼입니다.

[![Ruby](https://img.shields.io/badge/Ruby-3.4.0-red.svg)](https://www.ruby-lang.org/)
[![Rails](https://img.shields.io/badge/Rails-8.1.1-red.svg)](https://rubyonrails.org/)
[![License](https://img.shields.io/badge/License-Private-blue.svg)]()

---

## 📱 주요 기능

### 🎯 개인 루틴 관리
- 나만의 데일리 루틴 생성 및 관리
- 요일별 루틴 설정
- 루틴 완료 기록 및 통계
- 성취 지도 (캘린더 뷰)

### 🏆 챌린지 시스템
- 온라인/오프라인 챌린지 개설
- 보증금 기반 동기부여 시스템
- 실시간 인증 및 검증
- 참여자 랭킹 및 통계

### 👥 루파 클럽 (프리미엄 멤버십)
- 레벨 제한 없이 챌린지/모임 개설 가능
- 전용 패스 시스템 (휴식권, 세이브권)
- 주간/월간 성과 리포트 자동 생성
- 성장 포인트 적립

### ✨ 시너지 피드
- 멤버들의 성취 공유
- 응원 및 격려 시스템
- 실시간 활동 피드

### 🏅 배지 & 레벨 시스템
- 다양한 성취 배지
- 레벨 기반 권한 시스템
- 마일스톤 추적

---

## 🛠️ 기술 스택

### Backend
- **Ruby** 3.4.0
- **Rails** 8.1.1
- **SQLite3** (개발/프로덕션)
- **Solid Queue** (백그라운드 작업)
- **Solid Cache** (캐싱)

### Frontend
- **Hotwire** (Turbo + Stimulus)
- **TailwindCSS** 3.x
- **Importmap** (JavaScript 관리)

### Authentication
- **OmniAuth** (소셜 로그인)
  - 카카오 로그인
  - 구글 로그인
  - Threads 로그인

### Security
- **Rack::Attack** (Rate Limiting)
- 파일 업로드 검증 (Magic Number)
- CSRF 보호

### Deployment
- **Kamal** 2.0 (Docker 기반 배포)
- **Thruster** (HTTP 캐싱/압축)
- **GitHub Actions** (CI/CD)

---

## 🚀 시작하기

### 필수 요구사항

- Ruby 3.4.0 이상
- Node.js 18.x 이상
- SQLite3

### 설치

```bash
# 저장소 클론
git clone https://github.com/wonyteria/routine-finders.git
cd routine-finders

# 의존성 설치
bundle install

# 환경변수 설정
cp .env.example .env
# .env 파일을 열어 OAuth 키 등을 설정하세요

# 데이터베이스 설정
rails db:create
rails db:migrate
rails db:seed

# 개발 서버 실행
./bin/dev
```

서버가 실행되면 `http://localhost:3000`에서 확인할 수 있습니다.

### 프로토타입 앱 접속

프로토타입 앱은 `/prototype` 경로로 접속할 수 있습니다:
- 홈: `http://localhost:3000/prototype/home`
- 탐색: `http://localhost:3000/prototype/explore`
- 로그인: `http://localhost:3000/prototype/login`

---

## 📁 프로젝트 구조

```
routine-finders/
├── app/
│   ├── controllers/
│   │   ├── prototype_controller.rb    # 프로토타입 앱 메인 컨트롤러
│   │   ├── challenges_controller.rb   # 챌린지 관리
│   │   └── ...
│   ├── models/
│   │   ├── user.rb                    # 사용자 모델
│   │   ├── challenge.rb               # 챌린지 모델
│   │   ├── participant.rb             # 참여자 모델
│   │   └── ...
│   ├── services/                      # 비즈니스 로직 서비스
│   │   ├── challenge_participation_service.rb
│   │   ├── routine_club_report_service.rb
│   │   └── file_upload_validator.rb
│   ├── views/
│   │   ├── layouts/
│   │   │   └── prototype.html.erb     # 프로토타입 레이아웃
│   │   ├── prototype/                 # 프로토타입 뷰
│   │   └── ...
│   └── javascript/
│       └── controllers/               # Stimulus 컨트롤러
├── config/
│   ├── initializers/
│   │   └── rack_attack.rb            # Rate Limiting 설정
│   └── deploy.yml                    # Kamal 배포 설정
└── db/
    ├── migrate/                      # 마이그레이션 파일
    └── seeds.rb                      # 시드 데이터
```

---

## 🔐 환경변수 설정

`.env` 파일에 다음 환경변수를 설정하세요:

```env
# Google OAuth
GOOGLE_CLIENT_ID=your_google_client_id
GOOGLE_CLIENT_SECRET=your_google_client_secret

# Kakao OAuth
KAKAO_CLIENT_ID=your_kakao_client_id
KAKAO_CLIENT_SECRET=your_kakao_client_secret

# Threads OAuth (Optional)
THREADS_CLIENT_ID=your_threads_client_id
THREADS_CLIENT_SECRET=your_threads_client_secret

# Rails Master Key (프로덕션)
RAILS_MASTER_KEY=your_master_key
```

---

## 🧪 테스트

```bash
# 전체 테스트 실행
rails test

# 특정 테스트 파일 실행
rails test test/models/user_test.rb

# 시스템 테스트 실행
rails test:system
```

---

## 📦 배포

### Kamal을 사용한 배포

```bash
# 첫 배포
kamal setup

# 이후 배포
kamal deploy

# 로그 확인
kamal app logs

# 서버 상태 확인
kamal app details
```

### GitHub Actions

`main` 브랜치에 푸시하면 자동으로 배포됩니다.

---

## 🎨 디자인 시스템

### 색상 팔레트
- **Primary**: Indigo (#7C4DFF)
- **Success**: Emerald (#10B981)
- **Warning**: Amber (#F59E0B)
- **Danger**: Rose (#F43F5E)
- **Background**: Dark (#0C0B12)

### 타이포그래피
- **Font Family**: Pretendard (한글), Outfit (영문)
- **Font Weights**: 400 (Regular), 700 (Bold), 900 (Black)

---

## 🤝 기여하기

이 프로젝트는 개인 프로젝트이지만, 피드백과 제안은 언제나 환영합니다!

---

## 📄 라이선스

이 프로젝트는 비공개 프로젝트입니다. 무단 복제 및 배포를 금지합니다.

---

## 👨‍💻 개발자

**Cyberneum** - 루틴 파인더스 창립자 & 개발자

---

## 📞 문의

프로젝트에 대한 문의사항이 있으시면 이슈를 등록해주세요.

---

**Made with ❤️ by Routine Finders Team**
