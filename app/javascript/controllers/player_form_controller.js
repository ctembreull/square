import { Controller } from "@hotwired/stimulus"

// Handles player form field toggling based on player type selection.
// When "Charity" is selected, disables Family dropdown and sets Chances to 0.
export default class extends Controller {
  static targets = ["type", "family", "chances"]

  connect() {
    this.toggleFields()
  }

  typeChanged() {
    this.toggleFields()
  }

  toggleFields() {
    const isCharity = this.typeTarget.value === "Charity"

    // Family dropdown: disable for charities (they don't belong to families)
    this.familyTarget.disabled = isCharity
    if (isCharity) {
      this.familyTarget.value = ""
    }

    // Chances field: disable and set to 0 for charities (they fill unfilled squares)
    this.chancesTarget.disabled = isCharity
    if (isCharity) {
      this.chancesTarget.value = "0"
    }
  }
}
