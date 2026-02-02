import { Controller } from "@hotwired/stimulus"
import tippy from "tippy.js"

// Initializes Tippy.js tooltips for elements with data-tippy-content attribute
// Place data-controller="tippy" on a parent element (e.g., body or main container)
// Child elements with data-tippy-content will get tooltips automatically
//
// Usage:
//   <div data-controller="tippy">
//     <span data-tippy-content="Tooltip text">Hover me</span>
//     <span data-tippy-content="Bottom tip" data-tippy-placement="bottom">Below</span>
//   </div>
//
// Supports Tippy data attributes: data-tippy-placement, data-tippy-animation, etc.
export default class extends Controller {
  connect() {
    this.initTooltips()

    // Re-initialize when Turbo updates the page
    this.observer = new MutationObserver(() => this.initTooltips())
    this.observer.observe(this.element, { childList: true, subtree: true })
  }

  disconnect() {
    this.observer?.disconnect()
    this.destroyTooltips()
  }

  initTooltips() {
    // Find elements that don't already have tippy initialized
    const targets = this.element.querySelectorAll('[data-tippy-content]:not([data-tippy-initialized])')

    targets.forEach(target => {
      tippy(target, {
        content: target.dataset.tippyContent,
        placement: target.dataset.tippyPlacement || 'top',
        animation: 'fade',
        duration: [200, 150]
      })
      target.setAttribute('data-tippy-initialized', 'true')
    })
  }

  destroyTooltips() {
    const targets = this.element.querySelectorAll('[data-tippy-initialized]')
    targets.forEach(target => {
      target._tippy?.destroy()
      target.removeAttribute('data-tippy-initialized')
    })
  }
}
