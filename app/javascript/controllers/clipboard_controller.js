import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { content: String }

  copy() {
    this.#copyToClipboard(this.contentValue).then(() => {
      this.#showSuccess()
    }).catch(err => {
      console.error('Failed to copy:', err)
    })
  }

  #copyToClipboard(text) {
    // Modern Clipboard API (requires secure context)
    if (navigator.clipboard?.writeText) {
      return navigator.clipboard.writeText(text)
    }

    // Fallback for non-secure contexts (HTTP)
    return new Promise((resolve, reject) => {
      const textarea = document.createElement('textarea')
      textarea.value = text
      textarea.style.position = 'fixed'
      textarea.style.opacity = '0'
      document.body.appendChild(textarea)
      textarea.select()

      try {
        document.execCommand('copy')
        resolve()
      } catch (err) {
        reject(err)
      } finally {
        document.body.removeChild(textarea)
      }
    })
  }

  #showSuccess() {
    const originalText = this.element.innerHTML
    this.element.innerHTML = '<span class="fas fa-check me-1"></span> Copied!'
    this.element.classList.remove('btn-outline-secondary')
    this.element.classList.add('btn-success')

    setTimeout(() => {
      this.element.innerHTML = originalText
      this.element.classList.remove('btn-success')
      this.element.classList.add('btn-outline-secondary')
    }, 1500)
  }
}
