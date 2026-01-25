# 🔌 Routine Finders API Documentation

> **프로토타입 앱 내부 API 엔드포인트 문서**

이 문서는 루틴 파인더스 프로토타입 앱에서 사용하는 주요 API 엔드포인트를 설명합니다.

---

## 📋 목차

- [인증](#인증)
- [루틴 관리](#루틴-관리)
- [챌린지](#챌린지)
- [루파 클럽](#루파-클럽)
- [시너지 피드](#시너지-피드)
- [알림](#알림)

---

## 🔐 인증

### OAuth 로그인

#### 카카오 로그인
```
POST /auth/kakao
```

#### 구글 로그인
```
POST /auth/google_oauth2
```

#### 로그아웃
```
DELETE /logout
```

**응답:**
```json
{
  "success": true,
  "message": "로그아웃되었습니다."
}
```

---

## 📝 루틴 관리

### 루틴 생성
```
POST /prototype/routine_builder
```

**요청 파라미터:**
```json
{
  "title": "아침 운동",
  "description": "매일 아침 30분 운동하기",
  "days": ["1", "2", "3", "4", "5"],
  "time": "07:00",
  "category": "HEALTH"
}
```

**응답:**
```json
{
  "success": true,
  "routine": {
    "id": 123,
    "title": "아침 운동",
    "created_at": "2026-01-26T00:00:00Z"
  }
}
```

### 루틴 완료 기록
```
POST /prototype/record
```

**요청 파라미터:**
```json
{
  "routine_id": 123,
  "completed": true,
  "note": "오늘도 완료!"
}
```

---

## 🏆 챌린지

### 챌린지 목록 조회
```
GET /prototype/explore?type=all&sort=recent
```

**쿼리 파라미터:**
- `type`: `all`, `challenges`, `gatherings`
- `sort`: `recent`, `popular`, `amount`

**응답:**
```json
{
  "challenges": [
    {
      "id": 1,
      "title": "30일 독서 챌린지",
      "current_participants": 15,
      "max_participants": 30,
      "amount": 10000,
      "recruitment_end_date": "2026-02-01"
    }
  ]
}
```

### 챌린지 참여
```
POST /challenges/:id/join
```

**응답:**
```json
{
  "success": true,
  "message": "챌린지에 참여했습니다!",
  "participant_id": 456
}
```

### 챌린지 인증
```
POST /challenges/:challenge_id/verification_logs
```

**요청 파라미터:**
```json
{
  "value": "오늘의 인증 내용",
  "image": "<file>"
}
```

---

## 👥 루파 클럽

### 멤버십 가입
```
POST /prototype/club_join
```

**요청 파라미터:**
```json
{
  "plan": "monthly",
  "payment_method": "card"
}
```

### 리포트 조회
```
GET /prototype/member_reports?type=weekly
```

**쿼리 파라미터:**
- `type`: `weekly`, `monthly`

**응답:**
```json
{
  "report": {
    "log_rate": 85.5,
    "achievement_rate": 78.2,
    "identity_title": "성실한 루퍼 ⭐",
    "summary": "이번 주 기록률 85.5%, 달성률 78.2%로 총 23개의 루틴을 완료했습니다.",
    "cheering_message": "훌륭합니다! 조금만 더 힘내면 완벽해요! 💪"
  }
}
```

### 패스 사용
```
POST /routine_club_members/:id/use_pass
```

**요청 파라미터:**
```json
{
  "pass_type": "relax"
}
```

---

## ✨ 시너지 피드

### 피드 조회
```
GET /prototype/synergy
```

**응답:**
```json
{
  "activities": [
    {
      "id": 1,
      "user": {
        "nickname": "루퍼123",
        "profile_image": "https://..."
      },
      "activity_type": "routine_record",
      "body": "오늘도 운동 완료!",
      "created_at": "2026-01-26T00:00:00Z",
      "claps_count": 5
    }
  ]
}
```

### 응원하기 (박수)
```
POST /activities/:id/clap
```

**응답:**
```json
{
  "success": true,
  "claps_count": 6
}
```

---

## 🔔 알림

### 알림 목록
```
GET /prototype/notifications
```

**응답:**
```json
{
  "notifications": [
    {
      "id": 1,
      "title": "새로운 배지 획득!",
      "content": "7일 연속 달성 배지를 획득했습니다.",
      "is_read": false,
      "created_at": "2026-01-26T00:00:00Z"
    }
  ],
  "unread_count": 3
}
```

### 알림 읽음 처리
```
POST /prototype/clear_notifications
```

---

## 📊 에러 응답

모든 API는 에러 발생 시 다음 형식으로 응답합니다:

```json
{
  "success": false,
  "error": "에러 메시지",
  "code": "ERROR_CODE"
}
```

### HTTP 상태 코드

- `200 OK`: 성공
- `201 Created`: 리소스 생성 성공
- `400 Bad Request`: 잘못된 요청
- `401 Unauthorized`: 인증 필요
- `403 Forbidden`: 권한 없음
- `404 Not Found`: 리소스 없음
- `422 Unprocessable Entity`: 검증 실패
- `429 Too Many Requests`: Rate Limit 초과
- `500 Internal Server Error`: 서버 오류

---

## 🔒 Rate Limiting

API 요청은 다음과 같이 제한됩니다:

- **일반 요청**: IP당 분당 60회
- **로그인 시도**: IP당 5분에 5회
- **파일 업로드**: IP당 분당 10회
- **콘텐츠 생성**: 사용자당 시간당 10회

Rate Limit 초과 시 `429` 상태 코드와 함께 다음 헤더가 반환됩니다:

```
RateLimit-Limit: 60
RateLimit-Remaining: 0
RateLimit-Reset: 1706227200
```

---

## 📝 참고사항

1. 모든 요청은 CSRF 토큰이 필요합니다.
2. 파일 업로드는 최대 10MB까지 가능합니다.
3. 이미지는 JPG, PNG, GIF, WebP 형식만 지원됩니다.
4. 날짜 형식은 ISO 8601 (`YYYY-MM-DD`) 을 사용합니다.

---

**Last Updated**: 2026-01-26
