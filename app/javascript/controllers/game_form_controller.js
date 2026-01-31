import { Controller } from "@hotwired/stimulus"

// Choices.js is loaded via CDN and attaches to window
// We'll access it dynamically since the CDN version isn't an ES module
export default class extends Controller {
  static targets = ["league", "awayTeam", "awayStyle", "homeTeam", "homeStyle", "periodPrize", "finalPrize", "awayBanner", "homeBanner", "awayLastUsed", "homeLastUsed", "eventId", "scoreUrl", "scoreUrlLabel", "espnApiUrl", "fetchButton", "localDate", "localTime", "localTimezone", "broadcastNetwork", "title"]

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

    // Update score URL label if pre-filled (edit form)
    if (this.hasScoreUrlTarget && this.scoreUrlTarget.value) {
      this.updateScoreUrlLabel(this.scoreUrlTarget.value)
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

  // Called when score URL changes - update label to link to ESPN API
  scoreUrlChanged(event) {
    this.updateScoreUrlLabel(event.target.value)
  }

  // Update the score URL label to show API link or plain text, and populate hidden field
  updateScoreUrlLabel(url) {
    const apiUrl = this.buildEspnApiUrl(url)

    // Update label with link if valid ESPN URL
    if (this.hasScoreUrlLabelTarget) {
      if (apiUrl) {
        this.scoreUrlLabelTarget.innerHTML = `<a href="${apiUrl}" target="_blank">Score URL <i class="fas fa-external-link-alt fs-10"></i></a>`
      } else {
        this.scoreUrlLabelTarget.textContent = "Score URL"
      }
    }

    // Update hidden field
    if (this.hasEspnApiUrlTarget) {
      this.espnApiUrlTarget.value = apiUrl || ""
    }

    // Enable/disable fetch button
    if (this.hasFetchButtonTarget) {
      this.fetchButtonTarget.disabled = !apiUrl
    }
  }

  // Parse ESPN URL and build corresponding API URL
  buildEspnApiUrl(url) {
    if (!url) return null

    // Extract gameId from ESPN URL patterns:
    // https://www.espn.com/mens-college-basketball/game/_/gameId/401825479
    // https://www.espn.com/mens-college-basketball/boxscore/_/gameId/401825479
    // https://www.espn.com/nfl/game/_/gameId/401547417
    const gameIdMatch = url.match(/gameId\/(\d+)/)
    if (!gameIdMatch) return null

    const gameId = gameIdMatch[1]

    // Extract sport/league from URL path
    // Map ESPN URL paths to API paths
    const sportMappings = {
      "mens-college-basketball": "basketball/mens-college-basketball",
      "womens-college-basketball": "basketball/womens-college-basketball",
      "nfl": "football/nfl",
      "college-football": "football/college-football"
    }

    for (const [urlPath, apiPath] of Object.entries(sportMappings)) {
      if (url.includes(`espn.com/${urlPath}/`)) {
        return `https://site.api.espn.com/apis/site/v2/sports/${apiPath}/summary?event=${gameId}`
      }
    }

    return null
  }

  // Fetch game data from ESPN API and populate form fields
  async fetchEspnData() {
    const apiUrl = this.hasEspnApiUrlTarget ? this.espnApiUrlTarget.value : null
    if (!apiUrl) return

    // Show loading state
    if (this.hasFetchButtonTarget) {
      this.fetchButtonTarget.disabled = true
      this.fetchButtonTarget.innerHTML = '<i class="fas fa-spinner fa-spin"></i>'
    }

    try {
      const response = await fetch(`/games/fetch_espn_data?espn_api_url=${encodeURIComponent(apiUrl)}`)
      const data = await response.json()

      if (!response.ok) {
        throw new Error(data.error || "Failed to fetch ESPN data")
      }

      // Populate date/time/timezone if available (already converted to local timezone by server)
      if (data.local_date && this.hasLocalDateTarget) {
        this.localDateTarget.value = data.local_date
      }
      if (data.local_time && this.hasLocalTimeTarget) {
        this.localTimeTarget.value = data.local_time
      }
      if (data.local_timezone && this.hasLocalTimezoneTarget) {
        this.localTimezoneTarget.value = data.local_timezone
      }
      if (data.broadcast_network && this.hasBroadcastNetworkTarget) {
        this.broadcastNetworkTarget.value = data.broadcast_network
      }

      // Build messages for any teams not found
      const messages = []
      if (!data.home_team_id && data.home_espn_id) {
        messages.push(`Home team not found (ESPN ID: ${data.home_espn_id}, ${data.home_team_name})`)
      }
      if (!data.away_team_id && data.away_espn_id) {
        messages.push(`Away team not found (ESPN ID: ${data.away_espn_id}, ${data.away_team_name})`)
      }

      // Set team IDs in dataset before loading teams - loadTeamsForLeague will use these
      if (data.home_team_id) {
        this.homeTeamTarget.dataset.selectedValue = data.home_team_id.toString()
      }
      if (data.away_team_id) {
        this.awayTeamTarget.dataset.selectedValue = data.away_team_id.toString()
      }

      // Set league and load teams (which will auto-select teams from dataset.selectedValue)
      if (data.league_id) {
        this.leagueTarget.value = data.league_id.toString()
        await this.loadTeamsForLeague(data.league_id)
      }

      if (messages.length > 0) {
        alert(messages.join("\n"))
      }

      // Focus title field for user to complete
      if (this.hasTitleTarget) {
        this.titleTarget.focus()
      }
    } catch (error) {
      console.error("Failed to fetch ESPN data:", error)
      alert(`Failed to fetch ESPN data: ${error.message}`)
    } finally {
      // Restore button state
      if (this.hasFetchButtonTarget) {
        this.fetchButtonTarget.disabled = false
        this.fetchButtonTarget.innerHTML = '<i class="fas fa-download"></i>'
      }
    }
  }

  async loadTeamsForLeague(leagueId) {
    try {
      const eventId = this.hasEventIdTarget ? this.eventIdTarget.value : ""
      const url = eventId
        ? `/leagues/${leagueId}/teams.json?event_id=${eventId}`
        : `/leagues/${leagueId}/teams.json`
      const response = await fetch(url)
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
        const awayOption = this.awayTeamChoices.getValue()
        this.updateBanner(this.awayBannerTarget, awayOption?.label || "Away Team", "")
        this.loadStylesForTeam(awayTeamId, this.awayStyleChoices, this.awayStyleTarget, this.awayBannerTarget)
        if (this.hasAwayLastUsedTarget) this.updateLastUsed(awayTeamId, this.awayLastUsedTarget)
      }
      if (homeTeamId) {
        this.homeTeamChoices.setChoiceByValue(homeTeamId)
        const homeOption = this.homeTeamChoices.getValue()
        this.updateBanner(this.homeBannerTarget, homeOption?.label || "Home Team", "")
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
