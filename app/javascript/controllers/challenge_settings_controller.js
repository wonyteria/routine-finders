import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["submitButton", "cancelButton", "modal", "changesList", "announceButton"]
    static values = {
        challengeId: Number
    }

    connect() {
        this.originalValues = this.captureFormValues()
        this.changes = {}
        this.updateButtonState()
    }

    captureFormValues() {
        const formData = new FormData(this.element)
        const values = {}

        for (let [key, value] of formData.entries()) {
            if (key.includes('[days][]')) {
                if (!values['days']) values['days'] = []
                values['days'].push(value)
            } else {
                values[key] = value
            }
        }

        return values
    }

    detectChanges() {
        const currentValues = this.captureFormValues()
        this.changes = {}

        // Field labels for Korean display
        const fieldLabels = {
            'challenge[title]': '챌린지 제목',
            'challenge[summary]': '한 줄 요약',
            'challenge[description]': '상세 설명',
            'challenge[custom_host_bio]': '호스트 소개',
            'challenge[start_date]': '시작일',
            'challenge[end_date]': '종료일',
            'challenge[cost_type]': '참가 방식',
            'challenge[amount]': '참가 금액',
            'challenge[max_participants]': '최대 참여 인원',
            'challenge[failure_tolerance]': '최대 실패 허용',
            'challenge[penalty_per_failure]': '실패 차감액',
            'challenge[full_refund_threshold]': '전액 환급 기준',
            'challenge[active_rate_threshold]': '달성 중 기준',
            'challenge[sluggish_rate_threshold]': '부진 기준',
            'challenge[non_participating_failures_threshold]': '미참여 탈락 기준',
            'challenge[verification_start_time]': '인증 시작 시간',
            'challenge[verification_end_time]': '인증 종료 시간',
            'challenge[re_verification_allowed]': '재인증 허용',
            'challenge[mission_requires_host_approval]': '호스트 승인제',
            'challenge[host_bank]': '은행명',
            'challenge[host_account]': '계좌번호',
            'challenge[host_account_holder]': '예금주',
            'days': '인증 요일'
        }

        // Compare values
        for (let key in this.originalValues) {
            if (key === 'days') {
                const originalDays = (this.originalValues.days || []).sort().join(',')
                const currentDays = (currentValues.days || []).sort().join(',')
                if (originalDays !== currentDays) {
                    this.changes[key] = {
                        label: fieldLabels[key] || key,
                        from: this.originalValues.days?.join(', ') || '없음',
                        to: currentValues.days?.join(', ') || '없음'
                    }
                }
            } else if (this.originalValues[key] !== currentValues[key]) {
                this.changes[key] = {
                    label: fieldLabels[key] || key,
                    from: this.formatValue(key, this.originalValues[key]),
                    to: this.formatValue(key, currentValues[key])
                }
            }
        }

        this.updateButtonState()
    }

    formatValue(key, value) {
        if (!value || value === '') return '없음'

        // Format percentage fields
        if (key.includes('threshold') && !key.includes('failures')) {
            return `${value}%`
        }

        // Format boolean fields
        if (value === '1' || value === 'true') return '예'
        if (value === '0' || value === 'false') return '아니오'

        // Format cost type
        if (key === 'challenge[cost_type]') {
            const types = { 'free': '무료', 'fee': '참가비', 'deposit': '보증금' }
            return types[value] || value
        }

        return value
    }

    updateButtonState() {
        const hasChanges = Object.keys(this.changes).length > 0

        if (this.hasSubmitButtonTarget) {
            this.submitButtonTarget.disabled = !hasChanges
            if (hasChanges) {
                this.submitButtonTarget.classList.remove('opacity-50', 'cursor-not-allowed')
                this.submitButtonTarget.classList.add('hover:bg-indigo-700', 'hover:-translate-y-1')
            } else {
                this.submitButtonTarget.classList.add('opacity-50', 'cursor-not-allowed')
                this.submitButtonTarget.classList.remove('hover:bg-indigo-700', 'hover:-translate-y-1')
            }
        }
    }

    showSummary(event) {
        event.preventDefault()

        if (Object.keys(this.changes).length === 0) {
            return
        }

        // Build changes list HTML
        let changesHTML = ''
        for (let key in this.changes) {
            const change = this.changes[key]
            changesHTML += `
                <div class="p-4 bg-slate-50 rounded-2xl border border-slate-200">
                    <p class="text-sm font-black text-slate-900 mb-2">${change.label}</p>
                    <div class="flex items-center gap-3">
                        <div class="flex-1">
                            <p class="text-xs font-medium text-slate-400 mb-1">변경 전</p>
                            <p class="text-sm font-bold text-red-600">${change.from}</p>
                        </div>
                        <svg class="w-5 h-5 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 7l5 5m0 0l-5 5m5-5H6"/>
                        </svg>
                        <div class="flex-1">
                            <p class="text-xs font-medium text-slate-400 mb-1">변경 후</p>
                            <p class="text-sm font-bold text-emerald-600">${change.to}</p>
                        </div>
                    </div>
                </div>
            `
        }

        this.changesListTarget.innerHTML = changesHTML
        this.modalTarget.classList.remove('hidden')
    }

    closeModal() {
        this.modalTarget.classList.add('hidden')
    }

    async confirmSave() {
        // Submit the form
        this.element.submit()
    }

    async saveAndAnnounce() {
        // Create announcement content
        const announcementContent = this.generateAnnouncementContent()

        // Add hidden field for announcement
        const input = document.createElement('input')
        input.type = 'hidden'
        input.name = 'create_announcement'
        input.value = 'true'
        this.element.appendChild(input)

        const contentInput = document.createElement('input')
        contentInput.type = 'hidden'
        contentInput.name = 'announcement_content'
        contentInput.value = announcementContent
        this.element.appendChild(contentInput)

        // Submit the form
        this.element.submit()
    }

    generateAnnouncementContent() {
        let content = "📢 챌린지 설정이 변경되었습니다\n\n"

        for (let key in this.changes) {
            const change = this.changes[key]
            content += `• ${change.label}: ${change.from} → ${change.to}\n`
        }

        content += "\n변경된 설정을 확인해주세요!"

        return content
    }
}
