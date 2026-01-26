import { Controller } from "@hotwired/stimulus"

// Handles auto-submit when a team is selected from the dropdown
export default class extends Controller {
  static targets = ["select"]

  submit() {
    if (this.selectTarget.value) {
      this.element.requestSubmit()
    }
  }
}
