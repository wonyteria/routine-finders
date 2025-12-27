import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "star"]

  connect() {
    this.updateStars()
  }

  update(event) {
    this.updateStars()
  }

  updateStars() {
    const checkedInput = this.inputTargets.find(input => input.checked)
    const rating = checkedInput ? parseInt(checkedInput.value) : 0

    this.starTargets.forEach(star => {
      const value = parseInt(star.dataset.value)
      const path = star.querySelector("path")
      if (path) {
        if (value <= rating) {
          path.classList.remove("text-slate-200")
          path.classList.add("text-amber-400")
        } else {
          path.classList.remove("text-amber-400")
          path.classList.add("text-slate-200")
        }
      }
    })
  }
}
