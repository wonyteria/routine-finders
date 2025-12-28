import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "tab", "panel"]

  open() {
    this.containerTarget.classList.remove("hidden")
    document.body.classList.add("overflow-hidden")
    this.showTab("overview")
  }

  close() {
    this.containerTarget.classList.add("hidden")
    document.body.classList.remove("overflow-hidden")
  }

  closeOnBackground(event) {
    if (event.target === this.containerTarget) {
      this.close()
    }
  }

  switchTab(event) {
    const tabName = event.currentTarget.dataset.tab
    this.showTab(tabName)
  }

  showTab(tabName) {
    // Update tabs
    this.tabTargets.forEach(tab => {
      if (tab.dataset.tab === tabName) {
        tab.classList.add("bg-slate-900", "text-white")
        tab.classList.remove("text-slate-400")
      } else {
        tab.classList.remove("bg-slate-900", "text-white")
        tab.classList.add("text-slate-400")
      }
    })

    // Update panels
    this.panelTargets.forEach(panel => {
      if (panel.dataset.panel === tabName) {
        panel.classList.remove("hidden")
      } else {
        panel.classList.add("hidden")
      }
    })
  }
}
