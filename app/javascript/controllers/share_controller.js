import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="share"
export default class extends Controller {
    static values = {
        title: String,
        text: String,
        url: String
    }
    static targets = ["modal", "urlInput", "copyButton"]

    share(event) {
        if (event) event.preventDefault()

        const url = this.urlValue || window.location.href

        // 모달 표시
        this.showModal(url)
    }

    showModal(url) {
        // 모달 HTML 동적 생성
        const modal = document.createElement('div')
        modal.className = 'fixed inset-0 z-[1000] flex items-center justify-center p-6 bg-black/80 backdrop-blur-sm'
        modal.innerHTML = `
            <div class="bg-white rounded-[32px] w-full max-w-md p-8 space-y-6 animate-slide-up shadow-2xl">
                <div class="text-center space-y-2">
                    <div class="w-16 h-16 bg-indigo-500/10 rounded-[24px] flex items-center justify-center mx-auto">
                        <span class="text-3xl">🔗</span>
                    </div>
                    <h3 class="text-2xl font-black text-slate-900">링크 공유하기</h3>
                    <p class="text-sm font-bold text-slate-500">아래 주소를 복사하여 공유하세요</p>
                </div>
                
                <div class="space-y-3">
                    <div class="relative">
                        <input type="text" 
                               value="${url}" 
                               readonly 
                               class="w-full px-4 py-4 bg-slate-50 border-2 border-slate-200 rounded-2xl text-sm font-bold text-slate-700 focus:outline-none focus:border-indigo-500 transition-all"
                               onclick="this.select()">
                    </div>
                    
                    <button onclick="navigator.clipboard.writeText('${url}').then(() => {
                                this.innerHTML = '✅ 복사 완료!';
                                this.classList.remove('bg-indigo-600', 'hover:bg-indigo-700');
                                this.classList.add('bg-emerald-600');
                                setTimeout(() => {
                                    this.closest('.fixed').remove();
                                }, 1500);
                            })"
                            class="w-full py-4 bg-indigo-600 hover:bg-indigo-700 text-white rounded-2xl font-black text-sm transition-all shadow-lg active:scale-95">
                        📋 클립보드에 복사하기
                    </button>
                    
                    <button onclick="this.closest('.fixed').remove()"
                            class="w-full py-3 bg-slate-100 hover:bg-slate-200 text-slate-600 rounded-2xl font-bold text-sm transition-all">
                        닫기
                    </button>
                </div>
            </div>
        `

        document.body.appendChild(modal)

        // 모달 외부 클릭시 닫기
        modal.addEventListener('click', (e) => {
            if (e.target === modal) {
                modal.remove()
            }
        })
    }
}
