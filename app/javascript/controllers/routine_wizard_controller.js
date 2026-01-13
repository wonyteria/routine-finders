import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["step", "indicator", "iconInput", "categoryInput", "dayInput", "titleInput", "displayIcon", "displayTitle", "displayCategory", "displayDays", "mainNextBtn", "submitBtn"]

    connect() {
        this.currentStep = 0
        this.updateUI()
    }

    updateUI() {
        // Show/Hide Steps
        this.stepTargets.forEach((el, i) => {
            el.classList.toggle("hidden", i !== this.currentStep)
        })

        // Update Progress Indicators
        this.indicatorTargets.forEach((el, i) => {
            el.style.background = i <= this.currentStep ? "#6366f1" : "rgba(255,255,255,0.1)"
            el.style.width = i === this.currentStep ? "24px" : "8px"
        })

        this.validateStep()
        this.updateSummary()
    }

    validateStep() {
        let isValid = true
        if (this.currentStep === 0) {
            isValid = this.titleInputTarget.value.trim().length > 0 && this.iconInputTarget.value !== ""
        }

        // Manage Global Next Button visibility and state
        if (this.currentStep < 3) {
            this.mainNextBtnTarget.classList.remove("hidden")
            this.submitBtnTarget.classList.add("hidden")

            this.mainNextBtnTarget.disabled = !isValid
            this.mainNextBtnTarget.classList.toggle("opacity-30", !isValid)
            this.mainNextBtnTarget.classList.toggle("bg-indigo-500", isValid)
            this.mainNextBtnTarget.classList.toggle("bg-slate-800", !isValid)
        } else {
            this.mainNextBtnTarget.classList.add("hidden")
            this.submitBtnTarget.classList.remove("hidden")
        }
    }

    handleKeyup() {
        this.validateStep()
        this.updateSummary()
    }

    next(event) {
        if (event) event.preventDefault()
        if (this.currentStep < this.stepTargets.length - 1) {
            this.currentStep++
            this.updateUI()
        }
    }

    prev(event) {
        if (event) event.preventDefault()
        if (this.currentStep > 0) {
            this.currentStep--
            this.updateUI()
        } else {
            window.history.back()
        }
    }

    selectIcon(event) {
        if (event) event.preventDefault()
        const btn = event.currentTarget
        const icon = btn.dataset.icon

        this.iconInputTarget.value = icon
        this.displayIconTarget.textContent = icon

        // Highlight effect
        const grid = btn.closest('.grid')
        grid.querySelectorAll('button').forEach(b => {
            b.classList.remove('border-indigo-500', 'bg-indigo-500/20', 'scale-110')
            b.classList.add('border-white/5')
        })
        btn.classList.add('border-indigo-500', 'bg-indigo-500/20', 'scale-110')
        btn.classList.remove('border-white/5')

        this.validateStep()
    }

    selectCategory(event) {
        if (event) event.preventDefault()
        const btn = event.currentTarget
        const cat = btn.dataset.category

        this.categoryInputTarget.value = cat
        this.displayCategoryTarget.textContent = '#' + cat

        const grid = btn.closest('.grid')
        grid.querySelectorAll('button').forEach(b => {
            b.classList.remove('bg-indigo-500', 'text-white')
            b.classList.add('bg-white/5', 'text-slate-400')
        })
        btn.classList.remove('bg-white/5', 'text-slate-400')
        btn.classList.add('bg-indigo-500', 'text-white')

        setTimeout(() => this.next(), 200)
    }

    toggleDay(event) {
        if (event) event.preventDefault()
        const btn = event.currentTarget
        btn.classList.toggle('bg-indigo-500')
        btn.classList.toggle('text-white')
        btn.classList.toggle('bg-white/5')
        btn.classList.toggle('text-slate-500')

        this.updateDaysInput()
    }

    updateDaysInput() {
        const selectedDays = Array.from(this.element.querySelectorAll('[data-day].bg-indigo-500'))
            .map(btn => btn.dataset.day)
        this.dayInputTarget.value = JSON.stringify(selectedDays)

        const dayLabels = { "1": "월", "2": "화", "3": "수", "4": "목", "5": "금", "6": "토", "0": "일" }
        const sortedDays = selectedDays.sort((a, b) => (a == "0" ? 7 : a) - (b == "0" ? 7 : b))

        if (selectedDays.length === 7) {
            this.displayDaysTarget.textContent = "매일"
        } else if (selectedDays.length === 0) {
            this.displayDaysTarget.textContent = "요일 선택"
        } else {
            this.displayDaysTarget.textContent = sortedDays.map(d => dayLabels[d]).join(", ")
        }
    }

    updateSummary() {
        this.displayTitleTarget.textContent = this.titleInputTarget.value || ""
    }
}
