import utils from 'falcon/utils';
import tooltipInit from 'falcon/tooltip';
import popoverInit from 'falcon/popover';

/* -------------------------------------------------------------------------- */
/*                            Theme Initialization                            */
/* -------------------------------------------------------------------------- */

utils.docReady(() => {
  // Initialize Bootstrap tooltips
  tooltipInit();

  // Initialize Bootstrap popovers
  popoverInit();
});
