import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["form", "modal", "summaryContent", "announcementSection", "announcementCheckbox", "announcementTitle", "announcementContent", "costType", "costInput", "participationFeeInput", "amountLabel", "participationFeeContainer"]

    connect() {
        this.initialValues = this.captureCurrentValues()
        this.toggleCostInputs()

        // Validate initial values for fields with step increments
        this.formTarget.querySelectorAll('input[type="number"][step]').forEach(input => {
            this.validateStep({ target: input })
        })

        // Define field names for summary display
        this.fieldNames = {
            "challenge[title]": "챌린지 제목",
            "challenge[summary]": "한 줄 요약",
            "challenge[description]": "상세 설명",
            "challenge[custom_host_bio]": "호스트 소개",
            "challenge[start_date]": "시작일",
            "challenge[end_date]": "종료일",
            "challenge[recruitment_start_date]": "모집 시작일",
            "challenge[recruitment_end_date]": "모집 마감일",
            "challenge[days][]": "인증 요일",
            "challenge[verification_start_time]": "인증 시작 시간",
            "challenge[verification_end_time]": "인증 종료 시간",
            "challenge[re_verification_allowed]": "재인증 허용 여부",
            "challenge[mission_requires_host_approval]": "호스트 승인제 여부",
            "challenge[cost_type]": "참가 방식",
            "challenge[amount]": "금액",
            "challenge[participation_fee]": "추가 참가비",
            "challenge[failure_tolerance]": "최대 실패 허용",
            "challenge[penalty_per_failure]": "실패 차감액",
            "challenge[max_participants]": "최대 참여 인원",
            "challenge[full_refund_threshold]": "전액 환급 기준",
            "challenge[refund_date]": "환급 예정일",
            "challenge[active_rate_threshold]": "달성 중 기준",
            "challenge[sluggish_rate_threshold]": "부진 기준",
            "challenge[non_participating_failures_threshold]": "미참여 탈락 기준"
        }
    }

    captureCurrentValues() {
        const values = {}
        if (!this.hasFormTarget) return values

        const formData = new FormData(this.formTarget)
        for (let [key, value] of formData.entries()) {
            if (key === "authenticity_token" || key === "_method" || key === "utf8" || key.includes("thumbnail")) continue

            if (key.endsWith("[]")) {
                if (!values[key]) values[key] = []
                values[key].push(value)
            } else {
                values[key] = value
            }
        }
        return values
    }

    showSummary(event) {
        if (event) event.preventDefault()

        const currentValues = this.captureCurrentValues()
        const changes = this.getChanges(this.initialValues, currentValues)

        if (Object.keys(changes).length === 0) {
            if (this.hasFormTarget) this.formTarget.submit()
            return
        }

        this.renderSummary(changes)
        if (this.hasModalTarget) {
            this.modalTarget.classList.remove("hidden")
            this.modalTarget.style.display = 'flex'
        }

        this.updateAnnouncementPreview(changes)
    }

    getChanges(oldValues, newValues) {
        const changes = {}
        const allKeys = new Set([...Object.keys(oldValues), ...Object.keys(newValues)])

        allKeys.forEach(key => {
            if (key === "authenticity_token" || key === "_method" || key === "utf8" || key.includes("thumbnail")) return

            const oldVal = oldValues[key]
            const newVal = newValues[key]

            if (Array.isArray(oldVal) || Array.isArray(newVal)) {
                const oldSorted = JSON.stringify([...(oldVal || [])].sort())
                const newSorted = JSON.stringify([...(newVal || [])].sort())
                if (oldSorted !== newSorted) {
                    changes[key] = { old: oldVal || [], new: newVal || [] }
                }
            } else if (oldVal !== newVal) {
                // Ignore differences between null/undefined/empty string if they mean the same
                if (!oldVal && !newVal) return
                // Special handling for checkboxes (1/0)
                if ((oldVal === "0" && newVal === undefined) || (oldVal === undefined && newVal === "0")) return

                changes[key] = { old: oldVal, new: newVal }
            }
        })
        return changes
    }

    renderSummary(changes) {
        if (!this.hasSummaryContentTarget) return

        let html = '<ul class="space-y-3">'
        Object.entries(changes).forEach(([key, value]) => {
            const label = this.fieldNames[key] || key
            let oldText = value.old || "없음"
            let newText = value.new || "없음"

            if (key === "challenge[re_verification_allowed]" || key === "challenge[mission_requires_host_approval]") {
                oldText = oldText === "1" ? "허용" : "미허용"
                newText = newText === "1" ? "허용" : "미허용"
            }

            if (key === "challenge[cost_type]") {
                const costs = { "free": "무료", "fee": "참가비", "deposit": "보증금" }
                oldText = costs[oldText] || oldText
                newText = costs[newText] || newText
            }

            html += `
                <li class="flex flex-col gap-1 p-3 bg-white rounded-xl border border-slate-100">
                    <span class="text-[10px] font-black text-slate-400 uppercase tracking-widest">${label}</span>
                    <div class="flex items-center gap-2 text-sm">
                        <span class="text-slate-400 line-through truncate max-w-[150px]">${oldText}</span>
                        <svg class="w-3 h-3 text-indigo-400 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M13 7l5 5m0 0l-5 5m5-5H6"/></svg>
                        <span class="font-bold text-indigo-600 truncate max-w-[150px]">${newText}</span>
                    </div>
                </li>
            `
        })
        html += '</ul>'
        this.summaryContentTarget.innerHTML = html
    }

    updateAnnouncementPreview(changes) {
        if (!this.hasAnnouncementContentTarget || !this.hasAnnouncementTitleTarget) return

        let content = "챌린지 운영 정책이 다음과 같이 변경되었습니다.\n\n"
        Object.entries(changes).forEach(([key, value]) => {
            const label = this.fieldNames[key] || key
            let oldText = value.old || "없음"
            let newText = value.new || "없음"
            if (key === "challenge[re_verification_allowed]" || key === "challenge[mission_requires_host_approval]") {
                oldText = oldText === "1" ? "허용" : "미허용"
                newText = newText === "1" ? "허용" : "미허용"
            }
            if (key === "challenge[cost_type]") {
                const costs = { "free": "무료", "fee": "참가비", "deposit": "보증금" }
                oldText = costs[oldText] || oldText
                newText = costs[newText] || newText
            }
            content += `- ${label}: ${oldText} -> ${newText}\n`
        })
        this.announcementContentTarget.value = content
        this.announcementTitleTarget.value = "[공지] 챌린지 운영 정책 변경 안내"
    }

    toggleAnnouncementSection() {
        if (this.hasAnnouncementSectionTarget && this.hasAnnouncementCheckboxTarget) {
            this.announcementSectionTarget.classList.toggle("hidden", !this.announcementCheckboxTarget.checked)
        }
    }

    hideModal() {
        if (this.hasModalTarget) {
            this.modalTarget.classList.add("hidden")
            this.modalTarget.style.display = 'none'
        }
    }

    submitWithAnnouncement() {
        if (!this.hasFormTarget) return

        if (this.hasAnnouncementCheckboxTarget && this.announcementCheckboxTarget.checked) {
            const titleInput = document.createElement("input")
            titleInput.type = "hidden"
            titleInput.name = "announcement_title"
            titleInput.value = this.announcementTitleTarget.value
            this.formTarget.appendChild(titleInput)

            const contentInput = document.createElement("input")
            contentInput.type = "hidden"
            contentInput.name = "announcement_content"
            contentInput.value = this.announcementContentTarget.value
            this.formTarget.appendChild(contentInput)

            const flagInput = document.createElement("input")
            flagInput.type = "hidden"
            flagInput.name = "create_announcement"
            flagInput.value = "true"
            this.formTarget.appendChild(flagInput)
        }
        this.formTarget.submit()
    }

    toggleCostInputs() {
        if (!this.hasCostTypeTarget) return

        const costType = this.costTypeTarget.value
        const isFree = costType === "free"
        const isDeposit = costType === "deposit"
        const isFee = costType === "fee"

        // Update Amount Label
        if (this.hasAmountLabelTarget) {
            this.amountLabelTarget.innerText = isDeposit ? "보증금 (원)" : (isFee ? "참가비 (원)" : "보증금/참가비 (원)")
        }

        // Handle Base Cost Input
        if (this.hasCostInputTarget) {
            this.costInputTarget.disabled = isFree
            if (isFree) {
                this.costInputTarget.value = 0
                this.costInputTarget.classList.add("opacity-20", "cursor-not-allowed")
            } else {
                this.costInputTarget.classList.remove("opacity-20", "cursor-not-allowed")
            }
        }

        // Handle Additional Participation Fee (Only for Deposit)
        if (this.hasParticipationFeeContainerTarget && this.hasParticipationFeeInputTarget) {
            if (isDeposit) {
                this.participationFeeContainerTarget.classList.remove("hidden")
                this.participationFeeInputTarget.disabled = false
                this.participationFeeInputTarget.classList.remove("opacity-20", "cursor-not-allowed")
            } else {
                // Not a deposit: disable and optionally hide
                this.participationFeeInputTarget.disabled = true
                this.participationFeeInputTarget.value = 0
                this.participationFeeInputTarget.classList.add("opacity-20", "cursor-not-allowed")
                // Keep it visible but greyed out? Or hide? 
                // Suggestion: Hide it to avoid confusion as requested
                this.participationFeeContainerTarget.classList.add("hidden")
            }
        }
    }

    validateStep(event) {
        const input = event.target
        const step = parseInt(input.getAttribute("step"))
        if (!step || isNaN(step)) return

        let value = parseInt(input.value)
        if (isNaN(value)) {
            input.value = step
            return
        }

        const remainder = value % step
        if (remainder !== 0) {
            // Round to nearest multiple
            if (remainder >= step / 2) {
                value = value + (step - remainder)
            } else {
                value = value - remainder
            }
            // Ensure at least 1 step if min is higher
            if (value < step && input.getAttribute("min")) {
                value = parseInt(input.getAttribute("min"))
                // Re-round if min is not multiple
                if (value % step !== 0) value = Math.ceil(value / step) * step
            }
            input.value = value
        }
    }
}
