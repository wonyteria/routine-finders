import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["toggle", "statusText", "guideModal"]
    static values = {
        vapidPublicKey: String
    }

    connect() {
        this.checkSubscription()
        this.checkHighlight()
    }

    checkHighlight() {
        if (window.location.hash === "#push-settings-section") {
            const element = document.getElementById("push-settings-section")
            if (element) {
                // Remove offset and use inset to prevent cutoff, added transition for smoothness
                element.classList.add("ring-2", "ring-indigo-500", "ring-inset", "bg-indigo-500/10", "transition-all", "duration-500")

                setTimeout(() => {
                    element.classList.remove("ring-2", "ring-indigo-500", "ring-inset", "bg-indigo-500/10")
                }, 3000)
            }
        }
    }

    async checkSubscription() {
        if (!('serviceWorker' in navigator) || !('PushManager' in window)) {
            this.updateUI(false, "지원하지 않는 브라우저입니다")
            return
        }

        const registration = await navigator.serviceWorker.ready
        const subscription = await registration.pushManager.getSubscription()

        this.updateUI(!!subscription)

        // Enable interaction once state is determined
        this.toggleTarget.disabled = false
    }

    // Main action triggered when clicking the row
    subscribe(event) {
        // Prevent default if clicking directly on the toggle to avoid double-firing if wrapped
        // but here the action is on the parent div.

        if (this.toggleTarget.disabled) return

        if (this.toggleTarget.checked) {
            // Currently ON, user wants to turn OFF
            this.unsubscribeProcess()
        } else {
            // Currently OFF, user wants to turn ON
            this.startSubscribeFlow()
        }
    }

    async unsubscribeProcess() {
        if (!confirm('푸시 알림을 해제하시겠습니까?')) return

        const registration = await navigator.serviceWorker.ready
        const subscription = await registration.pushManager.getSubscription()

        if (subscription) {
            // Sync with server first to ensure DB is updated
            await this.removeSubscriptionFromServer(subscription)
            // Then unsubscribe from browser
            await subscription.unsubscribe()
        }

        this.updateUI(false)
        alert('알림이 해제되었습니다.')
    }

    async removeSubscriptionFromServer(subscription) {
        return fetch('/pwa/subscribe', {
            method: 'DELETE',
            headers: {
                'Content-Type': 'application/json',
                'X-CSRF-Token': document.querySelector("[name='csrf-token']").content
            },
            body: JSON.stringify({
                endpoint: subscription.endpoint
            })
        }).catch(err => console.error('Server sync failed:', err))
    }

    startSubscribeFlow() {
        const isGuideDismissed = localStorage.getItem('push_guide_dismissed') === 'true'

        if (isGuideDismissed) {
            this.processSubscription()
        } else {
            this.openGuide()
        }
    }

    handleDeniedPermission(status) {
        this.updateUI(false)

        let message = '🚫 알림 권한이 차단되어 있습니다.\n\n'

        if (status === 'denied') {
            message += '휴대폰 설정에서 알림을 허용하셨음에도 이 창이 뜬다면:\n\n' +
                '1. 홈 화면의 [루틴파인더스] 앱 아이콘을 꾹 눌러주세요.\n' +
                '2. [i] 버튼 또는 [앱 정보]를 눌러주세요.\n' +
                '3. [알림] 설정을 껐다가 다시 켜보시거나, [저장공간 > 데이터 삭제]를 하시면 가장 확실하게 초기화됩니다.\n\n' +
                '※ 그래도 안 된다면 앱을 삭제 후 다시 설치(홈 화면에 추가)해주시면 해결됩니다.'
        } else {
            message += '알림 권한을 허용해야 서비스를 원활히 이용하실 수 있습니다.'
        }

        alert(message)
    }

    openGuide() {
        this.guideModalTarget.classList.remove('hidden')
        document.body.classList.add('overflow-hidden')
    }

    closeGuide() {
        this.guideModalTarget.classList.add('hidden')
        document.body.classList.remove('overflow-hidden')
    }

    confirmGuide() {
        this.closeGuide()
        this.processSubscription()
    }

    dontShowAgain() {
        localStorage.setItem('push_guide_dismissed', 'true')
        this.closeGuide()
        this.processSubscription()
    }

    async processSubscription() {
        try {
            // 1. Request Permission FIRST
            const permission = await Notification.requestPermission()

            if (permission !== 'granted') {
                this.handleDeniedPermission(permission)
                return
            }

            // 2. Prepare service worker
            const registration = await navigator.serviceWorker.ready

            // Clean up old subscriptions to prevent conflicts
            const existingSubscription = await registration.pushManager.getSubscription()
            if (existingSubscription) {
                try {
                    await existingSubscription.unsubscribe()
                } catch (e) {
                    console.warn('Unsubscribe error (safe to ignore):', e)
                }
            }

            if (!this.vapidPublicKeyValue) {
                alert('알림 서버 설정 오류(VAPID)')
                this.updateUI(false)
                return
            }

            let cleanKey = (this.vapidPublicKeyValue || "").replace(/[^A-Za-z0-9\+\/\-\_=]/g, '')
            let applicationServerKey
            try {
                applicationServerKey = this.urlBase64ToUint8Array(cleanKey)
            } catch (e) {
                alert('알림 시스템 초기화 실패')
                this.updateUI(false)
                return
            }

            // 3. Final Subscription
            const subscription = await registration.pushManager.subscribe({
                userVisibleOnly: true,
                applicationServerKey: applicationServerKey
            })

            await this.sendSubscriptionToServer(subscription)

            this.updateUI(true)
            alert('푸시 알림이 설정되었습니다! ✨')

        } catch (error) {
            console.error('Push setting crash:', error)
            alert(`알림 설정 실패: ${error.message}\n브라우저를 껐다 켜보시거나 잠시 후 다시 시도해주세요.`)
            this.updateUI(false)
        }
    }

    updateUI(isSubscribed, customText = null) {
        this.toggleTarget.checked = isSubscribed

        if (customText) {
            this.statusTextTarget.textContent = customText
        } else {
            this.statusTextTarget.textContent = isSubscribed
                ? "알림이 활성화되었습니다"
                : "휴대폰 알림으로 루틴을 잊지 마세요"

            if (isSubscribed) {
                this.statusTextTarget.classList.add('text-indigo-400')
                this.statusTextTarget.classList.remove('text-slate-500')
            } else {
                this.statusTextTarget.classList.remove('text-indigo-400')
                this.statusTextTarget.classList.add('text-slate-500')
            }
        }
    }

    async sendSubscriptionToServer(subscription) {
        const key = subscription.getKey('p256dh')
        const token = subscription.getKey('auth')

        return fetch('/pwa/subscribe', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'X-CSRF-Token': document.querySelector("[name='csrf-token']").content
            },
            body: JSON.stringify({
                endpoint: subscription.endpoint,
                p256dh: btoa(String.fromCharCode.apply(null, new Uint8Array(key))),
                auth: btoa(String.fromCharCode.apply(null, new Uint8Array(token)))
            })
        })
    }

    urlBase64ToUint8Array(base64String) {
        const padding = '='.repeat((4 - base64String.length % 4) % 4)
        const base64 = (base64String + padding)
            .replace(/-/g, '+')
            .replace(/_/g, '/')

        const rawData = window.atob(base64)
        const outputArray = new Uint8Array(rawData.length)

        for (let i = 0; i < rawData.length; ++i) {
            outputArray[i] = rawData.charCodeAt(i)
        }
        return outputArray
    }
}
