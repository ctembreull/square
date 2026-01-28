import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["groupCheckbox", "memberCheckbox", "progress", "progressBar"]
  static values = { eventId: Number }

  connect() {
    this.restoreState()
    this.updateProgress()
  }

  get storageKey() {
    return `winners_worksheet_${this.eventIdValue}`
  }

  get checkedIds() {
    const stored = localStorage.getItem(this.storageKey)
    return stored ? JSON.parse(stored) : []
  }

  set checkedIds(ids) {
    localStorage.setItem(this.storageKey, JSON.stringify(ids))
  }

  restoreState() {
    const checked = this.checkedIds
    this.memberCheckboxTargets.forEach(checkbox => {
      checkbox.checked = checked.includes(checkbox.value)
      this.updateRowStyle(checkbox)
    })
    this.groupCheckboxTargets.forEach(checkbox => {
      this.syncGroupCheckbox(checkbox)
      this.updateRowStyle(checkbox)
    })
  }

  toggleGroup(event) {
    const groupCheckbox = event.target
    const groupId = groupCheckbox.dataset.groupId
    const memberCheckboxes = this.memberCheckboxTargets.filter(
      cb => cb.dataset.groupId === groupId
    )

    memberCheckboxes.forEach(checkbox => {
      checkbox.checked = groupCheckbox.checked
      this.updateRowStyle(checkbox)
    })
    this.updateRowStyle(groupCheckbox)

    this.saveState()
    this.updateProgress()
  }

  toggleMember(event) {
    const memberCheckbox = event.target
    const groupId = memberCheckbox.dataset.groupId
    const groupCheckbox = this.groupCheckboxTargets.find(
      cb => cb.dataset.groupId === groupId
    )

    this.updateRowStyle(memberCheckbox)
    if (groupCheckbox) {
      this.syncGroupCheckbox(groupCheckbox)
      this.updateRowStyle(groupCheckbox)
    }

    this.saveState()
    this.updateProgress()
  }

  syncGroupCheckbox(groupCheckbox) {
    const groupId = groupCheckbox.dataset.groupId
    const memberCheckboxes = this.memberCheckboxTargets.filter(
      cb => cb.dataset.groupId === groupId
    )
    const allChecked = memberCheckboxes.every(cb => cb.checked)
    const someChecked = memberCheckboxes.some(cb => cb.checked)

    groupCheckbox.checked = allChecked
    groupCheckbox.indeterminate = someChecked && !allChecked
  }

  saveState() {
    const checked = this.memberCheckboxTargets
      .filter(cb => cb.checked)
      .map(cb => cb.value)
    this.checkedIds = checked
  }

  updateProgress() {
    const total = this.memberCheckboxTargets.length
    const checked = this.memberCheckboxTargets.filter(cb => cb.checked).length
    const percent = total > 0 ? Math.round((checked / total) * 100) : 0

    if (this.hasProgressTarget) {
      this.progressTarget.textContent = `${checked} of ${total} checked (${percent}%)`
    }
    if (this.hasProgressBarTarget) {
      this.progressBarTarget.style.width = `${percent}%`
      this.progressBarTarget.setAttribute("aria-valuenow", percent)
    }
  }

  clearAll() {
    localStorage.removeItem(this.storageKey)
    this.memberCheckboxTargets.forEach(cb => {
      cb.checked = false
      this.updateRowStyle(cb)
    })
    this.groupCheckboxTargets.forEach(cb => {
      cb.checked = false
      cb.indeterminate = false
      this.updateRowStyle(cb)
    })
    this.updateProgress()
  }

  updateRowStyle(checkbox) {
    const row = checkbox.closest('tr')
    if (row) {
      row.classList.toggle('worksheet-checked', checkbox.checked)
    }
  }
}
