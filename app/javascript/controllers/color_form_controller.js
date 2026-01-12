import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["hex", "swatch"]

  connect() {
    this.updateSwatch()
  }

  updateSwatch() {
    const hex = this.hexTarget.value.replace(/[^0-9a-fA-F]/g, "")

    if (hex.length === 6) {
      this.swatchTarget.style.backgroundColor = `#${hex}`
      this.swatchTarget.style.borderColor = "#dee2e6"
    } else {
      // Show a neutral gray when hex is incomplete
      this.swatchTarget.style.backgroundColor = "#f8f9fa"
      this.swatchTarget.style.borderColor = "#dee2e6"
    }
  }
}
