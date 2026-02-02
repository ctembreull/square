# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "bootstrap", to: "https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.esm.min.js"
pin "@popperjs/core", to: "https://cdn.jsdelivr.net/npm/@popperjs/core@2.11.8/dist/esm/index.js"

# Falcon theme JavaScript
pin "falcon/config", to: "falcon/config.js"
pin "falcon/utils", to: "falcon/utils.js"
pin "falcon/node", to: "falcon/node.js"
pin "falcon/tooltip", to: "falcon/tooltip.js"
pin "falcon/popover", to: "falcon/popover.js"
pin "falcon/theme-control", to: "falcon/theme-control.js"
pin "falcon/navbar-vertical", to: "falcon/navbar-vertical.js"
pin "falcon/theme", to: "falcon/theme.js"

# FontAwesome
pin "fontawesome", to: "vendors/fontawesome.min.js"

# List.js library and Falcon integration
pin "list.js", to: "vendors/list.min.js"
pin "falcon/list", to: "falcon/list.js"

# Note: Choices.js is loaded via script tag in application.html.erb (not ES module compatible)
pin "trix"
pin "@rails/actiontext", to: "actiontext.esm.js"

# Tippy.js for tooltips (replaces Bootstrap tooltips)
pin "tippy.js", to: "https://cdn.jsdelivr.net/npm/tippy.js@6/dist/tippy.esm.js"
