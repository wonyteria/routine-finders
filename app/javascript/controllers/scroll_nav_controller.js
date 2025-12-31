import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["container"]

    scrollLeft() {
        this.containerTarget.scrollBy({
            left: -300,
            behavior: 'smooth'
        })
    }

    scrollRight() {
        this.containerTarget.scrollBy({
            left: 300,
            behavior: 'smooth'
        })
    }
}
