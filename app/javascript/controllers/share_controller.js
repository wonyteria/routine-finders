import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="share"
export default class extends Controller {
    static values = {
        title: String,
        text: String,
        url: String
    }

    share(event) {
        event.preventDefault()

        const shareData = {
            title: this.titleValue,
            text: this.textValue,
            url: this.urlValue || window.location.href
        }

        if (navigator.share) {
            navigator.share(shareData)
                .then(() => console.log('Successful share'))
                .catch((error) => console.log('Error sharing', error))
        } else {
            // Fallback: Copy to clipboard
            this.copyToClipboard(shareData.url)
        }
    }

    copyToClipboard(text) {
        navigator.clipboard.writeText(text).then(() => {
            // You might want to show a toast message here
            alert("링크가 클립보드에 복사되었습니다.")
        }).catch(err => {
            console.error('Could not copy text: ', err)
        })
    }
}
