import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["tab", "panel"]
    static classes = ["active", "inactive"]
    static values = {
        default: String
    }

    connect() {
        const activeTab = this.defaultValue || this.tabTargets[0]?.dataset.id
        if (activeTab) this.showTab(activeTab)
    }

    change(event) {
        const tabName = event.currentTarget.dataset.id
        this.showTab(tabName)
    }

    showTab(tabName) {
        if (!tabName) return

        // Update Panels
        this.panelTargets.forEach(panel => {
            if (panel.dataset.id === tabName) {
                panel.classList.remove("hidden")
            } else {
                panel.classList.add("hidden")
            }
        })

        // Update Tabs
        this.tabTargets.forEach(tab => {
            const isActive = tab.dataset.id === tabName
            const activeClasses = this.hasActiveClass ? this.activeClasses : []
            const inactiveClasses = this.hasInactiveClass ? this.inactiveClasses : []

            if (isActive) {
                if (activeClasses.length > 0) tab.classList.add(...activeClasses.filter(c => c))
                if (inactiveClasses.length > 0) tab.classList.remove(...inactiveClasses.filter(c => c))
            } else {
                if (activeClasses.length > 0) tab.classList.remove(...activeClasses.filter(c => c))
                if (inactiveClasses.length > 0) tab.classList.add(...inactiveClasses.filter(c => c))
            }
        })
    }
}
