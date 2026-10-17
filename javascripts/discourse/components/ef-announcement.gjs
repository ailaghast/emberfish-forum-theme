import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { trustHTML } from "@ember/template";

// The site-wide announcement bar on the lobby. It shows the core "banner
// topic" (topic wrench → Make banner topic) and remembers dismissals the
// same way core does, so closing it here also hides it on other pages.
export default class EfAnnouncement extends Component {
  @service site;
  @service currentUser;
  @service keyValueStore;

  @tracked hidden = false;

  get banner() {
    return this.site.banner;
  }

  get visible() {
    const key = parseInt(this.banner?.key, 10);
    if (!key || this.hidden) {
      return false;
    }
    const dismissed = parseInt(
      this.currentUser?.dismissed_banner_key ||
        this.keyValueStore.get("dismissed_banner_key"),
      10
    );
    return dismissed !== key;
  }

  get content() {
    return trustHTML(this.banner?.html || "");
  }

  @action
  dismiss() {
    this.hidden = true;
    if (this.currentUser) {
      this.currentUser.dismissBanner(this.banner.key);
    } else {
      this.keyValueStore.set({
        key: "dismissed_banner_key",
        value: this.banner.key,
      });
    }
  }

  <template>
    {{#if this.visible}}
      <div id="banner" class="ef-announcement">
        <div class="floated-buttons">
          {{#if this.currentUser.staff}}
            <a
              class="btn btn-transparent edit-banner"
              href={{this.banner.url}}
              aria-label="Edit announcement"
            ><svg class="fa d-icon svg-icon" aria-hidden="true"><use
                  href="#pencil"
                ></use></svg></a>
          {{/if}}
          <button
            type="button"
            class="btn btn-transparent close"
            aria-label="Dismiss announcement"
            {{on "click" this.dismiss}}
          ><svg class="fa d-icon svg-icon" aria-hidden="true"><use
                href="#xmark"
              ></use></svg></button>
        </div>
        <div id="banner-content">{{this.content}}</div>
      </div>
    {{/if}}
  </template>
}
