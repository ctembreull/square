import { Controller } from "@hotwired/stimulus"

// Highlights the currently displayed post in the archive list
export default class extends Controller {
  static targets = ["item"]

  connect() {
    // Mark first item as active on load
    if (this.itemTargets.length > 0) {
      this.itemTargets[0].classList.add("active")
    }
  }

  select(event) {
    // Remove active from all items
    this.itemTargets.forEach(item => item.classList.remove("active"))
    // Add active to clicked item
    event.currentTarget.closest("[data-post-list-target='item']").classList.add("active")
  }
}
