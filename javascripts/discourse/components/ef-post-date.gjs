import Component from "@glimmer/component";

// Full date and time at the start of a post's top bar (desktop), in place
// of core's short "2h" date. Links to the post, like the core date does.
const SHORT = new Intl.DateTimeFormat(undefined, {
  dateStyle: "medium",
  timeStyle: "short",
});
const LONG = new Intl.DateTimeFormat(undefined, {
  dateStyle: "full",
  timeStyle: "short",
});

export default class EfPostDate extends Component {
  get date() {
    const value = this.args.post.displayDate || this.args.post.created_at;
    return value ? new Date(value) : null;
  }

  get text() {
    return this.date ? SHORT.format(this.date) : "";
  }

  get title() {
    return this.date ? LONG.format(this.date) : "";
  }

  get iso() {
    return this.date ? this.date.toISOString() : "";
  }

  <template>
    <div class="post-info ef-post-date">
      <a href={{@post.shareUrl}} title={{this.title}}>
        <time datetime={{this.iso}}>{{this.text}}</time>
      </a>
    </div>
  </template>
}
