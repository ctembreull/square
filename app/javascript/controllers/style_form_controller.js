import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["name", "backgroundColor", "textColor", "strokeColor", "css", "cssDisplay", "preview"]

  connect() {
    // If editing an existing style, parse the CSS and pre-select dropdowns
    const existingCss = this.cssTarget.value
    if (existingCss) {
      this.parseCssAndSelectOptions(existingCss)
    }
    this.buildCss()
  }

  parseCssAndSelectOptions(css) {
    // Extract background-color
    const bgMatch = css.match(/background-color:\s*(#[0-9a-fA-F]{6}|#[0-9a-fA-F]{3})/)
    if (bgMatch) {
      this.selectOptionByValue(this.backgroundColorTarget, bgMatch[1])
    }

    // Extract color (text color)
    const textMatch = css.match(/(?<!background-)color:\s*(#[0-9a-fA-F]{6}|#[0-9a-fA-F]{3})/)
    if (textMatch) {
      this.selectOptionByValue(this.textColorTarget, textMatch[1])
    }

    // Extract text-shadow (stroke color) - grab first color from the shadow
    const strokeMatch = css.match(/text-shadow:.*?(#[0-9a-fA-F]{6}|#[0-9a-fA-F]{3})/)
    if (strokeMatch) {
      this.selectOptionByValue(this.strokeColorTarget, strokeMatch[1])
    }
  }

  selectOptionByValue(selectElement, value) {
    const normalizedValue = value.toLowerCase()
    for (const option of selectElement.options) {
      if (option.value.toLowerCase() === normalizedValue) {
        option.selected = true
        break
      }
    }
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
