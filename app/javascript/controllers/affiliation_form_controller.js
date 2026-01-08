import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["league", "conference", "division"]

  connect() {
    // Store all options on connect
    this.allConferences = Array.from(this.conferenceTarget.options).slice(1) // Skip prompt
    this.allDivisions = Array.from(this.divisionTarget.options).slice(1) // Skip prompt

    // Initialize on page load
    this.filterConferences()
    this.filterDivisions()
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

    // Trigger division filter
    this.filterDivisions()
  }

  filterDivisions() {
    const conferenceId = this.conferenceTarget.value
    const currentDivisionId = this.divisionTarget.value

    // Clear current options except prompt
    this.divisionTarget.innerHTML = '<option value="">Select a division</option>'

    if (conferenceId) {
      // Filter divisions by conference
      const filteredDivisions = this.allDivisions.filter(option => {
        return option.dataset.conferenceId === conferenceId
      })

      // Add filtered options
      filteredDivisions.forEach(option => {
        this.divisionTarget.add(option.cloneNode(true))
      })

      // Restore selection if it's still valid
      if (currentDivisionId && filteredDivisions.some(opt => opt.value === currentDivisionId)) {
        this.divisionTarget.value = currentDivisionId
      }
    }
  }
}
