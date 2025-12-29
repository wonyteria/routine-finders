import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="flash"
export default class extends Controller {
  static values = {
    timeout: Number
  }

  connect() {
    this.timeoutValue = this.timeoutValue || 3000

    // 약간의 지연 후 등장 애니메이션 및 프로그레스 바 시작
    requestAnimationFrame(() => {
      this.element.classList.add("visible")
    })

    // 설정된 시간 후 삭제
    setTimeout(() => {
      this.dismiss()
    }, this.timeoutValue)
  }

  dismiss() {
    // 사라지는 애니메이션 클래스 추가
    this.element.classList.add("opacity-0", "translate-y-[-20px]", "scale-95")
    this.element.style.transition = "all 0.5s ease-in-out"

    // 애니메이션 종료 후 요소 제거
    setTimeout(() => {
      this.element.remove()
    }, 500)
  }
}
