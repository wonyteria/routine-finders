import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["masterButton", "masterIndicator", "detailContainer", "detail", "detailButton", "detailIndicator"]

    connect() {
        this.syncMasterState()
    }

    toggleMaster(event) {
        const isCurrentlyOn = this.masterButtonTarget.classList.contains("justify-end")
        const newState = !isCurrentlyOn

        this.updateMasterUI(newState)
        this.updateAllDetailsUI(newState)
    }

    toggleDetail(event) {
        const detailWrapper = event.currentTarget
        const btn = detailWrapper.querySelector('[data-notification-center-target="detailButton"]')
        const isCurrentlyOn = btn.classList.contains("justify-end")
        const newState = !isCurrentlyOn

        this.updateDetailUI(detailWrapper, newState)
        this.syncMasterState()
    }

    syncMasterState() {
        const allOn = this.detailTargets.every(detail => {
            const btn = detail.querySelector('[data-notification-center-target="detailButton"]')
            return btn.classList.contains("justify-end")
        })

        this.updateMasterUI(allOn)
    }

    updateMasterUI(state) {
        if (state) {
            this.masterButtonTarget.classList.replace("justify-start", "justify-end")
            this.masterButtonTarget.classList.replace("bg-slate-800", "bg-indigo-500")
            this.masterIndicatorTarget.classList.replace("bg-slate-600", "bg-white")
            if (this.hasDetailContainerTarget) {
                this.detailContainerTarget.classList.remove("opacity-40", "pointer-events-none")
            }
        } else {
            this.masterButtonTarget.classList.replace("justify-end", "justify-start")
            this.masterButtonTarget.classList.replace("bg-indigo-500", "bg-slate-800")
            this.masterIndicatorTarget.classList.replace("bg-white", "bg-slate-600")
            if (this.hasDetailContainerTarget) {
                this.detailContainerTarget.classList.add("opacity-40", "pointer-events-none")
            }
        }
    }

    updateDetailUI(wrapper, state) {
        const btn = wrapper.querySelector('[data-notification-center-target="detailButton"]')
        const ind = wrapper.querySelector('[data-notification-center-target="detailIndicator"]')

        if (state) {
            btn.classList.replace("justify-start", "justify-end")
            btn.classList.remove("bg-indigo-500/20")
            btn.classList.add("bg-indigo-500")
            ind?.classList.replace("bg-indigo-400", "bg-white")
        } else {
            btn.classList.replace("justify-end", "justify-start")
            btn.classList.remove("bg-indigo-500")
            btn.classList.add("bg-indigo-500/20")
            ind?.classList.replace("bg-white", "bg-indigo-400")
        }
    }

    updateAllDetailsUI(state) {
        this.detailTargets.forEach(detail => {
            this.updateDetailUI(detail, state)
        })
    }
}
