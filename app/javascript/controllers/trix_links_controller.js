import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.element.addEventListener("submit", this.normalizeLinks.bind(this))
  }

  normalizeLinks() {
    const editor = this.element.querySelector("trix-editor")
    if (!editor) return

    const origin = window.location.origin
    editor.querySelectorAll("a").forEach(link => {
      if (link.href.startsWith(origin)) {
        const relativePath = link.href.slice(origin.length)
        link.setAttribute("href", relativePath)
      }
    })
  }
}
