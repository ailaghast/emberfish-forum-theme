import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { service } from "@ember/service";
import Category from "discourse/models/category";
import { fetchAbout } from "../lib/ef-activity";
import { fmtNumber } from "../lib/ef-config";

const ICONS = {
  Topics: "#comment",
  Posts: "#file-lines",
  Members: "#user-group",
};

// Forum stats panel (hall pages). Topics and posts count public
// categories only, so staff see the same numbers as everyone else; category
// counts already leave out each category's "About" topic.
export default class EfForumStats extends Component {
  @service currentUser;

  @tracked members = null;

  constructor() {
    super(...arguments);
    fetchAbout(this.currentUser?.id ?? "anon")
      .then((about) => (this.members = about.users_count))
      .catch(() => {});
  }

  get rows() {
    const open = Category.list().filter((c) => !c.read_restricted);
    const sum = (key) => open.reduce((n, c) => n + (Number(c[key]) || 0), 0);
    const rows = [
      { label: "Topics", value: fmtNumber(sum("topic_count")) },
      { label: "Posts", value: fmtNumber(sum("post_count")) },
    ];
    if (this.members !== null) {
      rows.push({ label: "Members", value: fmtNumber(this.members) });
    }
    return rows.map((r) => ({ ...r, icon: ICONS[r.label] }));
  }

  <template>
    <section class="ef-side ef-frame">
      <h2 class="ef-bar"><span class="ef-bar__title">Forum stats</span></h2>
      <dl class="ef-inner ef-stats">
        {{#each this.rows as |stat|}}
          <div class="ef-stat">
            <dt><svg class="fa d-icon svg-icon" aria-hidden="true"><use
                  href={{stat.icon}}
                ></use></svg>{{stat.label}}</dt>
            <dd>{{stat.value}}</dd>
          </div>
        {{/each}}
      </dl>
    </section>
  </template>
}
