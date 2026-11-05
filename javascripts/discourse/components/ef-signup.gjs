import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { service } from "@ember/service";
import getURL from "discourse/lib/get-url";
import { getJSON } from "../lib/ef-activity";

const NOT_AN_EMAIL = "That doesn’t look like an email address.";

// Gives each signup's field its own id
let signups = 0;

// A newsletter signup that keeps visitors on the forum: an email field and
// Keep me posted, sent to a Kit form (@formId, a number). Kit takes posts from
// any site and replies in JSON ({ status: "success" | "quarantined" |
// "failed", errors: { messages } }), then sends its own confirmation email.
// A member's forum email fills in when they click into the field, not before,
// so it never shows on a streamed or shared screen; nothing is sent until they
// click the button. @autofocus puts the cursor in the field straight away.
export default class EfSignup extends Component {
  @service currentUser;

  @tracked email = "";
  @tracked sending = false;
  @tracked done = false;
  @tracked message = "";
  @tracked failed = false;

  inputId = `ef-signup-${++signups}`;
  filled = false;

  constructor() {
    super(...arguments);
    if (this.args.autofocus) {
      // Once the field is on the page
      requestAnimationFrame(() =>
        document.getElementById(this.inputId)?.focus()
      );
    }
  }

  get formAction() {
    return `https://app.kit.com/forms/${this.args.formId}/subscriptions`;
  }

  // Kit keeps the page each subscriber signed up on
  get referrer() {
    return window.location.href;
  }

  get privacyUrl() {
    return getURL("/privacy");
  }

  get noteClass() {
    return this.failed
      ? "ef-signup__note ef-signup__note--error"
      : "ef-signup__note";
  }

  say(message, failed = false) {
    this.message = message;
    this.failed = failed;
  }

  @action
  updateEmail(event) {
    this.email = event.target.value;
  }

  // A member's own address, the first time they click into the field
  @action
  async fill(event) {
    if (!this.currentUser || this.filled) {
      return;
    }
    this.filled = true;
    const input = event.target;
    try {
      const result = await getJSON(
        `/u/${encodeURIComponent(this.currentUser.username)}/emails.json`
      );
      if (!this.email && result?.email) {
        this.email = result.email;
        requestAnimationFrame(() => input.select());
      }
    } catch {
      // The field just stays empty
    }
  }

  @action
  async submit(event) {
    event.preventDefault();
    const form = event.target;
    if (!this.email.trim() || !form.elements.email_address.checkValidity()) {
      this.say(NOT_AN_EMAIL, true);
      return;
    }
    const body = new FormData(form);
    this.sending = true;
    this.say("Sending…");
    try {
      const response = await fetch(this.formAction, {
        method: "POST",
        body,
        headers: { Accept: "application/json" },
      });
      const data = await response.json();
      if (data.status === "success") {
        this.done = true;
        this.say(
          "Almost there! Check your inbox and click the link to confirm. No email? Look in Spam or Promotions."
        );
      } else if (data.status === "quarantined") {
        // Kit wants a bot check: hand over to its own page, which runs it
        form.submit();
      } else {
        const messages = data.errors?.messages || [];
        this.say(
          messages.some((m) => /email/i.test(m))
            ? NOT_AN_EMAIL
            : "That didn’t work. Try again?",
          true
        );
      }
    } catch {
      this.say("Couldn’t reach the mail server. Try again in a moment.", true);
    } finally {
      this.sending = false;
    }
  }

  <template>
    <div class="ef-signup">
      {{#unless this.done}}
        <form
          class="ef-signup__form"
          action={{this.formAction}}
          method="post"
          novalidate
          {{on "submit" this.submit}}
        >
          {{! readonly, not disabled, while sending: Kit's bot-check
            hand-over posts the form itself, and disabled fields aren't sent }}
          <input
            id={{this.inputId}}
            type="email"
            name="email_address"
            value={{this.email}}
            placeholder="you@example.com"
            aria-label="Email address"
            autocomplete="email"
            required
            readonly={{this.sending}}
            {{on "input" this.updateEmail}}
            {{on "focus" this.fill}}
          />
          <input type="hidden" name="referrer" value={{this.referrer}} />
          <button
            type="submit"
            class="ef-btn ef-btn--hot"
            disabled={{this.sending}}
          >Keep me posted</button>
        </form>
      {{/unless}}
      <p class={{this.noteClass}} role="status" aria-live="polite">
        {{#if this.message}}
          {{this.message}}
        {{else}}
          Unsubscribe anytime.
          <a href={{this.privacyUrl}}>Privacy policy</a>
        {{/if}}
      </p>
    </div>
  </template>
}
