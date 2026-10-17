import Component from "@glimmer/component";
import { pairs, uploadUrl } from "../lib/ef-config";

// A forum's square medallion: the category's Logo image (a hero portrait),
// or an icon when it has none (category_icons setting, then the category's
// own icon, then a speech bubble).
export default class EfMedal extends Component {
  get image() {
    return uploadUrl(this.args.category?.uploaded_logo);
  }

  get iconRef() {
    const c = this.args.category;
    const icon =
      pairs(settings.category_icons).get(c?.slug) ||
      (c?.style_type === "icon" && c.icon) ||
      "comments";
    return `#${icon}`;
  }

  <template>
    {{#if this.image}}
      <img
        class="ef-medal"
        src={{this.image}}
        alt=""
        loading="lazy"
        ...attributes
      />
    {{else}}
      <span class="ef-medal ef-medal--icon" aria-hidden="true" ...attributes>
        <svg class="fa d-icon svg-icon"><use href={{this.iconRef}}></use></svg>
      </span>
    {{/if}}
  </template>
}
