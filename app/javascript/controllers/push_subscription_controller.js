import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static values = {
        vapidPublicKey: String
    }

    connect() {
        this.checkSubscription()
    }

    async checkSubscription() {
        if (!('serviceWorker' in navigator) || !('PushManager' in window)) {
            console.log('Push messaging is not supported')
            return
        }

        const registration = await navigator.serviceWorker.ready
        const subscription = await registration.pushManager.getSubscription()

        if (subscription) {
            // Already subscribed, sync with server if needed
            this.sendSubscriptionToServer(subscription)
        }
    }

    async subscribe() {
        try {
            const registration = await navigator.serviceWorker.ready

            // Request permission
            const permission = await Notification.requestPermission()
            if (permission !== 'granted') {
                alert('알림 권한이 설정되어 있지 않습니다.\n\n[해결 방법]\n1. 안드로이드: 바탕화면 앱 아이콘 길게 누르기 > [앱 정보(i)] > [알림] > 허용\n2. 아이폰: 설정 앱 > 알림 > [Routine Finders] 찾기 > 알림 허용\n\n권한을 켜신 후 다시 [앱 푸시 알림 설정]을 눌러주세요.')
                return
            }

            if (!this.vapidPublicKeyValue) {
                alert('VAPID 키가 누락되었습니다. 관리자에게 문의하세요.')
                return
            }



            // Detailed Sanitization & Logging
            console.log('Original VAPID Key:', this.vapidPublicKeyValue)

            // Remove everything except what's valid for Base64 (A-Z, a-z, 0-9, +, /, -, _, =)
            const cleanKey = this.vapidPublicKeyValue.replace(/[^A-Za-z0-9\+\/\-\_=]/g, '')
            console.log('Cleaned VAPID Key:', cleanKey, 'Length:', cleanKey.length)

            let applicationServerKey

            try {
                applicationServerKey = this.urlBase64ToUint8Array(cleanKey)
                console.log('Converted Buffer Length:', applicationServerKey.length)
            } catch (e) {
                console.error('VAPID Key Convert Error:', e)
                const firstPart = cleanKey ? cleanKey.substring(0, 10) : 'None'
                alert(`알림 시스템 초기화 오류가 발생했습니다.\n(Key Conversion Failed)\n\nKey: ${firstPart}...\nLen: ${cleanKey?.length}\nError: ${e.message}`)
                return
            }

            if (applicationServerKey.length !== 65) {
                alert(`설정된 VAPID Key의 길이가 올바르지 않습니다.\n(현재: ${applicationServerKey.length} bytes / 필요: 65 bytes)\n\n서버의 VAPID_PUBLIC_KEY 환경 변수를 확인해주세요.`)
                return
            }

            const subscription = await registration.pushManager.subscribe({
                userVisibleOnly: true,
                applicationServerKey: applicationServerKey
            })

            await this.sendSubscriptionToServer(subscription)
            alert('푸시 알림 구독이 완료되었습니다! ✨')
        } catch (error) {
            console.error('Failed to subscribe to push notifications:', error)

            if (error.message && error.message.includes('applicationServerKey is not valid')) {
                alert('서버에 설정된 VAPID Key가 유효하지 않습니다.\n\n서버의 .env 파일에 있는 VAPID_PUBLIC_KEY 값이 손상되었거나 잘못 입력되었습니다.\n새로운 키로 교체해주세요.')
                return
            }

            alert(`알림 구독에 실패했습니다: ${error.message}`)
        }
    }

    async sendSubscriptionToServer(subscription) {
        const key = subscription.getKey('p256dh')
        const token = subscription.getKey('auth')
        const contentEncoding = (PushManager.supportedContentEncodings || ['aesgcm'])[0]

        return fetch('/pwa/subscribe', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                endpoint: subscription.endpoint,
                p256dh: btoa(String.fromCharCode.apply(null, new Uint8Array(key))),
                auth: btoa(String.fromCharCode.apply(null, new Uint8Array(token)))
            })
        })
    }

    urlBase64ToUint8Array(base64String) {
        // Strip existing padding if any, then re-pad correctly
        const base64WithoutPadding = base64String.split('=')[0]
        const padding = '='.repeat((4 - (base64WithoutPadding.length % 4)) % 4)
        const base64 = (base64WithoutPadding + padding)
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
