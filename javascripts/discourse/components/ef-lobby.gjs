import Component from "@glimmer/component";
import { service } from "@ember/service";
import { trustHTML } from "@ember/template";
import { fmtNumber, halls } from "../lib/ef-config";
import EfAnnouncement from "./ef-announcement";

function cssUrl(url) {
  return `url("${String(url).replace(/["\\\n]/g, encodeURIComponent)}")`;
}

// The homepage: one "door" per game hall the visitor can see, then the
// announcement bar. Latest posts, Support, Forum stats and Share live on
// each hall's page, next to its forums.
export default class EfLobby extends Component {
  @service currentUser;

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
    {{#if settings.lobby_title}}
      <header class="ef-welcome">
        <h1>{{settings.lobby_title}}</h1>
        {{#if settings.lobby_subtitle}}
          <p>{{settings.lobby_subtitle}}</p>
        {{/if}}
      </header>
    {{/if}}

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
