import Component from "@glimmer/component";
import { childrenOf, findTopLevel } from "../lib/ef-config";
import EfMedal from "./ef-medal";

// Support panel on the hall pages: the forums of the forum-wide Support
// category (support_category setting), each with its icon and description
export default class EfSupportPanel extends Component {
  get forums() {
    const parent = findTopLevel(settings.support_category);
    return parent ? childrenOf(parent) : [];
  }

  <template>
    {{#if this.forums.length}}
      <section class="ef-side ef-frame">
        <h2 class="ef-bar"><span class="ef-bar__title">Support</span></h2>
        <div class="ef-inner">
          {{#each this.forums as |category|}}
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
  </template>
}
