import { apiInitializer } from "discourse/lib/api";
import getURL from "discourse/lib/get-url";
import { categoryBadgeHTML } from "discourse/ui-kit/helpers/d-category-link";
import EfBrand from "../components/ef-brand";
import EfHallChrome from "../components/ef-hall-chrome";
import EfHallHome from "../components/ef-hall-home";
import EfHeaderNav from "../components/ef-header-nav";
import EfLobby from "../components/ef-lobby";
import EfPostDate from "../components/ef-post-date";
import EfPoweredBy from "../components/ef-powered-by";
import { hallFor, halls } from "../lib/ef-config";

// Width of the timeline column next to the posts (see "Topic page" in
// common.scss)
const TIMELINE_WIDTH = 140;

function cssUrl(url) {
  return `url("${String(url).replace(/["\\\n]/g, encodeURIComponent)}")`;
}

export default apiInitializer((api) => {
  // Header: the Emberfish logo in place of the site logo, then the top links
  api.renderInOutlet("home-logo-contents", EfBrand);
  api.renderAfterWrapperOutlet("home-logo-wrapper", EfHeaderNav);

  // Halls bar and the current hall's banner, under the header on every page
  api.renderInOutlet("below-site-header", EfHallChrome);

  // The lobby (about.json turns on the custom homepage)
  api.renderInOutlet("custom-homepage", EfLobby);

  // A hall's own page lists its forums instead of core's topic list
  api.renderInOutlet("discovery-list-area", EfHallHome);

  // "Powered by Discourse" as the last line of the footer
  api.renderInOutlet("below-footer", EfPoweredBy);

  const router = api.container.lookup("service:router");
  const currentUser = api.getCurrentUser();
  const site = api.container.lookup("service:site");

  // Topic lists get a "Forums" tab first, so the row reads Forums · Latest ·
  // New · Top everywhere. Inside a game it leads to the hall's page (and is
  // the active tab there); elsewhere to the lobby.
  api.addNavigationBarItem({
    name: "ef-forums",
    displayName: "Forums",
    title: "All forums",
    href: "/",
    before: "latest",
    customHref: (category) => hallFor(category, settings)?.url || "/",
    forceActive: (category, args, r) => {
      const hall = hallFor(category, settings);
      return (
        !!hall &&
        hall.id === category?.id &&
        r.currentRouteName === "discovery.category"
      );
    },
  });

  // The stock Categories page repeats the lobby and the hall pages, so
  // players are sent to the lobby. Staff can still open /categories (it has
  // the New Category button). The path check stops a loop if "/" ever
  // renders it.
  router.on("routeDidChange", (transition) => {
    if (
      transition?.to?.name === "discovery.categories" &&
      !currentUser?.staff &&
      window.location.pathname !== getURL("/")
    ) {
      router.replaceWith("/");
    }
  });

  // Profile fields switched off in the theme settings are hidden by CSS
  // keyed on these body classes (see "Profile fields" in common.scss)
  document.body.classList.toggle(
    "ef-hide-location",
    settings.hide_profile_location
  );
  document.body.classList.toggle("ef-hide-bio", settings.hide_profile_bio);

  // Each hall's color, and its icon in place of the colored square wherever
  // the hall's category is named (breadcrumbs, topic lists, the composer's
  // category picker...). Its subcategories drop the half-and-half parent
  // square and show only their own color. Built from the categories this
  // visitor can see, so a hidden game adds nothing to the page.
  const rules = halls(settings).map((hall) => {
    const icon = hall.icon
      ? `
      .badge-category[data-category-id="${hall.id}"]::before {
        content: "" !important;
        width: 1.15em !important;
        height: 1.15em !important;
        border-radius: 2px !important;
        background: ${cssUrl(hall.icon)} center / contain no-repeat !important;
      }`
      : "";
    return `
      ${icon}
      .badge-category[data-parent-category-id="${hall.id}"]::before {
        background: var(--category-badge-color) !important;
      }`;
  });
  if (rules.length) {
    const style = document.createElement("style");
    style.id = "ef-hall-badges";
    style.textContent = rules.join("\n");
    document.head.appendChild(style);
  }

  // Posts on desktop show a big avatar in the author panel, so ask for the
  // 144px image instead of the 48px one (it would look blurry scaled up)
  api.registerValueTransformer("post-avatar-size", ({ value }) =>
    site.mobileView ? value : "huge"
  );

  // The post's top bar shows the full date and time instead of "2h"
  api.registerValueTransformer(
    "post-meta-data-infos",
    ({ value: infos, context: { metaDataInfoKeys } }) => {
      if (!site.mobileView) {
        infos.replace(metaDataInfoKeys.DATE, EfPostDate);
      }
    }
  );

  // The composer lines up with the posts column: same left edge and width
  // on a topic, and the same size (content minus the timeline) on other
  // pages. common.scss reads these two variables on desktop.
  const alignComposer = () => {
    if (site.mobileView) {
      return;
    }
    let left;
    let width;
    const posts = document.querySelector(".container.posts > .row");
    if (posts) {
      const box = posts.getBoundingClientRect();
      left = box.left;
      width = box.width;
    } else {
      const outlet = document.getElementById("main-outlet");
      if (!outlet) {
        return;
      }
      const box = outlet.getBoundingClientRect();
      const style = window.getComputedStyle(outlet);
      const padLeft = parseFloat(style.paddingLeft) || 0;
      const padRight = parseFloat(style.paddingRight) || 0;
      left = box.left + padLeft;
      width = box.width - padLeft - padRight - TIMELINE_WIDTH;
    }
    const root = document.documentElement.style;
    root.setProperty("--ef-composer-left", `${Math.round(left)}px`);
    root.setProperty("--ef-composer-width", `${Math.round(width)}px`);
  };
  api.onAppEvent("composer:open", alignComposer);
  api.onAppEvent("composer:opened", alignComposer);
  window.addEventListener("resize", alignComposer);
  router.on("routeDidChange", () => requestAnimationFrame(alignComposer));

  // Pin and banner notes ("@name pinned this 2h ago") are left out of
  // the topic; the pin icon on the title and in the lists says enough
  api.registerValueTransformer(
    "post-small-action-class",
    ({ value, context: { post } }) =>
      /^(pinned|pinned_globally|banner)\./.test(post?.action_code || "")
        ? [...value, "ef-quiet-action"]
        : value
  );

  // End of a topic: just "Browse other topics in <forum>", without the
  // "There are 7 new topics remaining" count or the Latest link
  api.modifyClass(
    "component:more-topics/browse-more",
    (Superclass) =>
      class extends Superclass {
        get topicBrowseMoreMessage() {
          const category = this.args.topic.get("category");
          if (
            !category ||
            category.id === this.site.uncategorized_category_id
          ) {
            return super.topicBrowseMoreMessage;
          }
          return `Browse other topics in ${categoryBadgeHTML(category)}`;
        }
      }
  );
});
