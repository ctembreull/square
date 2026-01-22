import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { content: String }

  copy() {
    navigator.clipboard.writeText(this.contentValue).then(() => {
      // Brief visual feedback
      const originalText = this.element.innerHTML
      this.element.innerHTML = '<span class="fas fa-check me-1"></span> Copied!'
      this.element.classList.remove('btn-outline-secondary')
      this.element.classList.add('btn-success')

      setTimeout(() => {
        this.element.innerHTML = originalText
        this.element.classList.remove('btn-success')
        this.element.classList.add('btn-outline-secondary')
      }, 1500)
    }).catch(err => {
      console.error('Failed to copy:', err)
    })
  }
}
