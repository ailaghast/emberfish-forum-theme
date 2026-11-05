import Component from "@glimmer/component";
import { kitFormId } from "../lib/ef-config";
import EfSignup from "./ef-signup";

// The newsletter strip at the end of the lobby, for news about all of the
// studio's games, from the lobby_newsletter setting: "bold first words;the
// rest;Kit form". Each hall banner signs up to its own game's form
// (hall_newsletter). Hidden until the setting has a form.
export default class EfNewsletter extends Component {
  get newsletter() {
    const [bold, rest, form] = (settings.lobby_newsletter || "")
      .split(";")
      .map((s) => (s || "").trim());
    const formId = kitFormId(form);
    return formId ? { bold, rest, formId } : null;
  }

  <template>
    {{#if this.newsletter}}
      <section class="ef-newsletter" aria-label="Newsletter">
        <span class="ef-newsletter__tag">Newsletter</span>
        <p class="ef-newsletter__text">
          <b>{{this.newsletter.bold}}</b>
          {{this.newsletter.rest}}
        </p>
        <EfSignup @formId={{this.newsletter.formId}} />
      </section>
    {{/if}}
  </template>
}
