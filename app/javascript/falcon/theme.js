import utils from 'falcon/utils';
import tooltipInit from 'falcon/tooltip';
import popoverInit from 'falcon/popover';
import handleNavbarVerticalCollapsed from 'falcon/navbar-vertical';
import listInit from 'falcon/list';

/* -------------------------------------------------------------------------- */
/*                            Theme Initialization                            */
/* -------------------------------------------------------------------------- */

utils.docReady(() => {
  // Initialize Bootstrap tooltips
  tooltipInit();

  // Initialize Bootstrap popovers
  popoverInit();

  // Initialize navbar vertical collapse functionality
  handleNavbarVerticalCollapsed();

  // Initialize List.js tables
  listInit();
});
