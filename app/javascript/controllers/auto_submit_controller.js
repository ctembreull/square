import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { minLength: { type: Number, default: 3 }, delay: { type: Number, default: 300 } }

  connect() {
    this.timeout = null
  }

  search(event) {
    const value = event.target.value

    clearTimeout(this.timeout)

    // Submit if length >= minLength OR if empty (to clear search)
    if (value.length >= this.minLengthValue || value.length === 0) {
      this.timeout = setTimeout(() => {
        this.element.requestSubmit()
      }, this.delayValue)
    }
  }
}
