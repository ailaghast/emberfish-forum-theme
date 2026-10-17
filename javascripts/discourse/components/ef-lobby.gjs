import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { trustHTML } from "@ember/template";
import getURL from "discourse/lib/get-url";
import { fetchTopics, noteStart, topicRows } from "../lib/ef-activity";
import {
  childrenOf,
  findTopLevel,
  fmtNumber,
  hallFor,
  halls,
  splitList,
} from "../lib/ef-config";
import EfAnnouncement from "./ef-announcement";
import EfForumStats from "./ef-forum-stats";
import EfMedal from "./ef-medal";

const SHARE = {
  x: {
    label: "X",
    url: (u, t) => `https://x.com/intent/post?text=${t}&url=${u}`,
  },
  reddit: {
    label: "Reddit",
    url: (u, t) => `https://www.reddit.com/submit?url=${u}&title=${t}`,
  },
  facebook: {
    label: "Facebook",
    url: (u) => `https://www.facebook.com/sharer/sharer.php?u=${u}`,
  },
  whatsapp: {
    label: "WhatsApp",
    url: (u, t) => `https://wa.me/?text=${t}%20${u}`,
  },
  weibo: {
    label: "Weibo",
    url: (u, t) =>
      `https://service.weibo.com/share/share.php?url=${u}&title=${t}`,
  },
  email: { label: "Email", url: (u, t) => `mailto:?subject=${t}&body=${u}` },
};

function cssUrl(url) {
  return `url("${String(url).replace(/["\\\n]/g, encodeURIComponent)}")`;
}

// The homepage: one "door" per game hall the visitor can see, the
// announcement bar, the latest discussions from every game, and Support,
// Forum stats and Share on the right. It doesn't list every forum of every
// game; each hall's page does that.
export default class EfLobby extends Component {
  @service currentUser;

  @tracked topics = [];
  @tracked loadError = null;
  @tracked copied = false;

  looping = noteStart();

  constructor() {
    super(...arguments);
    if (!this.looping) {
      this.load();
    }
    document.body.classList.add("ef-lobby-page");
  }

  willDestroy() {
    super.willDestroy(...arguments);
    document.body.classList.remove("ef-lobby-page");
  }

  async load() {
    try {
      const list = await fetchTopics(
        "/latest.json",
        this.currentUser?.id ?? "anon"
      );
      this.topics = topicRows(list);
    } catch (e) {
      // The lobby still renders its doors without activity data
      // eslint-disable-next-line no-console
      console.error("[Emberfish theme] loading activity failed", e);
      this.loadError = `Loading activity failed: ${e?.message || e}`;
    }
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

  get latest() {
    return this.topics
      .filter((t) => t.isPublic)
      .slice(0, settings.lobby_latest_count)
      .map((t) => {
        const hall = hallFor(t.category, settings);
        return {
          ...t,
          hallName: hall?.name,
          hallIcon: hall?.icon,
          chipStyle: hall ? trustHTML(`--ef-chip: ${hall.color}`) : null,
        };
      });
  }

  get support() {
    const parent = findTopLevel(settings.support_category);
    return parent ? childrenOf(parent) : [];
  }

  get errorText() {
    return this.currentUser?.staff ? this.loadError : null;
  }

  get noHalls() {
    return this.currentUser?.staff && !this.doors.length;
  }

  get shareUrl() {
    return window.location.origin + getURL("/");
  }

  get shareLinks() {
    const u = encodeURIComponent(this.shareUrl);
    const t = encodeURIComponent(settings.share_text || document.title);
    return splitList(settings.share_networks)
      .filter((key) => SHARE[key])
      .map((key) => ({ label: SHARE[key].label, href: SHARE[key].url(u, t) }));
  }

  get latestUrl() {
    return getURL("/latest");
  }

  @action
  async copyLink() {
    try {
      await navigator.clipboard.writeText(this.shareUrl);
      this.copied = true;
      setTimeout(() => (this.copied = false), 2000);
    } catch {
      // Clipboard blocked: the link stays selectable in the field
    }
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
    {{#if this.errorText}}
      <p class="ef-home-error">Emberfish theme (only staff see this):
        {{this.errorText}}</p>
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
              {{#each door.buttons as |button|}}
                <a
                  class="ef-btn ef-btn--line"
                  href={{button.url}}
                  target="_blank"
                  rel="noopener noreferrer"
                >{{button.label}}</a>
              {{/each}}
            </div>
            <span class="ef-door__meta">{{door.metaText}}</span>
          </div>
        </article>
      {{/each}}
    </div>

    <EfAnnouncement />

    <div class="ef-home__grid">
      <div class="ef-home__main">
        <section class="ef-section ef-frame">
          <div class="ef-bar">
            <h2 class="ef-bar__title">Latest discussions</h2>
            <span class="ef-bar__col">Replies</span>
          </div>
          <div class="ef-inner">
            {{#each this.latest as |topic|}}
              <div class="ef-topic">
                {{#if topic.avatar}}
                  <img
                    class="ef-avatar"
                    src={{topic.avatar}}
                    alt=""
                    loading="lazy"
                  />
                {{else}}
                  <span
                    class="ef-avatar ef-avatar--initial"
                    aria-hidden="true"
                  >{{topic.initial}}</span>
                {{/if}}
                <span class="ef-topic__text">
                  <a
                    class="ef-topic__title"
                    href={{topic.url}}
                  >{{topic.title}}</a>
                  <span class="ef-topic__meta">{{topic.user}}
                    ·
                    {{topic.when}}
                    {{#if topic.categoryName}}
                      ·
                      {{topic.categoryName}}
                    {{/if}}</span>
                </span>
                {{#if topic.hallName}}
                  <span class="ef-chip" style={{topic.chipStyle}}>
                    {{#if topic.hallIcon}}
                      <img src={{topic.hallIcon}} alt="" />
                    {{/if}}
                    {{topic.hallName}}
                  </span>
                {{else}}
                  <span></span>
                {{/if}}
                <span class="ef-topic__replies" title="Replies"><svg
                    class="fa d-icon svg-icon"
                    aria-hidden="true"
                  ><use href="#reply"></use></svg>{{topic.replies}}</span>
              </div>
            {{else}}
              <div class="ef-empty">No discussions yet.</div>
            {{/each}}
            <a class="ef-more" href={{this.latestUrl}}>All recent topics<svg
                class="fa d-icon svg-icon"
                aria-hidden="true"
              ><use href="#chevron-right"></use></svg></a>
          </div>
        </section>
      </div>

      <aside class="ef-home__aside">
        {{#if this.support.length}}
          <section class="ef-side ef-frame">
            <h2 class="ef-bar"><span class="ef-bar__title">Support</span></h2>
            <div class="ef-inner">
              {{#each this.support as |category|}}
                <a class="ef-support" href={{category.url}}>
                  <EfMedal @category={{category}} />
                  <span class="ef-support__text">
                    <b>{{category.name}}</b>
                    {{#if category.description_text}}
                      <span>{{category.description_text}}</span>
                    {{/if}}
                  </span>
                </a>
              {{/each}}
            </div>
          </section>
        {{/if}}

        {{#if settings.show_stats}}
          <EfForumStats />
        {{/if}}

        {{#if this.shareLinks.length}}
          <section class="ef-side ef-frame">
            <h2 class="ef-bar"><span class="ef-bar__title">Share</span></h2>
            <div class="ef-inner ef-share">
              <span class="ef-share__intro">Know someone who’d like our games?
                Bring them along.</span>
              <div class="ef-share__grid">
                {{#each this.shareLinks as |link|}}
                  <a
                    class="ef-share__net"
                    href={{link.href}}
                    target="_blank"
                    rel="noopener noreferrer"
                  >{{link.label}}</a>
                {{/each}}
              </div>
              <div class="ef-share__copy">
                <input
                  type="text"
                  readonly
                  value={{this.shareUrl}}
                  aria-label="Forum link"
                />
                <button
                  type="button"
                  class="ef-btn ef-btn--hot"
                  {{on "click" this.copyLink}}
                >{{if this.copied "Copied" "Copy"}}</button>
              </div>
            </div>
          </section>
        {{/if}}
      </aside>
    </div>
  </template>
}
