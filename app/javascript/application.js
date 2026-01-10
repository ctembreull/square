// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import { Tooltip, Popover, Toast, Modal, Collapse, Dropdown } from "bootstrap"

// Make Bootstrap components available globally for Falcon theme
window.bootstrap = {
  Tooltip,
  Popover,
  Toast,
  Modal,
  Collapse,
  Dropdown
}

// Import List.js library (makes window.List available)
import "list.js"

// Import Falcon theme
import "falcon/theme"

// Import FontAwesome
import "fontawesome"
