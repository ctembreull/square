import utils from 'falcon/utils';
import tooltipInit from 'falcon/tooltip';
import popoverInit from 'falcon/popover';
import handleNavbarVerticalCollapsed from 'falcon/navbar-vertical';

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
});
