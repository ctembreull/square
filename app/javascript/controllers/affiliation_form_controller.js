import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["league", "conference"]

  connect() {
    // Store all options on connect
    this.allConferences = Array.from(this.conferenceTarget.options).slice(1) // Skip prompt

    // Initialize on page load
    this.filterConferences()
  }

  filterConferences() {
    const leagueId = this.leagueTarget.value
    const currentConferenceId = this.conferenceTarget.value

    // Clear current options except prompt
    this.conferenceTarget.innerHTML = '<option value="">Select a conference</option>'

    if (leagueId) {
      // Filter conferences by league
      const filteredConferences = this.allConferences.filter(option => {
        return option.dataset.leagueId === leagueId
      })

      // Add filtered options
      filteredConferences.forEach(option => {
        this.conferenceTarget.add(option.cloneNode(true))
      })

      // Restore selection if it's still valid
      if (currentConferenceId && filteredConferences.some(opt => opt.value === currentConferenceId)) {
        this.conferenceTarget.value = currentConferenceId
      }
    }
  }
}
