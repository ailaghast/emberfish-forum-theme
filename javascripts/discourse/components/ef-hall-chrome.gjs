import Component from "@glimmer/component";
import { service } from "@ember/service";
import { trustHTML } from "@ember/template";
import getURL from "discourse/lib/get-url";
import Category from "discourse/models/category";
import dConcatClass from "discourse/ui-kit/helpers/d-concat-class";
import { findTopLevel, hallFor, halls, isWithin } from "../lib/ef-config";

function cssUrl(url) {
  return `url("${String(url).replace(/["\\\n]/g, encodeURIComponent)}")`;
}

// Under the site header on every page: the halls bar (Lobby, one tab per
// game hall the visitor can see, Support), then the current hall's banner:
// full size on the hall page, slim inside its forums and topics.
export default class EfHallChrome extends Component {
  @service router;
  @service discovery;

  get hidden() {
    const name = this.router.currentRouteName || "";
    return name.startsWith("admin") || name.startsWith("wizard");
  }

  get currentCategory() {
    if (this.discovery.category) {
      return this.discovery.category;
    }
    let route = this.router.currentRoute;
    while (route) {
      const categoryId = route.attributes?.category_id;
      if (categoryId) {
        return Category.findById(categoryId);
      }
      route = route.parent;
    }
    return null;
  }

  get hall() {
    return hallFor(this.currentCategory, settings);
  }

  get supportCategory() {
    return findTopLevel(settings.support_category);
  }

  get inSupport() {
    return isWithin(this.currentCategory, settings.support_category);
  }

  get tabs() {
    const current = this.hall;
    return halls(settings).map((h) => ({
      ...h,
      className: dConcatClass(
        "ef-halls__link",
        current?.id === h.id ? "active" : null
      ),
    }));
  }

  // The lobby, and forum-wide lists such as Latest that belong to no hall
  get lobbyActive() {
    return !this.hall && !this.inSupport;
  }

  // The hall's own page (/c/<hall>), as opposed to its forums and topics
  get onHallPage() {
    return (
      this.router.currentRouteName === "discovery.category" &&
      this.currentCategory?.id === this.hall?.id
    );
  }

  get bannerStyle() {
    return trustHTML(`--ef-banner: ${cssUrl(this.hall.banner)}`);
  }

  get homeUrl() {
    return getURL("/");
  }

  <template>
    {{#unless this.hidden}}
      <nav class="ef-halls" aria-label="Halls">
        <div class="ef-halls__inner">
          <span class="ef-halls__label">Halls</span>
          <a
            href={{this.homeUrl}}
            class={{dConcatClass
              "ef-halls__link"
              (if this.lobbyActive "active")
            }}
          ><svg class="fa d-icon svg-icon" aria-hidden="true"><use
                href="#house"
              ></use></svg>Lobby</a>
          {{#each this.tabs as |tab|}}
            <a href={{tab.url}} class={{tab.className}}>
              {{#if tab.icon}}
                <img class="ef-halls__icon" src={{tab.icon}} alt="" />
              {{/if}}
              {{tab.name}}
            </a>
          {{/each}}
          {{#if this.supportCategory}}
            <a
              href={{this.supportCategory.url}}
              class={{dConcatClass
                "ef-halls__link ef-halls__link--support"
                (if this.inSupport "active")
              }}
            ><svg class="fa d-icon svg-icon" aria-hidden="true"><use
                  href="#circle-question"
                ></use></svg>{{this.supportCategory.name}}</a>
          {{/if}}
        </div>
      </nav>

      {{#if this.hall}}
        <section
          class={{dConcatClass
            "ef-hall-banner"
            (unless this.onHallPage "ef-hall-banner--slim")
          }}
          style={{this.bannerStyle}}
          aria-label={{this.hall.name}}
        >
          <div class="ef-hall-banner__content">
            <a class="ef-hall-banner__home" href={{this.hall.url}}>
              {{#if this.hall.wordmark}}
                <img
                  class="ef-hall-banner__logo"
                  src={{this.hall.wordmark}}
                  alt={{this.hall.name}}
                />
              {{else}}
                <span class="ef-hall-banner__name">{{this.hall.name}}</span>
              {{/if}}
            </a>
            {{#if this.onHallPage}}
              {{#if this.hall.tagline}}
                <span class="ef-tagline"><span
                    class="ef-gem"
                  ></span>{{this.hall.tagline}}</span>
              {{/if}}
              {{#if this.hall.buttons.length}}
                <div class="ef-hall-banner__ctas">
                  {{#each this.hall.buttons as |cta index|}}
                    <a
                      class={{if
                        index
                        "ef-btn ef-btn--line"
                        "ef-btn ef-btn--hot"
                      }}
                      href={{cta.url}}
                      target="_blank"
                      rel="noopener noreferrer"
                    >{{cta.label}}</a>
                  {{/each}}
                </div>
              {{/if}}
            {{/if}}
          </div>
        </section>
      {{/if}}
    {{/unless}}
  </template>
}
