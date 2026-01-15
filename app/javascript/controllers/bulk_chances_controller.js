import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["singleInput", "familyInput", "individualInput", "preview", "total"]
  static values = {
    singleCount: Number,
    familyCount: Number,
    individualCount: Number,
    currentTotal: Number,
    singleCurrent: Number,
    familyCurrent: Number,
    individualCurrent: Number
  }

  connect() {
    this.calculate()
  }

  calculate() {
    const singleChances = this.singleInputTarget.value !== "" ? parseInt(this.singleInputTarget.value) : null
    const familyChances = this.familyInputTarget.value !== "" ? parseInt(this.familyInputTarget.value) : null
    const individualChances = this.individualInputTarget.value !== "" ? parseInt(this.individualInputTarget.value) : null

    // Start with current total
    let projectedTotal = this.currentTotalValue

    // For each type with a value entered, subtract current sum and add new calculated sum
    if (singleChances !== null) {
      projectedTotal = projectedTotal - this.singleCurrentValue + (singleChances * this.singleCountValue)
    }
    if (familyChances !== null) {
      projectedTotal = projectedTotal - this.familyCurrentValue + (familyChances * this.familyCountValue)
    }
    if (individualChances !== null) {
      projectedTotal = projectedTotal - this.individualCurrentValue + (individualChances * this.individualCountValue)
    }

    // Update preview display
    this.totalTarget.textContent = projectedTotal

    // Update color based on total
    this.totalTarget.classList.remove("text-success", "text-warning", "text-danger")
    if (projectedTotal === 100) {
      this.totalTarget.classList.add("text-success")
    } else if (projectedTotal > 100) {
      this.totalTarget.classList.add("text-danger")
    } else {
      this.totalTarget.classList.add("text-warning")
    }

    // Show/hide preview based on whether any values are entered
    if (singleChances !== null || familyChances !== null || individualChances !== null) {
      this.previewTarget.classList.remove("d-none")
    } else {
      this.previewTarget.classList.add("d-none")
    }
  }
}
