// Replaces the logo inside the header's home link: the Emberfish Games
// wordmark in its ember gradient, or just the swirl when the header shrinks
// to show a topic's title.
const EfBrand = <template>
  <span class="ef-brand">
    {{#if @outletArgs.minimized}}
      <img
        class="ef-brand__mark"
        src={{settings.theme_uploads.ef_mark}}
        alt="Emberfish Games"
      />
    {{else}}
      <img
        class="ef-brand__logo"
        src={{settings.theme_uploads.ef_logo}}
        alt="Emberfish Games"
      />
    {{/if}}
  </span>
</template>;

export default EfBrand;
