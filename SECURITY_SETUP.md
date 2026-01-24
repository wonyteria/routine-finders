# 보안 설정 가이드

## ⚠️ 긴급 조치 필요

현재 Git 히스토리에 OAuth 시크릿이 노출되어 있습니다. 다음 조치를 **즉시** 수행하세요:

### 1. OAuth 시크릿 재발급

#### Kakao 개발자 콘솔
1. https://developers.kakao.com 접속
2. 앱 선택 → 앱 키 메뉴
3. **Client Secret 재발급** 클릭
4. 새로운 시크릿을 `.kamal/secrets` 파일에 저장

#### Threads/Meta 개발자 콘솔
1. https://developers.facebook.com 접속
2. 앱 선택 → 설정 → 기본 설정
3. **앱 시크릿 재설정** 클릭
4. 새로운 시크릿을 `.kamal/secrets` 파일에 저장

### 2. .kamal/secrets 파일 설정

`.kamal/secrets-example` 파일을 복사하여 실제 값을 입력하세요:

```bash
# .kamal/secrets 파일 편집
notepad .kamal\secrets
```

다음 값들을 입력하세요:
- `KAMAL_REGISTRY_PASSWORD`: GitHub Personal Access Token
- `RAILS_MASTER_KEY`: config/master.key 파일의 내용
- `KAKAO_CLIENT_SECRET`: 재발급받은 Kakao 시크릿
- `THREADS_CLIENT_SECRET`: 재발급받은 Threads 시크릿

### 3. 환경 변수 설정

배포 전에 다음 환경 변수를 설정하세요:

```bash
# PowerShell
$env:DEPLOY_HOST = "152.42.204.0"
```

### 4. Git 히스토리 정리 (선택사항)

⚠️ **주의**: 이 작업은 Git 히스토리를 다시 작성하므로 팀원과 협의 후 진행하세요.

```bash
# BFG Repo-Cleaner 사용 (권장)
# 1. https://rtyley.github.io/bfg-repo-cleaner/ 에서 다운로드
# 2. 실행
java -jar bfg.jar --replace-text passwords.txt

# 또는 git filter-branch 사용
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch config/deploy.yml" \
  --prune-empty --tag-name-filter cat -- --all
```

## 보안 체크리스트

- [ ] Kakao Client Secret 재발급 완료
- [ ] Threads Client Secret 재발급 완료
- [ ] `.kamal/secrets` 파일 생성 및 설정 완료
- [ ] `.kamal/secrets`가 `.gitignore`에 포함되어 있는지 확인
- [ ] `config/deploy.yml`에 평문 시크릿이 없는지 확인
- [ ] Git 히스토리 정리 (필요시)
- [ ] 변경사항 커밋 및 푸시

## 추가 보안 권장사항

### SSH 보안 강화
```bash
# 서버에 접속하여 일반 사용자 생성
ssh root@152.42.204.0
adduser deploy
usermod -aG sudo deploy

# SSH 키 기반 인증 설정
# config/deploy.yml에서 ssh user를 deploy로 변경
```

### 방화벽 설정
```bash
# UFW 방화벽 활성화
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw enable
```

### 정기 백업 설정
```bash
# SQLite 데이터베이스 백업 스크립트 설정
# cron job으로 매일 백업 실행
```

## 문제 해결

### "DEPLOY_HOST environment variable is not set" 오류
```bash
# 환경 변수 설정
$env:DEPLOY_HOST = "152.42.204.0"
```

### "Secret not found" 오류
`.kamal/secrets` 파일이 올바르게 설정되었는지 확인하세요.
