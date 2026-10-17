import Component from "@glimmer/component";
import { service } from "@ember/service";
import getURL from "discourse/lib/get-url";

export default class EfHeaderNav extends Component {
  @service router;
  @service site;

  get forumsActive() {
    const name = this.router.currentRouteName || "";
    return name.startsWith("discovery") || name.startsWith("topic");
  }

  <template>
    {{#if this.site.desktopView}}
      <nav class="ef-header-nav" aria-label="Site">
        <a
          href={{getURL "/"}}
          class={{if this.forumsActive "active"}}
        >Forums</a>
        {{#if settings.nav_rules_url}}
          <a href={{settings.nav_rules_url}}>Rules</a>
        {{/if}}
        {{#if settings.nav_website_url}}
          <a
            href={{settings.nav_website_url}}
            target="_blank"
            rel="noopener noreferrer"
          >Website ↗</a>
        {{/if}}
      </nav>
    {{/if}}
  </template>
}
