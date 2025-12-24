# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 프로젝트 개요

루틴/챌린지 관리 서비스. 사용자는 온라인 챌린지에 참여하거나 오프라인 모임(gathering)에 참여할 수 있으며, 개인 루틴도 관리할 수 있다.

## 주요 명령어

```bash
# 개발 서버 (Rails + Tailwind watch)
bin/dev

# 테스트
bin/rails test              # 단위/통합 테스트
bin/rails test:system       # 시스템 테스트
bin/rails test test/models/user_test.rb  # 단일 테스트 파일

# 린트 및 보안 검사
bin/rubocop                 # 코드 스타일 검사
bin/brakeman                # 보안 취약점 분석
bin/bundler-audit           # Gem 보안 취약점 검사

# 데이터베이스
bin/rails db:migrate
bin/rails db:test:prepare   # 테스트 DB 준비
```

## 아키텍처

### 기술 스택
- Rails 8.1, Ruby 3.4.1
- SQLite (development/test/production)
- Hotwire (Turbo + Stimulus), Tailwind CSS
- Propshaft (asset pipeline)
- Solid Cache/Queue/Cable

### 도메인 모델

**User**: 사용자. 챌린지 호스트 또는 참가자 역할
- `hosted_challenges`: 주최한 챌린지들
- `participations`: 참여 정보 (Participant through)
- `personal_routines`: 개인 루틴들

**Challenge**: 온라인 챌린지 또는 오프라인 모임
- `mode`: online/offline (offline = gathering)
- `entry_type`: season/regular
- `cost_type`: free/fee/deposit
- `verification_type`: simple/metric/photo/url/complex
- `host`: User (belongs_to)
- `participants`, `verification_logs`, `meeting_info`(offline용)

**Participant**: 챌린지 참여 정보 (User-Challenge 조인 테이블)
- 참여 상태, 달성률, 연속 성공/실패 횟수 등 추적

**VerificationLog**: 챌린지 인증 기록
- 참가자가 제출한 인증 데이터 (이미지, 값, URL 등)

**PersonalRoutine**: 챌린지와 무관한 개인 루틴
- 요일별 설정(`days`), 연속 달성(`current_streak`) 추적

### API 구조

Web 컨트롤러와 API 컨트롤러 분리:
- Web: `app/controllers/*.rb` - 세션 기반 인증
- API: `app/controllers/api/v1/*.rb` - JSON 응답, `Api::V1::BaseController` 상속

인증: 세션 기반 (`session[:user_id]`). `current_user` 헬퍼 사용.

### 코드 스타일

RuboCop Rails Omakase 스타일 적용 (`.rubocop.yml`)
