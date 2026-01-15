// 브라우저 알림 헬퍼 유틸리티
export class NotificationHelper {
    static isEnabled() {
        return localStorage.getItem('notifications_enabled') === 'true' &&
            Notification.permission === 'granted'
    }

    static send(title, options = {}) {
        if (!this.isEnabled()) {
            console.log('알림이 비활성화되어 있습니다:', title)
            return null
        }

        const defaultOptions = {
            icon: '/icon.png',
            badge: '/badge.png',
            tag: 'routine-finders',
            requireInteraction: false,
            ...options
        }

        return new Notification(title, defaultOptions)
    }

    // 루틴 완료 알림
    static routineCompleted(routineTitle) {
        return this.send('루틴 완료! 🎉', {
            body: `"${routineTitle}" 루틴을 완료했습니다!`,
            tag: 'routine-completed'
        })
    }

    // 배지 획득 알림
    static badgeEarned(badgeName) {
        return this.send('새로운 배지 획득! 🏆', {
            body: `"${badgeName}" 배지를 획득했습니다!`,
            tag: 'badge-earned',
            requireInteraction: true
        })
    }

    // 레벨업 알림
    static levelUp(newLevel) {
        return this.send('레벨업! ⬆️', {
            body: `축하합니다! Lv.${newLevel}에 도달했습니다!`,
            tag: 'level-up',
            requireInteraction: true
        })
    }

    // 챌린지 시작 알림
    static challengeStarting(challengeName, hoursLeft) {
        return this.send('챌린지 시작 임박! ⏰', {
            body: `"${challengeName}" 챌린지가 ${hoursLeft}시간 후 시작됩니다.`,
            tag: 'challenge-starting'
        })
    }

    // 루틴 리마인더
    static routineReminder(routineTitle) {
        return this.send('루틴 시간이에요! 🔔', {
            body: `"${routineTitle}" 루틴을 완료할 시간입니다.`,
            tag: 'routine-reminder'
        })
    }

    // 박수 받음 알림
    static receivedClap(fromUser, activityTitle) {
        return this.send('응원을 받았어요! 👏', {
            body: `${fromUser}님이 "${activityTitle}"에 박수를 보냈습니다.`,
            tag: 'received-clap'
        })
    }
}

// 전역으로 사용 가능하도록 export
window.NotificationHelper = NotificationHelper
