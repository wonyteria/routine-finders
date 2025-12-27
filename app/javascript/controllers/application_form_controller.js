import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["agreement", "submitButton", "agreementHint", "depositorName"]

  connect() {
    this.checkAgreement()
  }

  checkAgreement() {
    const allChecked = this.agreementTargets.every(checkbox => checkbox.checked)
    
    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.disabled = !allChecked
      
      if (allChecked) {
        this.submitButtonTarget.classList.remove("disabled:bg-slate-300", "disabled:cursor-not-allowed", "disabled:shadow-none")
      } else {
        this.submitButtonTarget.classList.add("disabled:bg-slate-300", "disabled:cursor-not-allowed", "disabled:shadow-none")
      }
    }
    
    if (this.hasAgreementHintTarget) {
      this.agreementHintTarget.classList.toggle("hidden", allChecked)
    }
  }

  useSavedName(event) {
    const name = event.currentTarget.dataset.name
    if (this.hasDepositorNameTarget && name) {
      this.depositorNameTarget.value = name
      this.depositorNameTarget.focus()
    }
  }
}
