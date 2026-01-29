import { Controller } from "@hotwired/stimulus"

// Choices.js is loaded via CDN and attaches to window
// We'll access it dynamically since the CDN version isn't an ES module
export default class extends Controller {
  static targets = ["league", "awayTeam", "awayStyle", "homeTeam", "homeStyle", "periodPrize", "finalPrize", "awayBanner", "homeBanner", "awayLastUsed", "homeLastUsed"]

  connect() {
    // Store team data for last_used lookup
    this.teamsData = {}
    // Initialize Choices.js on team selects
    this.awayTeamChoices = new Choices(this.awayTeamTarget, {
      searchEnabled: true,
      searchPlaceholderValue: "Search teams...",
      itemSelectText: "",
      noResultsText: "No teams found",
      noChoicesText: "Select a league first",
      shouldSort: false,
      placeholderValue: "Select away team"
    })

    this.homeTeamChoices = new Choices(this.homeTeamTarget, {
      searchEnabled: true,
      searchPlaceholderValue: "Search teams...",
      itemSelectText: "",
      noResultsText: "No teams found",
      noChoicesText: "Select a league first",
      shouldSort: false,
      placeholderValue: "Select home team"
    })

    // Initialize Choices.js on style selects
    this.awayStyleChoices = new Choices(this.awayStyleTarget, {
      searchEnabled: false,
      itemSelectText: "",
      noChoicesText: "Select a team first",
      shouldSort: false,
      placeholderValue: "Select style"
    })

    this.homeStyleChoices = new Choices(this.homeStyleTarget, {
      searchEnabled: false,
      itemSelectText: "",
      noChoicesText: "Select a team first",
      shouldSort: false,
      placeholderValue: "Select style"
    })

    // Load teams if league is pre-selected (edit form)
    if (this.leagueTarget.value) {
      this.loadTeamsForLeague(this.leagueTarget.value)
    }
  }

  disconnect() {
    // Clean up Choices instances
    this.awayTeamChoices?.destroy()
    this.homeTeamChoices?.destroy()
    this.awayStyleChoices?.destroy()
    this.homeStyleChoices?.destroy()
  }

  // Called when league selection changes
  leagueChanged(event) {
    const leagueId = event.target.value

    // Clear team selections
    this.awayTeamChoices.clearStore()
    this.homeTeamChoices.clearStore()
    this.awayStyleChoices.clearStore()
    this.homeStyleChoices.clearStore()

    // Clear team data and hide last used icons
    this.teamsData = {}
    if (this.hasAwayLastUsedTarget) this.awayLastUsedTarget.classList.add("d-none")
    if (this.hasHomeLastUsedTarget) this.homeLastUsedTarget.classList.add("d-none")

    if (leagueId) {
      this.loadTeamsForLeague(leagueId)
    } else {
      this.awayTeamChoices.setChoices([{ value: "", label: "Select a league first", disabled: true }], "value", "label", true)
      this.homeTeamChoices.setChoices([{ value: "", label: "Select a league first", disabled: true }], "value", "label", true)
    }
  }

  // Called when away team selection changes
  awayTeamChanged(event) {
    const teamId = event.target.value
    const selectedOption = this.awayTeamChoices.getValue()
    // Clear old style selection and set team name - new style will be applied after loadStylesForTeam completes
    this.awayStyleTarget.dataset.selectedValue = ""
    this.updateBanner(this.awayBannerTarget, selectedOption?.label || "Away Team", "")
    this.loadStylesForTeam(teamId, this.awayStyleChoices, this.awayStyleTarget, this.awayBannerTarget)
    this.updateLastUsed(teamId, this.awayLastUsedTarget)
  }

  // Called when home team selection changes
  homeTeamChanged(event) {
    const teamId = event.target.value
    const selectedOption = this.homeTeamChoices.getValue()
    // Clear old style selection and set team name - new style will be applied after loadStylesForTeam completes
    this.homeStyleTarget.dataset.selectedValue = ""
    this.updateBanner(this.homeBannerTarget, selectedOption?.label || "Home Team", "")
    this.loadStylesForTeam(teamId, this.homeStyleChoices, this.homeStyleTarget, this.homeBannerTarget)
    this.updateLastUsed(teamId, this.homeLastUsedTarget)
  }

  // Update the last used icon visibility and tooltip
  updateLastUsed(teamId, iconTarget) {
    if (!this.hasAwayLastUsedTarget && !this.hasHomeLastUsedTarget) return

    const team = this.teamsData[teamId]
    if (team?.last_used) {
      iconTarget.classList.remove("d-none")
      iconTarget.setAttribute("title", `Last used: ${team.last_used}`)
      // Reinitialize tooltip if Bootstrap is available
      if (typeof bootstrap !== "undefined") {
        const existingTooltip = bootstrap.Tooltip.getInstance(iconTarget)
        if (existingTooltip) existingTooltip.dispose()
        new bootstrap.Tooltip(iconTarget)
      }
    } else {
      iconTarget.classList.add("d-none")
    }
  }

  // Called when away style selection changes
  awayStyleChanged(event) {
    const styleClass = event.target.value
    this.updateBanner(this.awayBannerTarget, null, styleClass)
  }

  // Called when home style selection changes
  homeStyleChanged(event) {
    const styleClass = event.target.value
    this.updateBanner(this.homeBannerTarget, null, styleClass)
  }

  // Update banner text and/or class
  updateBanner(bannerTarget, text, styleClass) {
    if (text !== null) {
      bannerTarget.textContent = text
    }
    if (styleClass !== null) {
      // Remove any existing style classes (they follow pattern like "team-name-style")
      // Preserve layout classes: m-0, p-3, p-4
      const preserveClasses = ["m-0", "p-3", "p-4"]
      const classes = Array.from(bannerTarget.classList)
      classes.forEach(cls => {
        if (!preserveClasses.includes(cls)) {
          bannerTarget.classList.remove(cls)
        }
      })
      // Add new style class if provided
      if (styleClass) {
        bannerTarget.classList.add(styleClass)
      }
    }
  }

  // Called when period prize changes - double it for final prize
  periodPrizeChanged(event) {
    const periodPrize = parseFloat(event.target.value) || 0
    this.finalPrizeTarget.value = periodPrize * 2
  }

  // Called when final prize changes - halve it for period prize
  finalPrizeChanged(event) {
    const finalPrize = parseFloat(event.target.value) || 0
    this.periodPrizeTarget.value = finalPrize / 2
  }

  async loadTeamsForLeague(leagueId) {
    try {
      const response = await fetch(`/leagues/${leagueId}/teams.json`)
      const teams = await response.json()

      // Store team data for last_used lookup
      teams.forEach(team => {
        this.teamsData[team.id.toString()] = team
      })

      const choices = teams.map(team => ({
        value: team.id.toString(),
        label: team.display_name
      }))

      // Add placeholder
      choices.unshift({ value: "", label: "Select team", placeholder: true })

      this.awayTeamChoices.setChoices(choices, "value", "label", true)
      this.homeTeamChoices.setChoices(choices, "value", "label", true)

      // If editing, restore selections
      const awayTeamId = this.awayTeamTarget.dataset.selectedValue
      const homeTeamId = this.homeTeamTarget.dataset.selectedValue

      if (awayTeamId) {
        this.awayTeamChoices.setChoiceByValue(awayTeamId)
        this.loadStylesForTeam(awayTeamId, this.awayStyleChoices, this.awayStyleTarget, this.awayBannerTarget)
        if (this.hasAwayLastUsedTarget) this.updateLastUsed(awayTeamId, this.awayLastUsedTarget)
      }
      if (homeTeamId) {
        this.homeTeamChoices.setChoiceByValue(homeTeamId)
        this.loadStylesForTeam(homeTeamId, this.homeStyleChoices, this.homeStyleTarget, this.homeBannerTarget)
        if (this.hasHomeLastUsedTarget) this.updateLastUsed(homeTeamId, this.homeLastUsedTarget)
      }
    } catch (error) {
      console.error("Failed to load teams:", error)
    }
  }

  async loadStylesForTeam(teamId, choicesInstance, selectTarget, bannerTarget) {
    choicesInstance.clearStore()

    if (!teamId) {
      choicesInstance.setChoices([{ value: "", label: "Select a team first", disabled: true }], "value", "label", true)
      if (bannerTarget) this.updateBanner(bannerTarget, null, "")
      return
    }

    try {
      const response = await fetch(`/teams/${teamId}/styles.json`)
      const styles = await response.json()

      const choices = styles.map(style => ({
        value: style.scss_class_name,
        label: style.name,
        selected: style.default
      }))

      // Find the default style to apply to banner
      const defaultStyle = styles.find(s => s.default)

      // Add placeholder if no default
      if (!choices.some(c => c.selected)) {
        choices.unshift({ value: "", label: "Select style", placeholder: true })
      }

      choicesInstance.setChoices(choices, "value", "label", true)

      // If editing, restore selection from data attribute
      const selectedValue = selectTarget.dataset.selectedValue
      if (selectedValue && bannerTarget) {
        choicesInstance.setChoiceByValue(selectedValue)
        this.updateBanner(bannerTarget, null, selectedValue)
      } else if (defaultStyle && bannerTarget) {
        // Apply default style to banner
        this.updateBanner(bannerTarget, null, defaultStyle.scss_class_name)
      }
    } catch (error) {
      console.error("Failed to load styles:", error)
    }
  }
}
