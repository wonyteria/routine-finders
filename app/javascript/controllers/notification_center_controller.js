import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["masterButton", "masterIndicator", "detailContainer", "detail", "detailButton", "detailIndicator"]

    connect() {
        // 초기화: 데이터 속성을 기준으로 상태 동기화
        this.syncStateFromData()
    }

    // 마스터 토글 클릭 핸들러
    toggleMaster(event) {
        if (event) event.preventDefault()

        const currentChecked = this.masterButtonTarget.dataset.checked === "true"
        const newChecked = !currentChecked

        this.setMasterState(newChecked)
        this.setAllDetailsState(newChecked)
    }

    // 상세 토글 클릭 핸들러
    toggleDetail(event) {
        if (event) event.preventDefault()

        const wrapper = event.currentTarget
        const btn = wrapper.querySelector('[data-notification-center-target="detailButton"]')
        if (!btn) return

        const currentChecked = btn.dataset.checked === "true"
        const newChecked = !currentChecked

        this.setDetailState(wrapper, newChecked)
        this.checkMasterStateCompliance()
    }

    // 초기 상태 동기화
    syncStateFromData() {
        this.checkMasterStateCompliance()
    }

    // 모든 상세 설정 상태가 켜져있는지 확인하고 마스터 업데이트
    checkMasterStateCompliance() {
        if (!this.hasDetailTarget) return

        const allDetailsOn = this.detailTargets.every(detail => {
            const btn = detail.querySelector('[data-notification-center-target="detailButton"]')
            return btn && btn.dataset.checked === "true"
        })

        // 마스터 상태 업데이트 (UI만, 하위 전파 X)
        this.setMasterState(allDetailsOn)
    }

    setMasterState(checked) {
        if (!this.hasMasterButtonTarget) return

        this.masterButtonTarget.dataset.checked = checked

        if (checked) {
            // ON Style
            this.masterButtonTarget.classList.replace("justify-start", "justify-end")
            this.masterButtonTarget.classList.replace("bg-slate-800", "bg-indigo-500")
            this.masterIndicatorTarget.classList.replace("bg-slate-600", "bg-white")

            if (this.hasDetailContainerTarget) {
                this.detailContainerTarget.classList.remove("opacity-50", "pointer-events-none")
            }
        } else {
            // OFF Style
            this.masterButtonTarget.classList.replace("justify-end", "justify-start")
            this.masterButtonTarget.classList.replace("bg-indigo-500", "bg-slate-800")
            this.masterIndicatorTarget.classList.replace("bg-white", "bg-slate-600")
        }
    }

    setDetailState(wrapper, checked) {
        const btn = wrapper.querySelector('[data-notification-center-target="detailButton"]')
        const ind = wrapper.querySelector('[data-notification-center-target="detailIndicator"]')

        if (!btn) return

        btn.dataset.checked = checked

        if (checked) {
            btn.classList.replace("justify-start", "justify-end")
            btn.classList.remove("bg-indigo-500/20")
            btn.classList.add("bg-indigo-500")
            if (ind) ind.classList.replace("bg-indigo-400", "bg-white")
        } else {
            btn.classList.replace("justify-end", "justify-start")
            btn.classList.remove("bg-indigo-500")
            btn.classList.add("bg-indigo-500/20")
            if (ind) ind.classList.replace("bg-white", "bg-indigo-400")
        }
    }

    setAllDetailsState(checked) {
        this.detailTargets.forEach(detail => {
            this.setDetailState(detail, checked)
        })
    }
}
