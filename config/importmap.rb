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
