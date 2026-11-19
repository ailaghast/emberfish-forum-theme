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

export default function guardUnsavedPreferences(api) {
  const router = api.container.lookup("service:router");
  const dialog = api.container.lookup("service:dialog");

  // The open preference page: its values as last loaded or saved
  let open = null;

  const staged = (state) => serialize(STAGED[state.route]?.(state.controller));

  function snapshot(route) {
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

    const saved = new Map();
    attrs
      .filter((attr) => !IGNORED.has(attr))
      .forEach((attr) => saved.set(attr, serialize(read(user, attr))));

    const state = { route, controller, user, saved };
    state.staged = staged(state);
    return state;
  }

  function hasChanges(state) {
    for (const [attr, value] of state.saved) {
      if (serialize(read(state.user, attr)) !== value) {
        return true;
      }
    }
    return staged(state) !== state.staged;
  }

  // Values held on the page are set again from the user when the page opens,
  // so only the user's own fields need putting back
  function revert(state) {
    for (const [attr, value] of state.saved) {
      if (value !== null && serialize(read(state.user, attr)) !== value) {
        const old = JSON.parse(value);
        if (isOption(state.user, attr)) {
          state.user.set(`user_option.${attr}`, old);
        } else {
          state.user.set(attr, old);
        }
      }
    }
  }

  // After a save, what was saved is the new starting point. Other saves
  // (a user tip being dismissed...) only move the fields they sent.
  function afterSave(user, fields) {
    if (open?.user !== user) {
      return;
    }
    const attrs = [...open.saved.keys()];
    for (const attr of attrs) {
      if (!fields || fields.includes(attr)) {
        open.saved.set(attr, serialize(read(user, attr)));
      }
    }
    if (!fields || attrs.every((attr) => fields.includes(attr))) {
      open.staged = staged(open);
    }
  }

  api.modifyClass(
    "model:user",
    (Superclass) =>
      class extends Superclass {
        save(fields) {
          return super.save(...arguments).then((result) => {
            afterSave(this, fields);
            return result;
          });
        }
      }
  );

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
          open = snapshot(route);
        }
      });
    }
  });

  router.on("routeWillChange", (transition) => {
    const state = open;
    if (
      !state ||
      transition.isAborted ||
      transition.to?.name === state.route ||
      state.user.isSaving ||
      !hasChanges(state)
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
            revert(state);
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
    if (open && !open.user.isSaving && hasChanges(open)) {
      event.preventDefault();
      event.returnValue = true;
    }
  });
}
