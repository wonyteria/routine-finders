# Google OAuth 로그인 설정 가이드

## 1. Google Cloud Console 설정

### 1-1. 프로젝트 생성 (없는 경우)
1. https://console.cloud.google.com 접속
2. 상단의 프로젝트 선택 → **새 프로젝트** 클릭
3. 프로젝트 이름: `Routine Finders` 입력
4. **만들기** 클릭

### 1-2. OAuth 동의 화면 구성
1. 왼쪽 메뉴 → **API 및 서비스** → **OAuth 동의 화면**
2. User Type: **외부** 선택 → **만들기**
3. 앱 정보 입력:
   - 앱 이름: `Routine Finders`
   - 사용자 지원 이메일: 본인 이메일
   - 앱 로고: (선택사항)
   - 앱 도메인:
     - 홈페이지: `https://www.routinefinders.life`
     - 개인정보처리방침: `https://www.routinefinders.life/privacy`
     - 서비스 약관: `https://www.routinefinders.life/terms`
   - 승인된 도메인:
     - `routinefinders.life` 추가
   - 개발자 연락처 정보: 본인 이메일
4. **저장 후 계속** 클릭

5. 범위 설정:
   - **범위 추가 또는 삭제** 클릭
   - 다음 항목 선택:
     - ✅ `.../auth/userinfo.email`
     - ✅ `.../auth/userinfo.profile`
   - **업데이트** → **저장 후 계속**

6. 테스트 사용자 (선택사항):
   - 개발 중에는 본인 이메일 추가
   - **저장 후 계속**

7. 요약 확인 → **대시보드로 돌아가기**

### 1-3. OAuth 클라이언트 ID 생성
1. 왼쪽 메뉴 → **사용자 인증 정보**
2. 상단 **+ 사용자 인증 정보 만들기** → **OAuth 클라이언트 ID**
3. 애플리케이션 유형: **웹 애플리케이션**
4. 이름: `Routine Finders Web`
5. 승인된 자바스크립트 원본:
   - `http://localhost:3000` (개발용)
   - `https://www.routinefinders.life` (프로덕션)
6. 승인된 리디렉션 URI:
   - `http://localhost:3000/auth/google_oauth2/callback` (개발용)
   - `https://www.routinefinders.life/auth/google_oauth2/callback` (프로덕션)
7. **만들기** 클릭

8. 생성된 **클라이언트 ID**와 **클라이언트 보안 비밀** 복사
   - 클라이언트 ID: `xxxxx.apps.googleusercontent.com` 형식
   - 클라이언트 보안 비밀: `GOCSPX-xxxxx` 형식

### 1-4. API 활성화
1. 왼쪽 메뉴 → **API 및 서비스** → **라이브러리**
2. 검색: `Google+ API` 또는 `People API`
3. **사용 설정** 클릭

---

## 2. 환경 변수 설정

### 로컬 개발 환경 (.env 파일)
```bash
GOOGLE_CLIENT_ID=your_client_id.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=GOCSPX-your_client_secret
```

### 프로덕션 환경 (.kamal/secrets 파일)
```bash
export GOOGLE_CLIENT_ID="your_client_id.apps.googleusercontent.com"
export GOOGLE_CLIENT_SECRET="GOCSPX-your_client_secret"
```

### deploy.yml에 추가
```yaml
env:
  secret:
    - RAILS_MASTER_KEY
    - KAKAO_CLIENT_SECRET
    - THREADS_CLIENT_SECRET
    - GOOGLE_CLIENT_SECRET  # 추가
  clear:
    KAKAO_CLIENT_ID: "..."
    THREADS_CLIENT_ID: "..."
    GOOGLE_CLIENT_ID: "your_client_id.apps.googleusercontent.com"  # 추가
```

---

## 3. 테스트

### 로컬 테스트
1. 개발 서버 실행: `rails server`
2. http://localhost:3000 접속
3. 로그인 모달 열기
4. **Google로 시작하기** 버튼 클릭
5. Google 계정 선택 및 권한 승인
6. 로그인 성공 확인

### 프로덕션 테스트
1. 배포 후 https://www.routinefinders.life 접속
2. 동일한 과정으로 테스트

---

## 문제 해결

### "redirect_uri_mismatch" 오류
- Google Cloud Console의 리디렉션 URI가 정확한지 확인
- 프로토콜(http/https), 도메인, 경로가 모두 일치해야 함

### "Access blocked" 오류
- OAuth 동의 화면이 올바르게 설정되었는지 확인
- 테스트 사용자에 본인 이메일이 추가되었는지 확인

### "invalid_client" 오류
- GOOGLE_CLIENT_ID와 GOOGLE_CLIENT_SECRET이 올바른지 확인
- 환경 변수가 제대로 로드되었는지 확인
