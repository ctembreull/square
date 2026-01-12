import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["name", "backgroundColor", "textColor", "strokeColor", "css", "cssDisplay", "preview"]

  connect() {
    this.buildCss()
  }

  updatePreview() {
    const name = this.nameTarget.value || "Style Name"
    this.previewTarget.textContent = name
  }

  buildCss() {
    const bgColor = this.backgroundColorTarget.value
    const textColor = this.textColorTarget.value
    const strokeColor = this.strokeColorTarget.value

    let css = ""

    if (bgColor) {
      css += `background-color: ${bgColor}; `
    }

    if (textColor) {
      css += `color: ${textColor}; `
    }

    if (strokeColor) {
      css += `text-shadow: 1px 1px 0 ${strokeColor}, -1px 1px 0 ${strokeColor}, 1px -1px 0 ${strokeColor}, -1px -1px 0 ${strokeColor}; `
    }

    // Update hidden field for form submission
    this.cssTarget.value = css

    // Update display textarea
    this.cssDisplayTarget.value = css

    // Update live preview
    this.previewTarget.style.cssText = css + "padding: 12px 24px; border-radius: 4px; font-size: 1.5rem; font-weight: bold;"

    // Update preview text
    this.updatePreview()
  }
}
