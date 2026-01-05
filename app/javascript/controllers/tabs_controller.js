import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel"]
  static classes = ["active", "inactive"]
  static values = {
    default: String,
    queryParam: { type: String, default: "tab" }
  }

  connect() {
    const urlParams = new URLSearchParams(window.location.search)
    const activeTab = urlParams.get(this.queryParamValue) || this.defaultValue || this.tabTargets[0]?.dataset.id

    // Validate if the tab from URL exists in this controller
    const isValidTab = this.tabTargets.some(tab => tab.dataset.id === activeTab)
    const actualTab = isValidTab ? activeTab : (this.defaultValue || this.tabTargets[0]?.dataset.id)

    if (actualTab) this.showTab(actualTab, false) // false means don't force URL update on connect if not needed
  }

  change(event) {
    const tabName = event.currentTarget.dataset.id
    this.showTab(tabName)
  }

  showTab(tabName, updateUrl = true) {
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
        tab.dataset.active = "true"
        if (activeClasses.length > 0) tab.classList.add(...activeClasses.filter(c => c))
        if (inactiveClasses.length > 0) tab.classList.remove(...inactiveClasses.filter(c => c))
      } else {
        tab.dataset.active = "false"
        if (activeClasses.length > 0) tab.classList.remove(...activeClasses.filter(c => c))
        if (inactiveClasses.length > 0) tab.classList.add(...inactiveClasses.filter(c => c))
      }
    })

    if (updateUrl) {
      const url = new URL(window.location)
      url.searchParams.set(this.queryParamValue, tabName)
      window.history.replaceState({}, '', url)
    }
  }
}
