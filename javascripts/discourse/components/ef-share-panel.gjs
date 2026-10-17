import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { splitList } from "../lib/ef-config";

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

// Share panel on a hall page: buttons for the share_networks setting and a
// copyable link to the hall (@hall)
export default class EfSharePanel extends Component {
  @tracked copied = false;

  get shareUrl() {
    return window.location.origin + this.args.hall.url;
  }

  get links() {
    const u = encodeURIComponent(this.shareUrl);
    const t = encodeURIComponent(settings.share_text || document.title);
    return splitList(settings.share_networks)
      .filter((key) => SHARE[key])
      .map((key) => ({ label: SHARE[key].label, href: SHARE[key].url(u, t) }));
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
    {{#if this.links.length}}
      <section class="ef-side ef-frame">
        <h2 class="ef-bar"><span class="ef-bar__title">Share</span></h2>
        <div class="ef-inner ef-share">
          <span class="ef-share__intro">Know someone who’d like
            {{@hall.name}}? Bring them along.</span>
          <div class="ef-share__grid">
            {{#each this.links as |share|}}
              <a
                class="ef-share__net"
                href={{share.href}}
                target="_blank"
                rel="noopener noreferrer"
              >{{share.label}}</a>
            {{/each}}
          </div>
          <div class="ef-share__copy">
            <input
              type="text"
              readonly
              value={{this.shareUrl}}
              aria-label="Link to this hall"
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
  </template>
}
