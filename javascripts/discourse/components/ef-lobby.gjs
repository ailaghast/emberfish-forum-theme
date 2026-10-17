import Component from "@glimmer/component";
import { service } from "@ember/service";
import { trustHTML } from "@ember/template";
import { fmtNumber, halls } from "../lib/ef-config";
import EfAnnouncement from "./ef-announcement";

function cssUrl(url) {
  return `url("${String(url).replace(/["\\\n]/g, encodeURIComponent)}")`;
}

// The homepage: a small Emberfish crest, one "door" per game hall the
// visitor can see, then the announcement bar. Latest posts, Support, Forum
// stats and Share live on each hall's page, next to its forums.
export default class EfLobby extends Component {
  @service currentUser;
  @service siteSettings;

  constructor() {
    super(...arguments);
    document.body.classList.add("ef-lobby-page");
  }

  willDestroy() {
    super.willDestroy(...arguments);
    document.body.classList.remove("ef-lobby-page");
  }

  get doors() {
    return halls(settings).map((h) => ({
      ...h,
      artStyle: trustHTML(`background-image: ${cssUrl(h.banner)}`),
      metaText: `${fmtNumber(h.topicCount)} topics · ${fmtNumber(
        h.postCount
      )} posts`,
    }));
  }

  get doorsClass() {
    return `ef-doors ef-doors--${Math.min(this.doors.length, 3)}`;
  }

  get noHalls() {
    return this.currentUser?.staff && !this.doors.length;
  }

  <template>
    {{! The page's heading is for screen readers; the crest says it visually }}
    <h1 class="sr-only">{{this.siteSettings.title}}</h1>
    <div class="ef-crest" aria-hidden="true">
      <span class="ef-crest__line"></span>
      <span class="ef-gem"></span>
      <img
        class="ef-crest__mark"
        src={{settings.theme_uploads.ef_mark}}
        alt=""
      />
      <span class="ef-gem"></span>
      <span class="ef-crest__line ef-crest__line--right"></span>
    </div>

    {{#if this.noHalls}}
      <p class="ef-home-error">Emberfish theme (only staff see this): no game
        halls yet. A hall is a top-level category with a Background image; see
        the theme's INSTALL.md.</p>
    {{/if}}

    <div class={{this.doorsClass}}>
      {{#each this.doors as |door|}}
        <article class="ef-door ef-frame">
          <a class="ef-door__art" href={{door.url}} style={{door.artStyle}}>
            {{#if door.wordmark}}
              <img
                class="ef-door__logo"
                src={{door.wordmark}}
                alt={{door.name}}
              />
            {{else}}
              <span class="ef-door__name">{{door.name}}</span>
            {{/if}}
          </a>
          <div class="ef-door__body">
            {{#if door.tagline}}
              <span class="ef-tagline"><span
                  class="ef-gem"
                ></span>{{door.tagline}}<span class="ef-gem"></span></span>
            {{/if}}
            {{#if door.pitch}}
              <p class="ef-door__pitch">{{door.pitch}}</p>
            {{/if}}
            <div class="ef-door__ctas">
              <a class="ef-btn ef-btn--hot" href={{door.url}}>Enter the hall</a>
              {{#each door.buttons as |cta|}}
                <a
                  class="ef-btn ef-btn--line"
                  href={{cta.url}}
                  target="_blank"
                  rel="noopener noreferrer"
                >{{cta.label}}</a>
              {{/each}}
            </div>
            <span class="ef-door__meta">{{door.metaText}}</span>
          </div>
        </article>
      {{/each}}
    </div>

    <EfAnnouncement />
  </template>
}
