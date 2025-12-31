import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = [
        "step", "nav", "progressBar", "dot",
        "costFields", "accountFields", "penaltyAmountCard", "failureToleranceCard",
        "amountHidden", "penaltyHidden",
        "bankName", "accountNumber", "accountHolder",
        "thumbnailPreview", "thumbnailInput",
        "invitationCodeSection", "summaryModal", "summaryContent",
        "hostBio", "missionGoalType", "fixedGoalSection", "dailyGoalSection",
        "disclaimerFields", "rewardHidden", "rewardsContainer", "achievementThresholds",
        "refundDateField", "recruitmentStartDate", "recruitmentEndDate"
    ]

    connect() {
        this.currentStep = 1
        this.showStep()
    }

    next() {
        if (this.currentStep < 7) {
            this.currentStep++
            this.showStep()
        }
    }

    prev() {
        if (this.currentStep > 1) {
            this.currentStep--
            this.showStep()
        }
    }

    goToStep(event) {
        const step = parseInt(event.currentTarget.dataset.step)
        // Only allow going to previous steps or the very next step
        if (step < this.currentStep || step === this.currentStep + 1) {
            this.currentStep = step
            this.showStep()
        }
    }

    showStep() {
        // Show current step div, hide others
        this.stepTargets.forEach((el, i) => {
            el.classList.toggle("hidden", i + 1 !== this.currentStep)
        })

        // Update progress bar
        if (this.hasProgressBarTarget) {
            const progress = (this.currentStep / 6) * 100
            this.progressBarTarget.style.width = `${progress}%`
        }

        // Update progress dots
        this.dotTargets.forEach((el, i) => {
            const active = i + 1 === this.currentStep
            el.classList.toggle("bg-indigo-600", active)
            el.classList.toggle("w-6", active)
            el.classList.toggle("bg-slate-200", !active)
            el.classList.toggle("w-2", !active)
        })

        // Update side nav
        this.navTargets.forEach((el, i) => {
            const stepNum = i + 1
            const icon = el.querySelector(".nav-icon")
            const text = el.querySelector(".nav-text")

            if (stepNum === this.currentStep) {
                icon.classList.remove("bg-white", "text-slate-300")
                icon.classList.add("bg-indigo-600", "text-white", "shadow-xl", "shadow-indigo-200")
                text.classList.remove("opacity-40")
                text.classList.add("opacity-100")
            } else {
                icon.classList.remove("bg-indigo-600", "text-white", "shadow-xl", "shadow-indigo-200")
                icon.classList.add("bg-white", "text-slate-300")
                text.classList.remove("opacity-100")
                text.classList.add("opacity-40")
            }
        })

        window.scrollTo({ top: 0, behavior: 'smooth' })
    }

    // --- Logic Methods ---

    selectOption(event) {
        const { name, value } = event.currentTarget.dataset
        const hiddenInput = this.element.querySelector(`input[name="challenge[${name}]"]`)

        if (hiddenInput) {
            hiddenInput.value = (value === "true" ? "1" : (value === "false" ? "0" : value))
        }

        // Update UI for buttons in the same group
        const parent = event.currentTarget.closest('[data-option-group]') || event.currentTarget.parentElement
        parent.querySelectorAll(`[data-name="${name}"]`).forEach(btn => {
            const isSelected = btn.dataset.value === value
            if (isSelected) {
                btn.classList.add("border-indigo-600", "bg-indigo-50", "ring-1", "ring-indigo-600/20")
                btn.classList.remove("border-transparent", "bg-white", "border-slate-100")
                const icon = btn.querySelector(".option-icon")
                if (icon) icon.classList.add("text-indigo-600")
            } else {
                btn.classList.remove("border-indigo-600", "bg-indigo-50", "ring-1", "ring-indigo-600/20")
                btn.classList.add("border-transparent", "bg-white", "border-slate-100")
                const icon = btn.querySelector(".option-icon")
                if (icon) icon.classList.remove("text-indigo-600")
            }
        })

        // Special case for Private Challenge
        if (name === "is_private" && this.hasInvitationCodeSectionTarget) {
            const isPrivate = value === "true"
            this.invitationCodeSectionTarget.classList.toggle("hidden", !isPrivate)
            if (isPrivate) {
                const code = Math.random().toString(36).substring(2, 8).toUpperCase()
                this.element.querySelector("#invitation_code_display").textContent = code
                this.element.querySelector("#challenge_invitation_code").value = code
            }
        }
    }

    toggleDay(event) {
        const day = event.currentTarget.dataset.day
        const checkbox = this.element.querySelector(`#day_${day}`)
        if (checkbox) {
            checkbox.checked = !checkbox.checked
            event.currentTarget.classList.toggle("bg-indigo-600", checkbox.checked)
            event.currentTarget.classList.toggle("text-white", checkbox.checked)
            event.currentTarget.classList.toggle("shadow-lg", checkbox.checked)
            event.currentTarget.classList.toggle("bg-white", !checkbox.checked)
            event.currentTarget.classList.toggle("text-slate-300", !checkbox.checked)
        }
    }

    toggleVerificationType(event) {
        const type = event.currentTarget.dataset.type
        const hiddenInput = this.element.querySelector(`#challenge_v_${type}`)
        if (hiddenInput) {
            hiddenInput.value = (hiddenInput.value === "1" ? "0" : "1")
            const isSelected = hiddenInput.value === "1"

            event.currentTarget.classList.toggle("border-indigo-600", isSelected)
            event.currentTarget.classList.toggle("bg-indigo-50", isSelected)
            event.currentTarget.classList.toggle("shadow-lg", isSelected)
            event.currentTarget.classList.toggle("shadow-indigo-600/5", isSelected)
            event.currentTarget.classList.toggle("border-transparent", !isSelected)
            event.currentTarget.classList.toggle("bg-white", !isSelected)

            const iconBox = event.currentTarget.querySelector(".verif-icon-box")
            if (iconBox) {
                iconBox.classList.toggle("bg-indigo-600", isSelected)
                iconBox.classList.toggle("text-white", isSelected)
                iconBox.classList.toggle("bg-slate-50", !isSelected)
                iconBox.classList.toggle("text-slate-300", !isSelected)
            }
        }
    }

    toggleCostType(event) {
        const type = event.currentTarget.dataset.type
        const hiddenInput = this.element.querySelector('input[name="challenge[cost_type]"]')
        if (hiddenInput) hiddenInput.value = type

        this.element.querySelectorAll(".cost-type-btn").forEach(btn => {
            const isSelected = btn.dataset.type === type
            btn.classList.toggle("border-indigo-600", isSelected)
            btn.classList.toggle("bg-indigo-50", isSelected)
            btn.classList.toggle("border-transparent", !isSelected)
            btn.classList.toggle("bg-white", !isSelected)

            const icon = btn.querySelector("svg")
            if (icon) {
                icon.classList.toggle("text-indigo-600", isSelected)
                icon.classList.toggle("text-slate-300", !isSelected)
            }
        })

        this.updateCostFields(type)
    }

    updateCostFields(type) {
        if (this.hasCostFieldsTarget) this.costFieldsTarget.classList.toggle("hidden", type === "free")
        if (this.hasAccountFieldsTarget) this.accountFieldsTarget.classList.toggle("hidden", type === "free")

        // Only show penalty amount for deposit-type challenges
        if (this.hasPenaltyAmountCardTarget) {
            this.penaltyAmountCardTarget.classList.toggle("hidden", type !== "deposit")
        }

        // Only show achievement thresholds for deposit-type challenges
        if (this.hasAchievementThresholdsTarget) {
            this.achievementThresholdsTarget.classList.toggle("hidden", type !== "deposit")
        }

        // Only show refund date for deposit-type challenges
        if (this.hasRefundDateFieldTarget) {
            this.refundDateFieldTarget.classList.toggle("hidden", type !== "deposit")
        }

        // Failure tolerance might be useful for all types besides maybe 'free'? 
        // Let's keep it visible for fee and deposit.
        if (this.hasFailureToleranceCardTarget) {
            this.failureToleranceCardTarget.classList.toggle("hidden", type === "free")
        }

        // Show disclaimer for paid/deposit challenges
        if (this.hasDisclaimerFieldsTarget) {
            this.disclaimerFieldsTarget.classList.toggle("hidden", type === "free")
        }
    }

    async saveAccount() {
        if (!this.hasBankNameTarget || !this.hasAccountNumberTarget || !this.hasAccountHolderTarget) return

        const data = {
            bank_name: this.bankNameTarget.value,
            account_number: this.accountNumberTarget.value,
            account_holder: this.accountHolderTarget.value
        }

        try {
            const response = await fetch("/profile/save_account", {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                    "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
                },
                body: JSON.stringify(data)
            })

            const result = await response.json()
            if (result.status === "success") {
                alert(result.message)
            } else {
                alert(result.message || "저장에 실패했습니다.")
            }
        } catch (error) {
            console.error("Error saving account:", error)
            alert("서버 통신 중 오류가 발생했습니다.")
        }
    }

    async loadAccount() {
        try {
            const response = await fetch("/profile/get_account")
            const result = await response.json()

            if (result.status === "success") {
                if (this.hasBankNameTarget) this.bankNameTarget.value = result.bank_name
                if (this.hasAccountNumberTarget) this.accountNumberTarget.value = result.account_number
                if (this.hasAccountHolderTarget) this.accountHolderTarget.value = result.account_holder
            } else {
                alert(result.message || "저장된 계좌 정보가 없습니다.")
            }
        } catch (error) {
            console.error("Error loading account:", error)
            alert("서버 통신 중 오류가 발생했습니다.")
        }
    }

    loadDefaultBio(event) {
        const { bio } = event.currentTarget.dataset
        if (this.hasHostBioTarget) {
            this.hostBioTarget.value = bio || ""
        }
    }

    previewThumbnail(event) {
        const file = event.target.files[0]
        if (file && this.hasThumbnailPreviewTarget) {
            const reader = new FileReader()
            reader.onload = (e) => {
                this.thumbnailPreviewTarget.src = e.target.result
                this.thumbnailPreviewTarget.classList.remove("hidden")
                const placeholder = this.element.querySelector("#thumbnail-placeholder")
                if (placeholder) placeholder.classList.add("hidden")
            }
            reader.readAsDataURL(file)
        }
    }

    updateMaxParticipants(event) {
        const value = parseInt(event.target.value)
        const display = this.element.querySelector("#max-participants-display")
        if (display) display.textContent = `${value}명`

        const min = parseInt(event.target.min) || 0
        const max = parseInt(event.target.max) || 100
        const percentage = ((value - min) / (max - min)) * 100
        event.target.style.backgroundSize = `${percentage}% 100%`
    }

    copyInvitationCode() {
        const code = this.element.querySelector("#challenge_invitation_code").value
        if (!code || code === "-") return

        navigator.clipboard.writeText(code).then(() => {
            const display = this.element.querySelector("#invitation_code_display")
            const originalText = display.textContent
            display.textContent = "복제 완료!"
            display.classList.add("text-indigo-600")

            setTimeout(() => {
                display.textContent = originalText
                display.classList.remove("text-indigo-600")
            }, 2000)
        })
    }

    toggleMissionGoalType(event) {
        const type = event.currentTarget.dataset.type
        const isDaily = type === "daily"

        if (this.hasFixedGoalSectionTarget) this.fixedGoalSectionTarget.classList.toggle("hidden", isDaily)
        if (this.hasDailyGoalSectionTarget) this.dailyGoalSectionTarget.classList.toggle("hidden", !isDaily)

        // Update button UI
        const container = event.currentTarget.closest('[data-option-group]')
        if (container) {
            container.querySelectorAll('button').forEach(btn => {
                const isSelected = btn.dataset.type === type
                if (isSelected) {
                    btn.classList.add("border-indigo-600", "bg-indigo-50", "shadow-lg", "shadow-indigo-600/5")
                    btn.classList.remove("border-slate-100", "bg-white")
                    const iconBox = btn.querySelector("div")
                    if (iconBox) {
                        iconBox.classList.add("bg-indigo-600", "text-white")
                        iconBox.classList.remove("bg-slate-50", "text-slate-300")
                    }
                    const mainLabel = btn.querySelector(".label-main")
                    const subLabel = btn.querySelector(".label-sub")
                    if (mainLabel) {
                        mainLabel.classList.add("text-indigo-600")
                        mainLabel.classList.remove("text-slate-400")
                    }
                    if (subLabel) {
                        subLabel.classList.add("text-indigo-400/80")
                        subLabel.classList.remove("text-slate-300")
                    }
                } else {
                    btn.classList.remove("border-indigo-600", "bg-indigo-50", "shadow-lg", "shadow-indigo-600/5")
                    btn.classList.add("border-slate-100", "bg-white")
                    const iconBox = btn.querySelector("div")
                    if (iconBox) {
                        iconBox.classList.remove("bg-indigo-600", "text-white")
                        iconBox.classList.add("bg-slate-50", "text-slate-300")
                    }
                    const mainLabel = btn.querySelector(".label-main")
                    const subLabel = btn.querySelector(".label-sub")
                    if (mainLabel) {
                        mainLabel.classList.remove("text-indigo-600")
                        mainLabel.classList.add("text-slate-400")
                    }
                    if (subLabel) {
                        subLabel.classList.remove("text-indigo-400/80")
                        subLabel.classList.add("text-slate-300")
                    }
                }
            })
        }

        // Clear contradictory data
        if (isDaily) {
            const fixedInput = this.element.querySelector("#challenge_certification_goal")
            if (fixedInput) fixedInput.value = ""
        } else {
            const hiddenDaily = this.element.querySelector("#challenge_daily_goals_hidden")
            if (hiddenDaily) hiddenDaily.value = "{}"
            const dailyInputs = this.dailyGoalSectionTarget.querySelectorAll("input")
            dailyInputs.forEach(input => input.value = "")
        }
    }

    updateDailyGoal(event) {
        const day = event.currentTarget.dataset.day
        const value = event.currentTarget.value
        const hiddenInput = this.element.querySelector("#challenge_daily_goals_hidden")

        if (hiddenInput) {
            let dailyGoals = {}
            try {
                dailyGoals = JSON.parse(hiddenInput.value || "{}")
                if (typeof dailyGoals === "string") {
                    dailyGoals = JSON.parse(dailyGoals)
                }
            } catch (e) {
                dailyGoals = {}
            }
            dailyGoals[day] = value
            hiddenInput.value = JSON.stringify(dailyGoals)
        }
    }

    showSummary(event) {
        event.preventDefault()
        if (this.hasSummaryModalTarget) {
            const title = this.element.querySelector("#challenge_title").value
            const start = this.element.querySelector("#challenge_start_date").value
            const end = this.element.querySelector("#challenge_end_date").value
            const recruitmentStart = this.element.querySelector('input[name="challenge[recruitment_start_date]"]').value
            const recruitmentEnd = this.element.querySelector('input[name="challenge[recruitment_end_date]"]').value
            const costType = this.element.querySelector('input[name="challenge[cost_type]"]').value
            const amount = this.element.querySelector("#challenge_amount").value
            const maxParticipants = this.element.querySelector("#max-participants-display").textContent

            const missionGoal = this.element.querySelector("#challenge_certification_goal")?.value || ""
            const dailyGoalsHidden = this.element.querySelector("#challenge_daily_goals_hidden")?.value || "{}"

            let dailyGoals = {}
            try {
                dailyGoals = JSON.parse(dailyGoalsHidden)
                // Handle potential double-encoding
                if (typeof dailyGoals === "string") {
                    dailyGoals = JSON.parse(dailyGoals)
                }
            } catch (e) {
                dailyGoals = {}
            }

            const isDailyMode = this.hasDailyGoalSectionTarget && !this.dailyGoalSectionTarget.classList.contains("hidden")
            const hasDailyGoals = isDailyMode && dailyGoals && typeof dailyGoals === 'object' && Object.values(dailyGoals).some(g => g && g.trim() !== "")

            let missionSummary = ""
            if (hasDailyGoals) {
                missionSummary = `<div class="mt-1 flex flex-wrap gap-1">`
                Object.entries(dailyGoals).forEach(([day, goal]) => {
                    if (goal && goal.trim()) {
                        missionSummary += `<span class="px-2 py-1 bg-indigo-50 text-[10px] font-bold text-indigo-600 rounded-md">${day}: ${goal}</span>`
                    }
                })
                missionSummary += `</div>`
            } else {
                missionSummary = `<p class="text-sm font-bold text-slate-700">${missionGoal || '공통 목표 없음'}</p>`
            }

            let summaryHtml = `
                <div class="space-y-4">
                    <div class="space-y-1">
                        <p class="text-[10px] font-black text-slate-400 uppercase tracking-widest">챌린지 명</p>
                        <p class="text-lg font-black text-slate-900">${title || '제목 없음'}</p>
                    </div>

                    <div class="space-y-1">
                        <p class="text-[10px] font-black text-slate-400 uppercase tracking-widest">인증 목표</p>
                        ${missionSummary}
                    </div>
                    
                    <div class="grid grid-cols-2 gap-4">
                        <div class="space-y-1">
                            <p class="text-[10px] font-black text-slate-400 uppercase tracking-widest">진행 기간</p>
                            <p class="text-sm font-bold text-slate-700">${start} ~ ${end}</p>
                        </div>
                        <div class="space-y-1">
                            <p class="text-[10px] font-black text-slate-400 uppercase tracking-widest">모집 인원</p>
                            <p class="text-sm font-bold text-slate-700">${maxParticipants}</p>
                        </div>
                    </div>

                    <div class="space-y-1">
                        <p class="text-[10px] font-black text-slate-400 uppercase tracking-widest">참여 모집 기간</p>
                        <p class="text-sm font-bold text-slate-700">${recruitmentStart} ~ ${recruitmentEnd}</p>
                    </div>

                <div class="space-y-2 pt-2 border-t border-slate-100">
                    <p class="text-[10px] font-black text-slate-400 uppercase tracking-widest">우승 혜택</p>
                    <div class="space-y-1">
                        ${this.getRewardsSummary()}
                    </div>
                </div>

                <div class="space-y-1 pt-2 border-t border-slate-100">
                        <p class="text-[10px] font-black text-slate-400 uppercase tracking-widest">참여 비용</p>
                        <p class="text-xl font-black text-indigo-600">
                            ${costType === 'free' ? '무료' : Number(amount).toLocaleString() + '원'}
                            <span class="text-xs text-slate-400 font-bold ml-1">(${costType === 'deposit' ? '보증금' : '참가비'})</span>
                        </p>
                    </div>
                </div>
            `
            this.summaryContentTarget.innerHTML = summaryHtml
            this.summaryModalTarget.classList.remove("hidden")
            this.summaryModalTarget.classList.add("flex")

            // For animation
            setTimeout(() => {
                const modal = this.summaryModalTarget.querySelector('div')
                modal.classList.add('scale-100', 'opacity-100')
                modal.classList.remove('scale-95', 'opacity-0')
            }, 10)
        }
    }

    hideSummary() {
        if (this.hasSummaryModalTarget) {
            const modal = this.summaryModalTarget.querySelector('div')
            modal.classList.remove('scale-100', 'opacity-100')
            modal.classList.add('scale-95', 'opacity-0')

            setTimeout(() => {
                this.summaryModalTarget.classList.add("hidden")
                this.summaryModalTarget.classList.remove("flex")
            }, 200)
        }
    }

    handleModalClick(event) {
        if (event.target === this.summaryModalTarget) {
            this.hideSummary()
        }
    }

    // Removed toggleCheckbox as it interfered with default label->checkbox behavior

    submitForm() {
        // Disable Turbo for this submission to ensure a clean redirect to the new challenge page
        const form = this.element.querySelector("form")
        form.setAttribute("data-turbo", "false")
        form.submit()
    }

    getRewardsSummary() {
        if (!this.hasRewardHiddenTarget) return '<p class="text-xs text-slate-400">설정된 혜택 없음</p>'

        let rewards = []
        try {
            rewards = JSON.parse(this.rewardHiddenTarget.value || "[]")
            if (typeof rewards === "string") {
                rewards = JSON.parse(rewards)
            }
        } catch (e) {
            rewards = []
        }

        if (!Array.isArray(rewards) || rewards.length === 0) return '<p class="text-xs text-slate-400">설정된 혜택 없음</p>'

        let html = ""
        rewards.forEach(item => {
            if (item.rank.trim() || item.prize.trim()) {
                html += `<p class="text-xs font-bold text-slate-700">${item.rank}: ${item.prize}</p>`
            }
        })

        return html || '<p class="text-xs text-slate-400">설정된 혜택 없음</p>'
    }

    addReward() {
        const container = this.rewardsContainerTarget
        const div = document.createElement("div")
        div.className = "group flex flex-col md:flex-row gap-4 p-6 bg-slate-50 rounded-[32px] border-2 border-transparent transition-all relative"
        div.innerHTML = `
            <div class="flex-1 space-y-2">
                <label class="text-[10px] font-black text-slate-400 uppercase tracking-widest pl-1">순위/대상</label>
                <input type="text" data-action="input->challenge-form#updateRewards" class="reward-rank w-full text-base font-black p-0 border-none bg-transparent focus:ring-0 text-slate-900" placeholder="">
            </div>
            <div class="flex-[2] space-y-2">
                <label class="text-[10px] font-black text-slate-400 uppercase tracking-widest pl-1">혜택 내용</label>
                <input type="text" data-action="input->challenge-form#updateRewards" class="reward-prize w-full text-base font-black p-0 border-none bg-transparent focus:ring-0 text-slate-900" placeholder="">
            </div>
            <button type="button" data-action="click->challenge-form#removeReward" class="absolute -top-2 -right-2 w-8 h-8 bg-white border border-slate-100 text-slate-400 hover:text-rose-500 rounded-full flex items-center justify-center shadow-sm opacity-0 group-hover:opacity-100 transition-all">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M6 18L18 6M6 6l12 12"/></svg>
            </button>
        `
        container.appendChild(div)
        this.updateRewards()
    }

    removeReward(event) {
        event.target.closest(".group").remove()
        this.updateRewards()
    }

    updateRewards() {
        const container = this.rewardsContainerTarget
        const hiddenField = this.rewardHiddenTarget
        const items = []

        container.querySelectorAll(".group").forEach(group => {
            const rank = group.querySelector(".reward-rank").value
            const prize = group.querySelector(".reward-prize").value
            if (rank.trim() || prize.trim()) {
                items.push({ rank, prize })
            }
        })

        hiddenField.value = JSON.stringify(items)
    }

    formatCurrency(event) {
        let value = event.target.value.replace(/[^0-9]/g, "")
        if (value === "") {
            event.target.value = ""
        } else {
            const numericValue = parseInt(value)
            event.target.value = numericValue.toLocaleString()

            // Update hidden field
            const targetName = event.target.dataset.targetInput
            if (targetName === "amountHidden" && this.hasAmountHiddenTarget) {
                this.amountHiddenTarget.value = numericValue
            } else if (targetName === "penaltyHidden" && this.hasPenaltyHiddenTarget) {
                this.penaltyHiddenTarget.value = numericValue
            }
        }
    }

    updateRefundThreshold(event) {
        // Convert percentage (0-100) to decimal (0-1) for backend
        const percentageValue = parseInt(event.target.value) || 0
        const decimalValue = percentageValue / 100

        // Update the actual field value that will be submitted
        event.target.value = percentageValue

        // Store the decimal value in a data attribute for form submission
        event.target.dataset.decimalValue = decimalValue
    }
}
