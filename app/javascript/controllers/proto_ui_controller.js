import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["fabBg", "fabContent"]

    connect() {
        console.log("✅ ProtoUI Controller Connected")

        // 1. 전역 함수로 등록 (onclick="window.toggleFabMenu()" 지원)
        window.toggleFabMenu = this.toggleFabMenu.bind(this)

        const urlParams = new URLSearchParams(window.location.search);
        if (urlParams.get('show_login') === 'true') {
            window.location.href = '/login'
        }

        document.addEventListener("turbo:frame-missing", (event) => {
            event.preventDefault();
            const { response } = event.detail;
            console.warn("Turbo frame missing, redirecting to:", response.url);
        });
    }

    openModal(event) {
        const modalId = event.currentTarget.dataset.modalId
        const modal = document.getElementById(modalId)
        if (modal) {
            modal.classList.remove('hidden')
            document.body.classList.add('overflow-hidden')
        }
    }

    closeModal(event) {
        const modal = event.currentTarget.closest('[data-modal-target="container"]') || event.currentTarget.closest('.fixed')
        if (modal) {
            modal.classList.add('hidden')
            document.body.classList.remove('overflow-hidden')
        }
    }

    toggleFabMenu() {
        console.log("🔘 FAB Menu Toggle Triggered (Global/Controller)")

        // 1. 메뉴 컨테이너 찾기
        const menu = document.getElementById('fab-menu-sheet')
        if (!menu) {
            console.error("❌ Critical: 'fab-menu-sheet' not found")
            return
        }

        // 2. 내부 요소 찾기 (직접 쿼리)
        // Stimulus Target에 의존하지 않고 직접 찾아서 확실하게 처리
        const bg = menu.querySelector('[data-proto-ui-target="fabBg"]') || menu.querySelector('.bg-black\\/80') || menu.children[0]
        const content = menu.querySelector('[data-proto-ui-target="fabContent"]') || menu.querySelector('.bg-\\[\\#1B1A24\\]') || menu.children[1]

        // 3. 요소 유효성 검사
        if (!bg || !content) {
            console.error("❌ Critical: Sub-elements missing", { bg, content })
            // 최소 동작 보장
            menu.classList.toggle('hidden')
            document.body.classList.toggle('overflow-hidden')
            return
        }

        // 4. 토글 로직
        if (menu.classList.contains('hidden')) {
            // Open
            menu.classList.remove('hidden')
            bg.style.opacity = '0'
            content.style.transform = 'translateY(100%)'

            // Force Reflow
            void menu.offsetWidth

            requestAnimationFrame(() => {
                bg.style.transition = 'opacity 0.3s ease'
                content.style.transition = 'transform 0.4s cubic-bezier(0.34, 1.56, 0.64, 1)'
                bg.style.opacity = '1'
                content.style.transform = 'translateY(0)'
            })
            document.body.classList.add('overflow-hidden')
        } else {
            // Close
            bg.style.opacity = '0'
            content.style.transform = 'translateY(100%)'

            setTimeout(() => {
                menu.classList.add('hidden')
                document.body.classList.remove('overflow-hidden')
                // Reset
                content.style.transform = ''
                content.style.transition = ''
                bg.style.opacity = ''
                bg.style.transition = ''
            }, 300)
        }
    }

    checkLogin(event) {
        const isLoggedIn = document.body.getAttribute('data-logged-in')
        if (isLoggedIn === "false") {
            if (event) {
                event.preventDefault()
                event.stopImmediatePropagation()
            }
            window.location.href = '/login'
            return false
        }
        return true
    }
}
