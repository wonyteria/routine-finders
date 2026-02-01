import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    connect() {
        this.checkInAppBrowser()
    }

    checkInAppBrowser() {
        const userAgent = navigator.userAgent.toLowerCase()
        const targetUrl = window.location.href

        // 인앱 브라우저 식별 (카카오, 네이버, 인스타그램, 페이스북, 라인, 밴드)
        const isInApp = /kakaotalk|naver|fban|fbav|instagram|line|band/i.test(userAgent)

        if (isInApp) {
            if (/android/i.test(userAgent)) {
                // 안드로이드: 크롬으로 강제 이동 시도
                // intent 스킴 사용
                const scheme = location.protocol === 'https:' ? 'https' : 'http';
                const urlWithoutScheme = targetUrl.replace(/^https?:\/\//, '');

                // 크롬으로 열기 Intent
                // S.browser_fallback_url은 크롬이 없을 경우 대비용 (현재 페이지 유지)
                const intentUrl = `intent://${urlWithoutScheme}#Intent;scheme=${scheme};package=com.android.chrome;S.browser_fallback_url=${targetUrl};end`;

                window.location.href = intentUrl;
            } else if (/iphone|ipad|ipod/i.test(userAgent)) {
                // iOS: 강제 이동 불가 -> 안내 모달 표시
                this.showGuideModal()
            }
        }
    }

    showGuideModal() {
        // 이미 모달이 있으면 중복 생성 방지
        if (document.getElementById('inapp-browser-guide')) return;

        const guideHtml = `
      <div id="inapp-browser-guide" style="position:fixed; top:0; left:0; width:100%; height:100%; z-index:99999; background:#0C0B12; display:flex; flex-direction:column; align-items:center; justify-content:center; text-align:center; padding:24px; color:white; font-family:'Outfit', sans-serif;">
        <div style="width:64px; height:64px; background:#4F46E5; border-radius:16px; display:flex; align-items:center; justify-content:center; margin-bottom:24px; box-shadow:0 10px 25px -5px rgba(79, 70, 229, 0.4);">
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="white" style="width:32px; height:32px;">
            <path stroke-linecap="round" stroke-linejoin="round" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
          </svg>
        </div>
        
        <h2 style="font-size:20px; font-weight:700; margin-bottom:12px; color:white;">외부 브라우저 이용 권장</h2>
        
        <p style="font-size:15px; line-height:1.6; color:#9ca3af; margin-bottom:32px; max-width:280px;">
          현재 브라우저(인앱)에서는 구글 보안 정책으로 인해 로그인이 제한될 수 있습니다.<br><br>
          <span style="color:#818cf8; font-weight:600;">Safari</span> 또는 <span style="color:#818cf8; font-weight:600;">Chrome</span> 앱으로 접속해주세요.
        </p>
        
        <div style="width:100%; max-width:320px; background:rgba(255,255,255,0.05); border:1px solid rgba(255,255,255,0.1); border-radius:12px; padding:16px; margin-bottom:32px;">
          <div style="display:flex; align-items:center; gap:12px; margin-bottom:12px; text-align:left;">
            <div style="width:24px; height:24px; background:rgba(255,255,255,0.1); border-radius:50%; display:flex; align-items:center; justify-content:center; font-size:12px; font-weight:bold;">1</div>
            <p style="font-size:14px; color:#e5e7eb;">화면 상단/하단의 <span style="display:inline-block; padding:0 6px; background:rgba(255,255,255,0.1); border-radius:4px; font-size:12px;">⋮</span> 또는 <span style="display:inline-block; padding:0 6px; background:rgba(255,255,255,0.1); border-radius:4px; font-size:12px;">⋯</span> 버튼 터치</p>
          </div>
          <div style="display:flex; align-items:center; gap:12px; text-align:left;">
            <div style="width:24px; height:24px; background:rgba(255,255,255,0.1); border-radius:50%; display:flex; align-items:center; justify-content:center; font-size:12px; font-weight:bold;">2</div>
            <p style="font-size:14px; color:#e5e7eb;">'다른 브라우저로 열기' 선택</p>
          </div>
        </div>

        <button data-action="click->inapp-browser#copyUrl" style="background:transparent; border:1px solid rgba(255,255,255,0.2); padding:12px 24px; border-radius:12px; color:white; font-size:14px; font-weight:500; display:flex; align-items:center; gap:8px;">
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" style="width:18px; height:18px;">
            <path stroke-linecap="round" stroke-linejoin="round" d="M15.75 17.25v3.375c0 .621-.504 1.125-1.125 1.125h-9.75a1.125 1.125 0 01-1.125-1.125V7.875c0-.621.504-1.125 1.125-1.125H6.75a9.06 9.06 0 011.5.124m7.5 10.376h3.375c.621 0 1.125-.504 1.125-1.125V11.25c0-4.46-3.243-8.161-7.5-8.876a9.06 9.06 0 00-1.5-.124H9.375c-.621 0-1.125.504-1.125 1.125v3.5m7.5 10.375H9.375a1.125 1.125 0 01-1.125-1.125v-9.25m12 6.625v-1.875a3.375 3.375 0 00-3.375-3.375h-1.5" />
          </svg>
          링크 복사하기
        </button>
        
        <button onclick="document.getElementById('inapp-browser-guide').remove()" style="margin-top:24px; font-size:13px; color:#6b7280; text-decoration:underline; border:none; background:none;">
          닫기
        </button>
      </div>
    `
        document.body.insertAdjacentHTML('beforeend', guideHtml)
    }

    copyUrl() {
        const url = window.location.href
        navigator.clipboard.writeText(url).then(() => {
            alert("링크가 복사되었습니다. 브라우저 주소창에 붙여넣어주세요.")
        }).catch(err => {
            console.error('Could not copy text: ', err)
            // 클립보드 API 실패 시 fallback (input 생성 후 선택)
            const textArea = document.createElement("textarea");
            textArea.value = url;
            document.body.appendChild(textArea);
            textArea.select();
            document.execCommand("Copy");
            textArea.remove();
            alert("링크가 복사되었습니다. 브라우저 주소창에 붙여넣어주세요.")
        })
    }
}
