import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    toggle(event) {
        const costType = event.target.value
        const costFields = document.querySelector('[data-cost-fields]')
        const penaltyField = document.querySelector('[data-penalty-field]')

        if (costType === 'free') {
            costFields.classList.add('hidden')
        } else {
            costFields.classList.remove('hidden')

            if (costType === 'deposit') {
                penaltyField.classList.remove('hidden')
            } else {
                penaltyField.classList.add('hidden')
            }
        }
    }
}
