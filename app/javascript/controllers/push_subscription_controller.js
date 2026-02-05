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
                element.classList.add("ring-2", "ring-indigo-500", "ring-offset-4", "ring-offset-[#0C0B12]", "rounded-xl", "bg-indigo-500/10")
                setTimeout(() => {
                    element.classList.remove("ring-2", "ring-indigo-500", "ring-offset-4", "ring-offset-[#0C0B12]", "bg-indigo-500/10")
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
        // Check if user has dismissed the guide
        const isGuideDismissed = localStorage.getItem('push_guide_dismissed') === 'true'

        if (isGuideDismissed) {
            this.processSubscription()
        } else {
            this.openGuide()
        }
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
            const registration = await navigator.serviceWorker.ready

            // [Important] Force VAPID Key Rotation check
            // Although usually we are here because we are unsubscribed,
            // double check to ensure clean state.
            const existingSubscription = await registration.pushManager.getSubscription()
            if (existingSubscription) {
                await existingSubscription.unsubscribe()
            }

            // Request permission
            const permission = await Notification.requestPermission()
            if (permission !== 'granted') {
                // If the user manually blocked it before, the browser won't ask again and returns 'denied' immediately.
                // Or if they just switched text in OS settings but didn't reload, the browser might not know yet.
                if (permission === 'denied') {
                    // PWA environment doesn't have an address bar, so we guide to App Settings.
                    alert(
                        '🚫 알림 권한이 차단되어 있습니다.\n\n' +
                        '이미 설정을 켜셨다면, 일시적인 오류일 수 있습니다.\n\n' +
                        '[해결 방법]\n' +
                        '1. 앱을 완전히 종료 후 다시 실행해보세요.\n' +
                        '2. 그래도 안 되면 휴대폰 [설정 > 애플리케이션 > 루틴파인더스 > 저장공간 > 데이터 삭제] 후 다시 로그인해보세요. (가장 확실)\n' +
                        '   (*데이터 삭제 시 권한 설정이 초기화됩니다)'
                    )
                } else {
                    alert('알림 권한이 거부되었습니다.\n권한을 허용해야 알림을 받을 수 있습니다.')
                }

                // Revert toggle visually
                this.updateUI(false)
                return
            }

            if (!this.vapidPublicKeyValue) {
                alert('VAPID 키가 누락되었습니다.')
                return
            }

            // Remove everything except what's valid for Base64 (A-Z, a-z, 0-9, +, /, -, _, =)
            let cleanKey = (this.vapidPublicKeyValue || "").replace(/[^A-Za-z0-9\+\/\-\_=]/g, '')

            let applicationServerKey
            try {
                applicationServerKey = this.urlBase64ToUint8Array(cleanKey)
            } catch (e) {
                console.error('Key error:', e)
                alert('알림 시스템 초기화 오류')
                return
            }

            // Subscribe
            const subscription = await registration.pushManager.subscribe({
                userVisibleOnly: true,
                applicationServerKey: applicationServerKey
            })

            await this.sendSubscriptionToServer(subscription)

            this.updateUI(true)
            alert('푸시 알림이 설정되었습니다! ✨')

        } catch (error) {
            console.error('Subscription failed:', error)
            alert(`알림 설정 실패: ${error.message}`)
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
