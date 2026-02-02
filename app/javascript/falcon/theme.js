import utils from 'falcon/utils';
// Tooltips now handled by Tippy.js via tippy_controller.js
import popoverInit from 'falcon/popover';
import handleNavbarVerticalCollapsed from 'falcon/navbar-vertical';
import listInit from 'falcon/list';

/* -------------------------------------------------------------------------- */
/*                            Theme Initialization                            */
/* -------------------------------------------------------------------------- */

utils.docReady(() => {
  // Initialize Bootstrap popovers
  popoverInit();

  // Initialize navbar vertical collapse functionality
  handleNavbarVerticalCollapsed();

  // Initialize List.js tables
  listInit();
});
