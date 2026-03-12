import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["form", "modal", "summaryContent", "announcementSection", "announcementCheckbox", "announcementTitle", "announcementContent", "costType", "costInput", "participationFeeInput", "amountLabel", "participationFeeContainer", "submitButton"]
    static values = { isGathering: Boolean }

    connect() {
        this.initialValues = this.captureCurrentValues()
        this.toggleCostInputs()

        // Validate initial values for fields with step increments
        this.formTarget.querySelectorAll('input[type="number"][step]').forEach(input => {
            this.validateStep({ target: input })
        })

        // Listen for all input changes to toggle submit button
        this.formTarget.addEventListener("input", () => this.checkChanges())
        this.toggleSubmitButton(false) // Initially disabled

        // Define field names for summary display
        const typeLabel = this.isGatheringValue ? "모임" : "챌린지"
        this.fieldNames = {
            "challenge[title]": `${typeLabel} 제목`,
            "challenge[summary]": "한 줄 요약",
            "challenge[description]": "상세 설명",
            "challenge[custom_host_bio]": "호스트 소개",
            "challenge[start_date]": this.isGatheringValue ? "모임일" : "시작일",
            "challenge[end_date]": "종료일",
            "challenge[recruitment_start_date]": "모집 시작일",
            "challenge[recruitment_end_date]": "모집 마감일",
            "challenge[days][]": "인증 요일",
            "challenge[verification_start_time]": "인증 시작 시간",
            "challenge[verification_end_time]": "인증 종료 시간",
            "challenge[re_verification_allowed]": "재인증 허용 여부",
            "challenge[mission_requires_host_approval]": "호스트 승인제 여부",
            "challenge[cost_type]": "참가 방식",
            "challenge[category]": "카테고리",
            "challenge[chat_link]": "채팅방 링크",
            "challenge[is_private]": "공개 여부",
            "challenge[admission_type]": "승인 방식",
            "challenge[amount]": this.isGatheringValue ? "참가비" : "보증금/참가비",
            "challenge[participation_fee]": "추가 참가비",
            "challenge[max_participants]": "최대 참여 인원",
            "challenge[full_refund_threshold]": "전액 환급 기준",
            "challenge[bonus_threshold]": "보너스 상금 기준",
            "challenge[certification_goal]": "인증 목표",
            "challenge[host_bank]": "은행",
            "challenge[host_account]": "계좌번호",
            "challenge[host_account_holder]": "예금주",
            "challenge[meeting_info_attributes][meeting_time]": "모임 시간",
            "challenge[meeting_info_attributes][place_name]": "장소명",
            "challenge[meeting_info_attributes][address]": "상세 주소",
            "challenge[meeting_info_attributes][place_url]": "상세 장소 URL"
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
        if (this.isSubmitting) return;
        if (event) event.preventDefault()

        const currentValues = this.captureCurrentValues()
        const changes = this.getChanges(this.initialValues, currentValues)

        // If no changes, submit button should already be disabled, but just in case
        if (Object.keys(changes).length === 0) {
            window.showToast("변경된 사항이 없습니다.", "info")
            return
        }

        if (!this.hasModalTarget) {
            if (this.hasFormTarget) {
                this.isSubmitting = true
                this.formTarget.requestSubmit()
            }
            return
        }

        this.renderSummary(changes)
        this.modalTarget.classList.remove("hidden")
        this.modalTarget.style.display = 'flex'

        this.updateAnnouncementPreview(changes)
    }

    checkChanges() {
        const currentValues = this.captureCurrentValues()
        const changes = this.getChanges(this.initialValues, currentValues)
        const hasChanges = Object.keys(changes).length > 0
        this.toggleSubmitButton(hasChanges)
    }

    toggleSubmitButton(enabled) {
        this.submitButtonTargets.forEach(button => {
            button.disabled = !enabled
            if (enabled) {
                button.classList.remove("opacity-50", "cursor-not-allowed", "grayscale-[0.5]")
            } else {
                button.classList.add("opacity-50", "cursor-not-allowed", "grayscale-[0.5]")
            }
        })
    }

    getChanges(oldValues, newValues) {
        const changes = {}
        const allKeys = new Set([...Object.keys(oldValues), ...Object.keys(newValues)])

        allKeys.forEach(key => {
            if (key === "authenticity_token" || key === "_method" || key === "utf8" || key.includes("thumbnail") || key === "tab" || key === "source" ||
                key === "announcement_title" || key === "announcement_content" || key === "create_announcement") return

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
            const label = this.fieldNames[key] || key.replace('challenge[', '').replace(']', '')
            let oldText = value.old || "없음"
            let newText = value.new || "없음"

            if (key === "challenge[re_verification_allowed]" || key === "challenge[mission_requires_host_approval]") {
                oldText = (oldText === "1" || oldText === "true") ? "허용" : "미허용"
                newText = (newText === "1" || newText === "true") ? "허용" : "미허용"
            }

            if (key === "challenge[is_private]") {
                oldText = (oldText === "true" || oldText === true) ? "비공개" : "공개"
                newText = (newText === "true" || newText === true) ? "비공개" : "공개"
            }

            if (key === "challenge[admission_type]") {
                const types = { "first_come": "선착순", "approval": "승인제" }
                oldText = types[oldText] || oldText
                newText = types[newText] || newText
            }

            if (key === "challenge[cost_type]") {
                const costs = { "free": "무료", "fee": "참가비", "deposit": "보증금" }
                oldText = costs[oldText] || oldText
                newText = costs[newText] || newText
            }

            html += `
                <li class="flex flex-col gap-1 p-3 bg-white/5 rounded-xl border border-white/5">
                    <span class="text-[9px] font-black text-slate-500 uppercase tracking-widest">${label}</span>
                    <div class="flex items-center gap-2 text-xs">
                        <span class="text-slate-500 line-through truncate max-w-[120px]">${oldText}</span>
                        <svg class="w-3 h-3 text-indigo-400 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M13 7l5 5m0 0l-5 5m5-5H6"/></svg>
                        <span class="font-bold text-white truncate max-w-[120px]">${newText}</span>
                    </div>
                </li>
            `
        })
        html += '</ul>'
        this.summaryContentTarget.innerHTML = html
    }

    updateAnnouncementPreview(changes) {
        if (!this.hasAnnouncementContentTarget || !this.hasAnnouncementTitleTarget) return

        const typeLabel = this.isGatheringValue ? "모임" : "챌린지"
        let content = `${typeLabel} 운영 정책이 더욱 원활한 진행을 위해 다음과 같이 보완되었습니다.\n\n`
        Object.entries(changes).forEach(([key, value]) => {
            const label = this.fieldNames[key] || this.formatKeyToLabel(key)
            let oldText = value.old || "미지정"
            let newText = value.new || "미지정"

            if (oldText === "없음") oldText = "미지정"
            if (newText === "없음") newText = "미지정"

            if (key === "challenge[re_verification_allowed]" || key === "challenge[mission_requires_host_approval]") {
                oldText = (oldText === "1" || oldText === "true") ? "허용" : "미허용"
                newText = (newText === "1" || newText === "true") ? "허용" : "미허용"
            }
            if (key === "challenge[is_private]") {
                oldText = (oldText === "true" || oldText === true) ? "비공개" : "공개"
                newText = (newText === "true" || newText === true) ? "비공개" : "공개"
            }
            if (key === "challenge[admission_type]") {
                const types = { "first_come": "선착순", "approval": "승인제" }
                oldText = types[oldText] || oldText
                newText = types[newText] || newText
            }
            if (key === "challenge[cost_type]") {
                const costs = { "free": "무료", "fee": "참가비", "deposit": "보증금" }
                oldText = costs[oldText] || oldText
                newText = costs[newText] || newText
            }

            if (value.old === undefined || value.old === "" || value.old === null) {
                content += `📌 ${label}이(가) [${newText}] (으)로 새롭게 설정되었습니다.\n`
            } else {
                content += `✅ ${label}: ${oldText} -> ${newText}\n`
            }
        })
        content += "\n더욱 알찬 활동을 위해 최선을 다하겠습니다. 궁금한 점은 호스트에게 문의해 주세요! 🌿"
        this.announcementContentTarget.value = content
        this.announcementTitleTarget.value = `[공지] ${typeLabel} 운영 정책 변경 안내`
    }

    formatKeyToLabel(key) {
        return key.replace('challenge[', '')
            .replace('meeting_info_attributes][', '장소 ')
            .replace(']', '')
            .replace('_', ' ')
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
            // Remove any existing hidden inputs of the same name to prevent duplicates
            this.formTarget.querySelectorAll('input[name="announcement_title"], input[name="announcement_content"], input[name="create_announcement"]').forEach(el => el.remove())

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

        // Scroll to top as requested
        window.scrollTo({ top: 0, behavior: 'smooth' })

        this.isSubmitting = true
        this.formTarget.requestSubmit()
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
