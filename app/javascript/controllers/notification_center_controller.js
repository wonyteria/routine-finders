import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["masterButton", "masterIndicator", "detailContainer", "detail", "detailButton", "detailIndicator"]

    connect() {
        console.log("✅ Notification Center Connected")
        // Stimulus 내부 디버깅 활성화
        this.application.debug = true
        this.syncStateFromData()
    }

    // 마스터 토글 클릭
    toggleMaster(event) {
        if (event) {
            event.preventDefault()
            event.stopPropagation()
        }

        // 중복 실행 방지 (0.1초)
        if (this.isToggling) return
        this.isToggling = true
        setTimeout(() => { this.isToggling = false }, 100)

        const currentChecked = this.masterButtonTarget.dataset.checked === "true"
        const newChecked = !currentChecked

        console.log("Master Toggle Triggered:", newChecked)
        this.setMasterState(newChecked)
        this.setAllDetailsState(newChecked)
    }

    // 상세 토글 클릭
    toggleDetail(event) {
        if (event) {
            event.preventDefault()
            event.stopPropagation()
        }

        // 중복 실행 방지
        if (this.isTogglingDetail) return
        this.isTogglingDetail = true
        setTimeout(() => { this.isTogglingDetail = false }, 100)

        // 마스터가 꺼져있으면 작동하지 않도록 함 (UI적으로만)
        if (this.masterButtonTarget.dataset.checked === "false") {
            console.log("Detail Toggle blocked because Master is OFF")
            return
        }

        const wrapper = event.currentTarget
        const btn = wrapper.querySelector('[data-notification-center-target="detailButton"]')
        if (!btn) return

        const currentChecked = btn.dataset.checked === "true"
        const newChecked = !currentChecked

        console.log("Detail Toggle Triggered:", newChecked)
        this.setDetailState(wrapper, newChecked)
        this.checkMasterStateCompliance()
    }

    // 모든 상세 설정 상태가 켜져있는지 확인하여 마스터 업데이트
    checkMasterStateCompliance() {
        if (!this.hasDetailTarget) return

        const allDetailsOn = this.detailTargets.every(detail => {
            const btn = detail.querySelector('[data-notification-center-target="detailButton"]')
            return btn && btn.dataset.checked === "true"
        })

        // 마스터 상태 업데이트 (UI만 변경, 자식 전파 X)
        this.setMasterState(allDetailsOn)
    }

    syncStateFromData() {
        // 초기 데이터에 따른 UI 동기화
        const isMasterOn = this.masterButtonTarget.dataset.checked === "true"
        this.setMasterState(isMasterOn)

        this.detailTargets.forEach(detail => {
            const btn = detail.querySelector('[data-notification-center-target="detailButton"]')
            if (btn) {
                this.setDetailState(detail, btn.dataset.checked === "true")
            }
        })
    }

    setMasterState(checked) {
        if (!this.hasMasterButtonTarget) return
        console.log("Applying Master State UI:", checked)

        this.masterButtonTarget.dataset.checked = checked.toString()

        if (checked) {
            // ON Style: Purple background, circle on right
            this.masterButtonTarget.className = "w-11 h-6 rounded-full relative p-0.5 flex items-center transition-all bg-indigo-500 justify-end px-1"
            this.masterIndicatorTarget.className = "w-5 h-5 rounded-full transition-all shadow-sm bg-white"

            if (this.hasDetailContainerTarget) {
                this.detailContainerTarget.classList.remove("opacity-50", "pointer-events-none")
            }
        } else {
            // OFF Style: Dark background, circle on left
            this.masterButtonTarget.className = "w-11 h-6 rounded-full relative p-0.5 flex items-center transition-all bg-slate-800 justify-start px-1"
            this.masterIndicatorTarget.className = "w-5 h-5 rounded-full transition-all shadow-sm bg-slate-600"

            if (this.hasDetailContainerTarget) {
                this.detailContainerTarget.classList.add("opacity-50", "pointer-events-none")
            }
        }
    }

    setDetailState(wrapper, checked) {
        const btn = wrapper.querySelector('[data-notification-center-target="detailButton"]')
        const ind = wrapper.querySelector('[data-notification-center-target="detailIndicator"]')

        if (!btn) return
        console.log("Applying Detail State UI:", checked)

        btn.dataset.checked = checked.toString()

        if (checked) {
            btn.className = "w-10 h-5 rounded-full relative p-0.5 flex items-center border border-indigo-500/30 transition-all bg-indigo-500 justify-end px-1"
            if (ind) ind.className = "w-4 h-4 rounded-full shadow-sm transition-all bg-white"
        } else {
            btn.className = "w-10 h-5 rounded-full relative p-0.5 flex items-center border border-indigo-500/30 transition-all bg-indigo-500/20 justify-start px-1"
            if (ind) ind.className = "w-4 h-4 rounded-full shadow-sm transition-all bg-indigo-400"
        }
    }

    setAllDetailsState(checked) {
        this.detailTargets.forEach(detail => {
            this.setDetailState(detail, checked)
        })
    }

    save() {
        console.log("Save clicked")
        alert("알림 설정이 저장되었습니다.")
        const modal = this.element.closest('.fixed')
        if (modal) {
            modal.classList.add('hidden')
            document.body.classList.remove('overflow-hidden')
        }
    }
}
