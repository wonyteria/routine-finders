import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static values = {
        summary: String,
        detailed: String
    }

    copySummary() {
        this.copyToClipboard(this.summaryValue, "단톡방용 요약 문구가 복사되었습니다.")
    }

    copyDetailed() {
        this.copyToClipboard(this.detailedValue, "상세형 전체 리포트가 복사되었습니다.")
    }

    copyToClipboard(text, message) {
        if (!text) return

        navigator.clipboard.writeText(text).then(() => {
            this.showToast(message)
        }).catch(err => {
            console.error('Failed to copy: ', err)
            alert("복사에 실패했습니다. 직접 선택해서 복사해주세요.")
        })
    }

    showToast(message) {
        if (window.showToast) {
            window.showToast(message, "success")
        } else {
            console.log("Toast: " + message)
        }
    }
}
