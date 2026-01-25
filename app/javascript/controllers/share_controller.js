import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="share"
export default class extends Controller {
    static values = {
        title: String,
        text: String,
        url: String,
        image: String
    }

    share(event) {
        if (event) event.preventDefault()

        const shareData = {
            title: this.titleValue || "Routine Finders",
            text: this.textValue || "함께 습관을 만들어가는 루틴 챌린지 플랫폼",
            url: this.urlValue || window.location.href,
            image: this.imageValue || (window.location.origin + "/rf_symbol_v9.png")
        }

        // 1. Try Native Share (best for mobile)
        if (navigator.share) {
            navigator.share({
                title: shareData.title,
                text: shareData.text,
                url: shareData.url
            }).catch((error) => console.log('Error sharing', error))
        } else {
            // 2. Fallback to Kakao Sharing if on web/desktop
            this.shareToKakao(shareData)
        }
    }

    shareToKakao(data) {
        if (typeof Kakao !== 'undefined' && Kakao.isInitialized()) {
            Kakao.Share.sendDefault({
                objectType: 'feed',
                content: {
                    title: data.title,
                    description: data.text,
                    imageUrl: data.image,
                    link: {
                        mobileWebUrl: data.url,
                        webUrl: data.url,
                    },
                },
                buttons: [
                    {
                        title: '보러가기',
                        link: {
                            mobileWebUrl: data.url,
                            webUrl: data.url,
                        },
                    },
                ],
            });
        } else {
            // 3. Last fallback: Clipboard
            this.copyToClipboard(data.url)
        }
    }

    copyToClipboard(text) {
        navigator.clipboard.writeText(text).then(() => {
            alert("링크가 클립보드에 복사되었습니다. 단톡방에 붙여넣어 공유해보세요!")
        }).catch(err => {
            console.error('Could not copy text: ', err)
        })
    }
}
