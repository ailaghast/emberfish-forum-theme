import { schedule } from "@ember/runloop";

// Core's preference pages (Account, Profile, Emails...) only keep a change
// when Save Changes is pressed, and say nothing if the player leaves first.
// The change also stays in the page's copy of the user until the profile is
// loaded again, so a page opened later can show it as if it had been saved.
// This asks before leaving a page with unsaved changes, as core's newer forms
// do, and puts the old values back if the player leaves anyway.

const MESSAGE = "You haven't saved your changes on this page.";

// Values a few pages hold on the page itself until Save Changes copies them
// into the user. Everything else a page saves (its saveAttrNames) is edited
// on the user directly.
const STAGED = {
  "preferences.account": (controller) => [
    controller.newNameInput,
    controller.newTitleInput,
    controller.newPrimaryGroupInput,
    controller.newFlairGroupId,
    controller.newStatus,
  ],
  "preferences.profile": (controller) =>
    controller.userFields?.map((field) => field.value),
  "preferences.interface": (controller) => [
    controller.themeId,
    controller.makeThemeDefault,
    controller.textSize,
    controller.makeTextSizeDefault,
    controller.selectedColorSchemeId,
    controller.selectedDarkColorSchemeId,
    controller.selectedInterfaceColorModeId,
    controller.makeColorSchemeDefault,
  ],
};

// Changed by the forum itself (user tips), not by the form
const IGNORED = new Set(["seen_popups"]);

// A value that can't be written out never counts as a change
function serialize(value) {
  try {
    return JSON.stringify(value ?? null);
  } catch {
    return null;
  }
}

// Core's User#save reads each field from the user's options if it is one,
// otherwise from the user
function isOption(user, attr) {
  return !!user.user_option && attr in user.user_option;
}

function read(user, attr) {
  return isOption(user, attr) ? user.user_option[attr] : user.get(attr);
}

// The page's values as they are now
function values(page) {
  const fields = new Map();
  page.attrs.forEach((attr) =>
    fields.set(attr, serialize(read(page.user, attr)))
  );
  const staged = serialize(STAGED[page.route]?.(page.controller));
  return { fields, staged };
}

function sameValues(a, b) {
  if (a.staged !== b.staged) {
    return false;
  }
  for (const [attr, value] of a.fields) {
    if (b.fields.get(attr) !== value) {
      return false;
    }
  }
  return true;
}

// A save says it went through only by showing "Saved!" (the page's `saved`),
// so the values are noted when Save Changes is pressed and become the
// starting point once the page says Saved
function settle(page) {
  if (page.saving && page.controller.saved === true && !page.user.isSaving) {
    page.start = page.saving;
    page.saving = null;
  }
}

function hasChanges(page) {
  settle(page);
  return !page.user.isSaving && !sameValues(values(page), page.start);
}

// Values held on the page are set again from the user when the page opens,
// so only the user's own fields need putting back
function revert(page) {
  for (const [attr, value] of page.start.fields) {
    if (value !== null && serialize(read(page.user, attr)) !== value) {
      const old = JSON.parse(value);
      if (isOption(page.user, attr)) {
        page.user.set(`user_option.${attr}`, old);
      } else {
        page.user.set(attr, old);
      }
    }
  }
}

export default function guardUnsavedPreferences(api) {
  const router = api.container.lookup("service:router");
  const dialog = api.container.lookup("service:dialog");

  // The open preference page
  let open = null;

  function openPage(route) {
    const controller = api.container.lookup(`controller:${route}`);
    const user = controller?.model;
    let attrs;
    try {
      attrs = controller?.saveAttrNames;
    } catch {
      attrs = null;
    }
    if (!user?.user_option || !Array.isArray(attrs)) {
      return null;
    }

    const page = {
      route,
      controller,
      user,
      attrs: attrs.filter((attr) => !IGNORED.has(attr)),
      saving: null,
    };
    page.start = values(page);
    return page;
  }

  // Taken after the page has drawn, so values its fields fill in on their
  // own aren't mistaken for the player's changes
  router.on("routeDidChange", () => {
    const route = router.currentRouteName;
    if (open?.route === route && open.controller.model === open.user) {
      return;
    }
    open = null;
    if (route?.startsWith("preferences.")) {
      schedule("afterRender", () => {
        if (router.currentRouteName === route) {
          open = openPage(route);
        }
      });
    }
  });

  // Save Changes: an earlier save that went through is settled first, then
  // the values are noted once the page's save has started (and copied what
  // it holds into the user)
  document.addEventListener(
    "click",
    (event) => {
      const page = open;
      if (!page || !event.target.closest?.(".save-changes")) {
        return;
      }
      settle(page);
      setTimeout(() => {
        if (open === page) {
          page.saving = values(page);
        }
      });
    },
    true
  );

  router.on("routeWillChange", (transition) => {
    const page = open;
    if (
      !page ||
      transition.isAborted ||
      transition.to?.name === page.route ||
      !hasChanges(page)
    ) {
      return;
    }

    transition.abort();
    dialog.dialog({
      type: "confirm",
      message: MESSAGE,
      buttons: [
        {
          label: "Discard changes",
          class: "btn-danger ef-discard-changes",
          action: () => {
            revert(page);
            open = null;
            transition.retry();
          },
        },
        { label: "Keep editing", class: "btn-default ef-keep-editing" },
      ],
    });
  });

  // Closing the tab, reloading, or following a link out of the forum: the
  // browser asks with its own message
  window.addEventListener("beforeunload", (event) => {
    if (open && hasChanges(open)) {
      event.preventDefault();
      event.returnValue = true;
    }
  });
}
