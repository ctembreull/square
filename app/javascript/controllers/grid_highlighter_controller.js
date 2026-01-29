import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="grid-highlighter"
// Highlights grid rows and columns when hovering over:
// - Grid cells (extracts digits from ID like "a3h7")
// - Winners table rows (uses data-away-digit and data-home-digit attributes)
//
// Uses Stimulus actions for winners rows (survives Turbo replacement)
// and manual listeners for grid cells (static, never replaced)
export default class extends Controller {
  static targets = ["grid", "scores", "winners"]

  connect() {
    this.setupGridListeners()
  }

  disconnect() {
    this.clearHighlights()
  }

  setupGridListeners() {
    if (!this.hasGridTarget) return

    const cells = this.gridTarget.querySelectorAll("td.game-cell")
    cells.forEach(cell => {
      cell.addEventListener("mouseenter", this.handleGridCellEnter.bind(this))
      cell.addEventListener("mouseleave", this.handleMouseLeave.bind(this))
    })
  }

  // Called via data-action on grid cells
  gridCellEnter(event) {
    this.handleGridCellEnter(event)
  }

  // Called via data-action on winners rows
  winnersRowEnter(event) {
    const row = event.currentTarget
    const awayDigit = parseInt(row.dataset.awayDigit, 10)
    const homeDigit = parseInt(row.dataset.homeDigit, 10)

    if (isNaN(awayDigit) || isNaN(homeDigit)) return
    this.highlightRowAndColumn(awayDigit, homeDigit)
  }

  // Called via data-action on both grid cells and winners rows
  rowLeave() {
    this.clearHighlights()
  }

  handleGridCellEnter(event) {
    const cell = event.currentTarget
    const id = cell.id // e.g., "a3h7"
    const match = id.match(/^a(\d)h(\d)$/)
    if (!match) return

    const awayDigit = parseInt(match[1], 10)
    const homeDigit = parseInt(match[2], 10)
    this.highlightRowAndColumn(awayDigit, homeDigit)
  }

  handleMouseLeave() {
    this.clearHighlights()
  }

  highlightRowAndColumn(awayDigit, homeDigit) {
    this.clearHighlights()

    if (!this.hasGridTarget) return

    // Highlight the away digit header (row header)
    const awayHeader = this.gridTarget.querySelector(`#a${awayDigit}`)
    if (awayHeader) awayHeader.classList.add("grid-highlight")

    // Highlight the home digit header (column header)
    const homeHeader = this.gridTarget.querySelector(`#h${homeDigit}`)
    if (homeHeader) homeHeader.classList.add("grid-highlight")

    // Highlight all cells in the away row (same away digit, all home digits)
    for (let h = 0; h <= 9; h++) {
      const cell = this.gridTarget.querySelector(`#a${awayDigit}h${h}`)
      if (cell) cell.classList.add("grid-highlight-row")
    }

    // Highlight all cells in the home column (all away digits, same home digit)
    for (let a = 0; a <= 9; a++) {
      const cell = this.gridTarget.querySelector(`#a${a}h${homeDigit}`)
      if (cell) cell.classList.add("grid-highlight-col")
    }

    // The intersecting cell gets special treatment (both row and col)
    const winningCell = this.gridTarget.querySelector(`#a${awayDigit}h${homeDigit}`)
    if (winningCell) {
      winningCell.classList.remove("grid-highlight-row", "grid-highlight-col")
      winningCell.classList.add("grid-highlight-cell")
    }

    // If hovering from winners table, also highlight the corresponding winners row
    if (this.hasWinnersTarget) {
      const winnersRows = this.winnersTarget.querySelectorAll(
        `tbody tr[data-away-digit="${awayDigit}"][data-home-digit="${homeDigit}"]`
      )
      winnersRows.forEach(row => row.classList.add("grid-highlight-winner"))
    }
  }

  clearHighlights() {
    // Clear all highlight classes from the document
    const highlightClasses = [
      "grid-highlight",
      "grid-highlight-row",
      "grid-highlight-col",
      "grid-highlight-cell",
      "grid-highlight-winner"
    ]

    highlightClasses.forEach(cls => {
      document.querySelectorAll(`.${cls}`).forEach(el => el.classList.remove(cls))
    })
  }
}
