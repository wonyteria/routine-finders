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
                alert('알림 권한이 차단되어 있습니다.\n\n브라우저 주소창의 [자물쇠 아이콘] 또는 [설정 > 애플리케이션 > 브라우저]에서 알림 권한을 허용으로 변경 후 다시 시도해주세요.')
                return
            }

            if (!this.vapidPublicKeyValue) {
                alert('VAPID 키가 누락되었습니다. 관리자에게 문의하세요.')
                return
            }

            // Debugging: Check if key looks correct
            console.log('VAPID Key:', this.vapidPublicKeyValue)

            // Remove any whitespace or quotes that might have snuck in
            const cleanKey = this.vapidPublicKeyValue.replace(/["'\s]/g, '')

            let applicationServerKey
            try {
                applicationServerKey = this.urlBase64ToUint8Array(cleanKey)
                console.log('Converted Key Length:', applicationServerKey.length)
            } catch (e) {
                alert(`VAPID 키 변환 오류: ${e.message}\n키 값: ${cleanKey.substring(0, 10)}...`)
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
