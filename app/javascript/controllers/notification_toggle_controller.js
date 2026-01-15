import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["button", "indicator"]

    connect() {
        // 저장된 설정 불러오기
        this.isOn = localStorage.getItem('notifications_enabled') === 'true'
        this.updateUI()

        // 이미 권한이 있으면 UI 업데이트
        if (Notification.permission === 'granted') {
            this.isOn = true
            this.updateUI()
            localStorage.setItem('notifications_enabled', 'true')
        }
    }

    switch() {
        if (!this.isOn) {
            // 알림 켜기
            this.requestPermission()
        } else {
            // 알림 끄기
            this.isOn = false
            this.updateUI()
            localStorage.setItem('notifications_enabled', 'false')
            this.showToast('알림이 비활성화되었습니다')
        }
    }

    async requestPermission() {
        if (!('Notification' in window)) {
            alert('이 브라우저는 알림을 지원하지 않습니다.')
            return
        }

        try {
            const permission = await Notification.requestPermission()

            if (permission === 'granted') {
                this.isOn = true
                this.updateUI()
                localStorage.setItem('notifications_enabled', 'true')

                // 테스트 알림 표시
                this.showNotification(
                    '알림이 활성화되었습니다! 🎉',
                    '이제 중요한 업데이트를 받아보실 수 있습니다.'
                )

                this.showToast('알림이 활성화되었습니다')
            } else {
                this.isOn = false
                this.updateUI()
                this.showToast('알림 권한이 거부되었습니다')
            }
        } catch (error) {
            console.error('알림 권한 요청 실패:', error)
            this.showToast('알림 설정 중 오류가 발생했습니다')
        }
    }

    updateUI() {
        if (this.isOn) {
            // Turn ON
            this.buttonTarget.classList.remove("justify-end", "bg-slate-800")
            this.buttonTarget.classList.add("justify-start", "bg-indigo-500")
            this.indicatorTarget.classList.remove("bg-slate-600")
            this.indicatorTarget.classList.add("bg-white")
        } else {
            // Turn OFF
            this.buttonTarget.classList.remove("justify-start", "bg-indigo-500")
            this.buttonTarget.classList.add("justify-end", "bg-slate-800")
            this.indicatorTarget.classList.remove("bg-white")
            this.indicatorTarget.classList.add("bg-slate-600")
        }
    }

    showNotification(title, body) {
        if (Notification.permission === 'granted') {
            new Notification(title, {
                body: body,
                icon: '/icon.png',
                badge: '/badge.png',
                tag: 'routine-finders',
                requireInteraction: false
            })
        }
    }

    showToast(message) {
        // 간단한 토스트 메시지 (기존 시스템이 있다면 그것 사용)
        const toast = document.createElement('div')
        toast.className = 'fixed bottom-20 left-1/2 -translate-x-1/2 bg-white/90 backdrop-blur-xl text-slate-900 px-6 py-3 rounded-2xl shadow-2xl text-sm font-bold z-[400] animate-fade-in'
        toast.textContent = message
        document.body.appendChild(toast)

        setTimeout(() => {
            toast.classList.add('opacity-0', 'transition-opacity', 'duration-300')
            setTimeout(() => toast.remove(), 300)
        }, 2000)
    }
}
