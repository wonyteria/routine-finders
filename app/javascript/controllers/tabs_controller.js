import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel"]
  static values = { default: String }

  connect() {
    this.showTab(this.defaultValue || this.tabTargets[0]?.dataset.tab)
  }

  show(event) {
    const tabName = event.currentTarget.dataset.tab
    this.showTab(tabName)
  }

  showTab(tabName) {
    // Update tab states
    this.tabTargets.forEach(tab => {
      if (tab.dataset.tab === tabName) {
        tab.dataset.active = true
      } else {
        delete tab.dataset.active
      }
    })

    // Update panel visibility
    this.panelTargets.forEach(panel => {
      if (panel.dataset.panel === tabName) {
        panel.classList.remove("hidden")
      } else {
        panel.classList.add("hidden")
      }
    })
  }
}
