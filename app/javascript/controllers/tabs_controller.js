import { Controller } from "@hotwired/stimulus"

// Handles tab switching with support for complex content (tables, grids)
// Dispatches tab:shown event when panel becomes visible for lazy initialization
export default class extends Controller {
  static targets = ["button", "panel", "action"]
  static values = {
    activeClass: { type: String, default: "active" },
    hiddenClass: { type: String, default: "d-none" },
    defaultTab: { type: String, default: "" }
  }

  connect() {
    // Only initialize if we have targets (avoids race conditions with Turbo cache)
    if (this.hasPanelTarget) {
      // Check URL hash on load, fall back to default or first tab
      const hash = window.location.hash.replace("#", "")
      const initialTab = hash || this.defaultTabValue || this.panelTargets[0]?.id

      if (initialTab) {
        this.showPanel(initialTab)
      }
    }

    // Listen for hash changes (back/forward navigation)
    this.boundHashChange = this.handleHashChange.bind(this)
    window.addEventListener("hashchange", this.boundHashChange)
  }

  disconnect() {
    window.removeEventListener("hashchange", this.boundHashChange)
  }

  handleHashChange() {
    const hash = window.location.hash.replace("#", "")
    if (hash && this.panelTargets.find(p => p.id === hash)) {
      this.showPanel(hash)
    }
  }

  select(event) {
    event.preventDefault()
    const panelId = event.currentTarget.dataset.tabsPanel
    this.showPanel(panelId)

    // Update URL hash without scrolling
    history.pushState(null, null, `#${panelId}`)
  }

  showPanel(panelId) {
    // Hide all panels
    this.panelTargets.forEach(panel => {
      panel.classList.add(this.hiddenClassValue)
    })

    // Deactivate all buttons
    this.buttonTargets.forEach(button => {
      button.classList.remove(this.activeClassValue)
    })

    // Show selected panel
    const panel = this.panelTargets.find(p => p.id === panelId)
    const button = this.buttonTargets.find(b => b.dataset.tabsPanel === panelId)

    if (panel) {
      panel.classList.remove(this.hiddenClassValue)
      panel.dispatchEvent(new CustomEvent("tab:shown", { bubbles: true }))
    }

    if (button) {
      button.classList.add(this.activeClassValue)
    }

    // Update context-aware action buttons
    this.actionTargets.forEach(action => {
      if (action.dataset.tabsPanel === panelId) {
        action.classList.remove(this.hiddenClassValue)
      } else {
        action.classList.add(this.hiddenClassValue)
      }
    })
  }
}
