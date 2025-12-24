import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["loginTab", "registerTab", "loginPanel", "registerPanel"]
  static classes = ["active", "inactive"]

  connect() {
    this.showLogin()
  }

  showLogin() {
    this.loginTabTarget.classList.add(...this.activeClasses)
    this.loginTabTarget.classList.remove(...this.inactiveClasses)
    this.registerTabTarget.classList.add(...this.inactiveClasses)
    this.registerTabTarget.classList.remove(...this.activeClasses)
    
    this.loginPanelTarget.classList.remove("hidden")
    this.registerPanelTarget.classList.add("hidden")
  }

  showRegister() {
    this.registerTabTarget.classList.add(...this.activeClasses)
    this.registerTabTarget.classList.remove(...this.inactiveClasses)
    this.loginTabTarget.classList.add(...this.inactiveClasses)
    this.loginTabTarget.classList.remove(...this.activeClasses)
    
    this.registerPanelTarget.classList.remove("hidden")
    this.loginPanelTarget.classList.add("hidden")
  }
}
