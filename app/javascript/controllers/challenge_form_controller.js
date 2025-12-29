import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = [
        "step", "nav", "progressBar", "dot",
        "costFields", "accountFields", "penaltyFields",
        "bankName", "accountNumber", "accountHolder",
        "thumbnailPreview", "thumbnailInput",
        "invitationCodeSection", "summaryModal", "summaryContent"
    ]

    connect() {
        this.currentStep = 1
        this.showStep()
    }

    next() {
        if (this.currentStep < 5) {
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
            const progress = (this.currentStep / 5) * 100
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
        if (this.hasPenaltyFieldsTarget) this.penaltyFieldsTarget.classList.toggle("hidden", type !== "deposit")
    }

    loadSavedAccount(event) {
        const { bank, account, holder } = event.currentTarget.dataset
        if (this.hasBankNameTarget) this.bankNameTarget.value = bank || ""
        if (this.hasAccountNumberTarget) this.accountNumberTarget.value = account || ""
        if (this.hasAccountHolderTarget) this.accountHolderTarget.value = holder || ""
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
        const value = event.target.value
        const display = this.element.querySelector("#max-participants-display")
        if (display) display.textContent = `${value}명`

        // Smooth progress fill for range
        const min = event.target.min || 2
        const max = event.target.max || 100
        const val = (value - min) / (max - min) * 100
        event.target.style.backgroundSize = val + '% 100%'
    }

    showSummary(event) {
        event.preventDefault()
        if (this.hasSummaryModalTarget) {
            const title = this.element.querySelector("#challenge_title").value
            const start = this.element.querySelector("#challenge_start_date").value
            const end = this.element.querySelector("#challenge_end_date").value
            const costType = this.element.querySelector('input[name="challenge[cost_type]"]').value
            const amount = this.element.querySelector("#challenge_amount").value

            let summaryHtml = `
        <div class="space-y-4">
          <div class="flex justify-between items-center py-3 border-b border-slate-100">
            <span class="text-slate-400 text-xs font-bold">챌린지 명</span>
            <span class="text-slate-900 font-black">${title || '제목 없음'}</span>
          </div>
          <div class="flex justify-between items-center py-3 border-b border-slate-100">
            <span class="text-slate-400 text-xs font-bold">기간</span>
            <span class="text-slate-900 font-bold">${start} ~ ${end}</span>
          </div>
          <div class="flex justify-between items-center py-3 border-b border-slate-100">
            <span class="text-slate-400 text-xs font-bold">참여 비용</span>
            <span class="text-indigo-600 font-black">${costType === 'free' ? '무료' : Number(amount).toLocaleString() + '원'}</span>
          </div>
          <div class="p-4 bg-indigo-50 rounded-2xl text-[11px] text-indigo-600 font-medium leading-relaxed">
            게시물은 개설 후 즉시 노출됩니다. 입력하신 정보가 정확한지 다시 한번 확인해주세요!
          </div>
        </div>
      `
            this.summaryContentTarget.innerHTML = summaryHtml
            this.summaryModalTarget.classList.remove("hidden")
            this.summaryModalTarget.classList.add("flex")
        }
    }

    hideSummary() {
        if (this.hasSummaryModalTarget) {
            this.summaryModalTarget.classList.add("hidden")
            this.summaryModalTarget.classList.remove("flex")
        }
    }

    submitForm() {
        this.element.querySelector("form").submit()
    }
}
