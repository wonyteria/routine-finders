import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = [
        "step", "nav", "dot",
        "regularFrequency",
        "offlineLocation", "onlineLink",
        "feeSection",
        "thumbnailPreview",
        "startDate", "endDate", "recStart", "recEnd"
    ]

    connect() {
        this.currentStep = 1
        this.totalSteps = 5
        this.projectType = 'single' // Default
        this.showStep(1)
    }

    // 날짜 클릭 시 픽커 호출 (아이콘 없이 텍스트 클릭으로 열기)
    openPicker(event) {
        if (event.target.showPicker) {
            event.target.showPicker()
        }
    }

    // 단일 날짜 선택 시 종료일 자동 동기화
    syncDates(event) {
        const selectedDate = event.target.value
        if (this.hasEndDateTarget) {
            this.endDateTarget.value = selectedDate
        }
    }

    // Navigation
    next() {
        if (this.currentStep < this.totalSteps) {
            if (this.validateCurrentStep()) {
                this.showStep(this.currentStep + 1)
            }
        }
    }

    prev() {
        if (this.currentStep > 1) {
            this.showStep(this.currentStep - 1)
        }
    }

    goToStep(event) {
        const targetStep = parseInt(event.currentTarget.dataset.step)
        // 이전 단계 이동은 언제나 가능, 다음 단계는 검증 후 가능
        if (targetStep < this.currentStep || this.validateCurrentStep()) {
            this.showStep(targetStep)
        }
    }

    showStep(stepNumber) {
        this.currentStep = stepNumber

        this.stepTargets.forEach((el, index) => {
            el.classList.toggle("hidden", index + 1 !== stepNumber)
        })

        this.navTargets.forEach((el, index) => {
            const step = index + 1
            const icon = el.querySelector('.nav-icon')
            const text = el.querySelector('.nav-text')

            if (step === stepNumber) {
                icon.className = 'nav-icon w-12 h-12 rounded-2xl flex items-center justify-center transition-all duration-500 bg-orange-600 text-white shadow-xl shadow-orange-200'
                text.className = 'nav-text space-y-0.5 transition-all duration-500 opacity-100'
            } else if (step < stepNumber) {
                icon.className = 'nav-icon w-12 h-12 rounded-2xl flex items-center justify-center transition-all duration-500 bg-emerald-100 text-emerald-600'
                text.className = 'nav-text space-y-0.5 transition-all duration-500 opacity-60'
            } else {
                icon.className = 'nav-icon w-12 h-12 rounded-2xl flex items-center justify-center transition-all duration-500 bg-white text-slate-300'
                text.className = 'nav-text space-y-0.5 transition-all duration-500 opacity-40'
            }
        })

        this.dotTargets.forEach((el, index) => {
            if (index + 1 === stepNumber) {
                el.className = 'h-1.5 rounded-full transition-all duration-700 bg-orange-600 w-8'
            } else if (index + 1 < stepNumber) {
                el.className = 'h-1.5 rounded-full transition-all duration-700 bg-emerald-400 w-2'
            } else {
                el.className = 'h-1.5 rounded-full transition-all duration-700 bg-slate-200 w-2'
            }
        })

        window.scrollTo({ top: 0, behavior: 'smooth' })
    }

    updateMeetingType(event) {
        const type = event.target.value
        this.projectType = type
        if (this.hasRegularFrequencyTarget) {
            this.regularFrequencyTarget.classList.toggle('hidden', type !== 'regular')
        }
    }

    updateLocationType(event) {
        const type = event.target.value
        if (this.hasOfflineLocationTarget) this.offlineLocationTarget.classList.toggle('hidden', type !== 'offline')
        if (this.hasOnlineLinkTarget) this.onlineLinkTarget.classList.toggle('hidden', type !== 'online')
    }

    updateCostType(event) {
        const type = event.target.value
        if (this.hasFeeSectionTarget) {
            this.feeSectionTarget.classList.toggle('hidden', type !== 'fee')
        }
    }

    previewThumbnail(event) {
        const input = event.target
        const file = input.files[0]
        if (file && this.hasThumbnailPreviewTarget) {
            const reader = new FileReader()
            reader.onload = (e) => {
                this.thumbnailPreviewTarget.src = e.target.result
                this.thumbnailPreviewTarget.classList.remove('hidden')
            }
            reader.readAsDataURL(file)
        }
    }

    validateCurrentStep() {
        const currentStepEl = this.stepTargets[this.currentStep - 1]
        if (!currentStepEl) return true

        const requiredInputs = currentStepEl.querySelectorAll('[required]')
        let isValid = true

        requiredInputs.forEach(input => {
            const isVisible = input.offsetParent !== null
            if (isVisible && !input.value.trim()) {
                isValid = false
                input.classList.add('border-red-500', 'ring-2', 'ring-red-100')
            } else {
                input.classList.remove('border-red-500', 'ring-2', 'ring-red-100')
            }
        })

        return isValid
    }
}
