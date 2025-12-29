import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="rating"
export default class extends Controller {
  static targets = ["input"]

  set(event) {
    const value = event.currentTarget.dataset.ratingValue
    this.inputTarget.value = value

    // Update visual stars
    const buttons = this.element.querySelectorAll("button[data-rating-value]")
    buttons.forEach(btn => {
      const btnValue = btn.dataset.ratingValue
      const svg = btn.querySelector("svg")
      if (parseInt(btnValue) <= parseInt(value)) {
        svg.classList.remove("text-slate-200")
        svg.classList.add("text-amber-400")
      } else {
        svg.classList.remove("text-amber-400")
        svg.classList.add("text-slate-200")
      }
    })
  }
}
