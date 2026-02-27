import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "groupCheckbox",
    "memberCheckbox",
    "selectedCount",
    "submitButton",
    "selectAllCheckbox",
    "otherEmails"
  ]

  connect() {
    this.updateSelectedCount()

    // Listen for changes to "other emails" field
    if (this.hasOtherEmailsTarget) {
      this.otherEmailsTarget.addEventListener('input', () => this.updateSelectedCount())
    }
  }

  changePost(event) {
    // Reload page with new post_id parameter
    const postId = event.target.value
    const url = new URL(window.location)
    url.searchParams.set('post_id', postId)
    window.location = url.toString()
  }

  toggleGroup(event) {
    const groupId = event.target.dataset.groupId
    const checked = event.target.checked

    // Check/uncheck all members in this group
    this.memberCheckboxTargets
      .filter(cb => cb.dataset.groupId === groupId)
      .forEach(cb => cb.checked = checked)

    this.updateSelectedCount()
  }

  toggleMember(event) {
    const groupId = event.target.dataset.groupId

    // Update group checkbox state (indeterminate if partial)
    const groupCheckbox = this.groupCheckboxTargets
      .find(cb => cb.dataset.groupId === groupId)

    if (groupCheckbox) {
      const members = this.memberCheckboxTargets
        .filter(cb => cb.dataset.groupId === groupId)
      const checkedCount = members.filter(cb => cb.checked).length

      groupCheckbox.checked = checkedCount > 0
      groupCheckbox.indeterminate = checkedCount > 0 && checkedCount < members.length
    }

    this.updateSelectedCount()
  }

  toggleAll(event) {
    const checked = event.target.checked

    // Check/uncheck all member checkboxes
    this.memberCheckboxTargets.forEach(cb => cb.checked = checked)

    // Sync group checkboxes
    this.groupCheckboxTargets.forEach(cb => {
      cb.checked = checked
      cb.indeterminate = false
    })

    this.updateSelectedCount()
  }

  updateSelectedCount() {
    const count = this.memberCheckboxTargets.filter(cb => cb.checked).length
    this.selectedCountTarget.textContent = count

    // Update master checkbox state
    if (this.hasSelectAllCheckboxTarget) {
      const totalMembers = this.memberCheckboxTargets.length
      this.selectAllCheckboxTarget.checked = count > 0
      this.selectAllCheckboxTarget.indeterminate = count > 0 && count < totalMembers
    }

    // Check if "other emails" field has content
    const hasOtherEmails = this.hasOtherEmailsTarget &&
                           this.otherEmailsTarget.value.trim().length > 0

    // Disable submit if no recipients AND no other emails
    this.submitButtonTargets.forEach(btn => {
      btn.disabled = count === 0 && !hasOtherEmails
    })
  }

}
