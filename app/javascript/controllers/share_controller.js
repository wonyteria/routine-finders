import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="share"
export default class extends Controller {
    static values = {
        title: String,
        text: String,
        url: String
    }

    share(event) {
        if (event) event.preventDefault()

        const url = this.urlValue || window.location.href

        // 바로 클립보드에 복사
        this.copyToClipboard(url)
    }

    copyToClipboard(text) {
        navigator.clipboard.writeText(text).then(() => {
            alert("✅ 링크가 복사되었습니다!\n단톡방에 붙여넣어 공유해보세요.")
        }).catch(err => {
            console.error('Could not copy text: ', err)
            alert("❌ 복사에 실패했습니다. 다시 시도해주세요.")
        })
    }
}
