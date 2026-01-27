import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["password", "confirmation", "feedback"]

  connect() {
    // Check on connect in case of browser autofill
    this.check()
  }

  check() {
    const password = this.passwordTarget.value
    const confirmation = this.confirmationTarget.value

    // Don't show validation if both are empty
    if (!password && !confirmation) {
      this.#clearValidation()
      return
    }

    // Don't show validation if confirmation hasn't been touched yet
    if (!confirmation) {
      this.#clearValidation()
      return
    }

    if (password === confirmation) {
      this.#showValid()
    } else {
      this.#showInvalid()
    }
  }

  #clearValidation() {
    this.confirmationTarget.classList.remove("is-valid", "is-invalid")
    if (this.hasFeedbackTarget) {
      this.feedbackTarget.classList.add("d-none")
    }
  }

  #showValid() {
    this.confirmationTarget.classList.remove("is-invalid")
    this.confirmationTarget.classList.add("is-valid")
    if (this.hasFeedbackTarget) {
      this.feedbackTarget.classList.remove("d-none", "text-danger")
      this.feedbackTarget.classList.add("text-success")
      this.feedbackTarget.innerHTML = '<span class="fas fa-check me-1"></span>Passwords match'
    }
  }

  #showInvalid() {
    this.confirmationTarget.classList.remove("is-valid")
    this.confirmationTarget.classList.add("is-invalid")
    if (this.hasFeedbackTarget) {
      this.feedbackTarget.classList.remove("d-none", "text-success")
      this.feedbackTarget.classList.add("text-danger")
      this.feedbackTarget.innerHTML = '<span class="fas fa-times me-1"></span>Passwords do not match'
    }
  }
}
