import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { service } from "@ember/service";
import bodyClass from "discourse/helpers/body-class";
import { fetchTopics, noteStart, topicRows } from "../lib/ef-activity";
import { fmtNumber, hallFor, hallSections } from "../lib/ef-config";
import EfForumStats from "./ef-forum-stats";
import EfMedal from "./ef-medal";

// The hall page itself (see EfHallHome below)
class EfHallForums extends Component {
  @service currentUser;

  @tracked topics = [];
  @tracked loadError = null;

  looping = noteStart();

  constructor() {
    super(...arguments);
    if (!this.looping) {
      this.load();
    }
  }

  async load() {
    const hall = this.args.hall;
    try {
      const list = await fetchTopics(
        `/c/${hall.slug}/${hall.id}/l/latest.json`,
        this.currentUser?.id ?? "anon"
      );
      this.topics = topicRows(list);
    } catch (e) {
      // eslint-disable-next-line no-console
      console.error("[Emberfish theme] loading hall activity failed", e);
      this.loadError = `Loading activity failed: ${e?.message || e}`;
    }
  }

  get latestByCategory() {
    const map = new Map();
    this.topics.forEach((t) => {
      if (!map.has(t.categoryId)) {
        map.set(t.categoryId, t);
      }
    });
    return map;
  }

  get sections() {
    const latest = this.latestByCategory;
    return hallSections(this.args.hall, settings).map((section) => ({
      name: section.name,
      url: section.url,
      rows: section.categories.map((c) => ({
        category: c,
        name: c.name,
        url: c.url,
        description: c.description_text,
        topicsText: fmtNumber(c.topic_count),
        postsText: fmtNumber(c.post_count),
        last: latest.get(c.id),
      })),
    }));
  }

  get latest() {
    return this.topics.filter((t) => t.isPublic).slice(0, 5);
  }

  get errorText() {
    return this.currentUser?.staff ? this.loadError : null;
  }

  <template>
    {{#if this.errorText}}
      <p class="ef-home-error">Emberfish theme (only staff see this):
        {{this.errorText}}</p>
    {{/if}}

    <div class="ef-home__grid">
      <div class="ef-home__main">
        {{#each this.sections as |group|}}
          <section class="ef-section ef-frame">
            <div class="ef-bar ef-bar--forums">
              <h2 class="ef-bar__title">
                {{#if group.url}}
                  <a href={{group.url}}>{{group.name}}</a>
                {{else}}
                  {{group.name}}
                {{/if}}
              </h2>
              <span class="ef-bar__col">Topics</span>
              <span class="ef-bar__col ef-bar__col--posts">Posts</span>
              <span class="ef-bar__col ef-bar__col--latest">Latest</span>
            </div>
            <div class="ef-inner">
              {{#each group.rows as |row|}}
                <div class="ef-forum">
                  <EfMedal @category={{row.category}} />
                  <div class="ef-forum__info">
                    <a class="ef-forum__name" href={{row.url}}>{{row.name}}</a>
                    {{#if row.description}}
                      <span class="ef-forum__desc">{{row.description}}</span>
                    {{/if}}
                  </div>
                  <span class="ef-forum__count">{{row.topicsText}}</span>
                  <span
                    class="ef-forum__count ef-forum__count--posts"
                  >{{row.postsText}}</span>
                  <div class="ef-forum__latest">
                    {{#if row.last}}
                      {{#if row.last.avatar}}
                        <img
                          class="ef-avatar"
                          src={{row.last.avatar}}
                          alt=""
                          loading="lazy"
                        />
                      {{else}}
                        <span
                          class="ef-avatar ef-avatar--initial"
                          aria-hidden="true"
                        >{{row.last.initial}}</span>
                      {{/if}}
                      <span class="ef-forum__latest-text">
                        <a href={{row.last.url}}>{{row.last.title}}</a>
                        <span>{{row.last.when}} · {{row.last.user}}</span>
                      </span>
                    {{else}}
                      <span class="ef-forum__empty">No topics yet</span>
                    {{/if}}
                  </div>
                </div>
              {{/each}}
            </div>
          </section>
        {{/each}}
      </div>

      <aside class="ef-home__aside">
        {{#if this.latest.length}}
          <section class="ef-side ef-frame">
            <h2 class="ef-bar"><span class="ef-bar__title">Latest posts</span></h2>
            <div class="ef-inner">
              {{#each this.latest as |item|}}
                <div class="ef-latest-item">
                  {{#if item.avatar}}
                    <img
                      class="ef-avatar"
                      src={{item.avatar}}
                      alt=""
                      loading="lazy"
                    />
                  {{else}}
                    <span
                      class="ef-avatar ef-avatar--initial"
                      aria-hidden="true"
                    >{{item.initial}}</span>
                  {{/if}}
                  <span class="ef-latest-item__text">
                    <a href={{item.url}}>{{item.title}}</a>
                    <span>{{item.user}} · {{item.when}}</span>
                  </span>
                </div>
              {{/each}}
            </div>
          </section>
        {{/if}}

        {{#if settings.show_stats}}
          <EfForumStats />
        {{/if}}
      </aside>
    </div>
  </template>
}

// Replaces core's topic list on a hall's own page (/c/<hall>, the
// "discovery.category" route): the hall's forums in sections, each with its
// medallion, counts and latest topic, and Latest posts and Forum stats on
// the right. Everywhere else it shows core's list unchanged ({{yield}}).
export default class EfHallHome extends Component {
  @service router;

  get hall() {
    if (this.router.currentRouteName !== "discovery.category") {
      return null;
    }
    const category = this.args.outletArgs?.category;
    const hall = hallFor(category, settings);
    return hall && hall.id === category.id ? hall : null;
  }

  // A one-item list keyed by id, so moving from one hall to another builds
  // a fresh page (and loads that hall's topics)
  get hallList() {
    return this.hall ? [this.hall] : [];
  }

  <template>
    {{#if this.hall}}
      {{bodyClass "ef-hall-page"}}
      {{#each this.hallList key="id" as |hall|}}
        <EfHallForums @hall={{hall}} />
      {{/each}}
    {{else}}
      {{yield}}
    {{/if}}
  </template>
}
