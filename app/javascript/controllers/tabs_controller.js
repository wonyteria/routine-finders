import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel"]
  static classes = ["active", "inactive"]
  static values = { default: String }

  connect() {
    const urlParams = new URLSearchParams(window.location.search)
    const activeTab = urlParams.get('tab') || this.defaultValue || this.tabTargets[0]?.dataset.id
    if (activeTab) this.showTab(activeTab)
  }

  change(event) {
    const tabName = event.currentTarget.dataset.id
    this.showTab(tabName)
  }

  showTab(tabName) {
    this.tabTargets.forEach(tab => {
      const isActive = tab.dataset.id === tabName
      tab.dataset.active = isActive
      if (isActive) {
        if (this.hasActiveClasses) tab.classList.add(...this.activeClasses)
        if (this.hasInactiveClasses) tab.classList.remove(...this.inactiveClasses)
      } else {
        if (this.hasActiveClasses) tab.classList.remove(...this.activeClasses)
        if (this.hasInactiveClasses) tab.classList.add(...this.inactiveClasses)
      }
    })

    this.panelTargets.forEach(panel => {
      if (panel.dataset.id === tabName) {
        panel.classList.remove("hidden")
      } else {
        panel.classList.add("hidden")
      }
    })
  }
}
