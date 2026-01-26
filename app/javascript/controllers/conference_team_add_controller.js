import { Controller } from "@hotwired/stimulus"

// Handles searchable team dropdown with auto-submit on selection
export default class extends Controller {
  static targets = ["select"]

  connect() {
    // Initialize Choices.js on the team select
    this.choices = new Choices(this.selectTarget, {
      searchEnabled: true,
      searchPlaceholderValue: "Search teams...",
      itemSelectText: "",
      noResultsText: "No teams found",
      shouldSort: false,
      placeholderValue: "Add team..."
    })
  }

  disconnect() {
    this.choices?.destroy()
  }

  submit() {
    if (this.selectTarget.value) {
      this.element.requestSubmit()
    }
  }
}
