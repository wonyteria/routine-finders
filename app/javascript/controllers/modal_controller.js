import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { autoOpen: Boolean }
  static targets = ["container"]

  connect() {
    document.addEventListener("keydown", this.handleKeydown.bind(this))
    if (this.autoOpenValue) {
      this.open()
    }
  }

  disconnect() {
    document.removeEventListener("keydown", this.handleKeydown.bind(this))
  }

  open() {
    this.containerTarget.classList.remove("hidden")
    document.body.classList.add("overflow-hidden")
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

  handleKeydown(event) {
    if (event.key === "Escape" && !this.containerTarget.classList.contains("hidden")) {
      this.close()
    }
  }
}
