# Emberfish Ashen Gate theme

The forum theme for forum.emberfishgames.com: warm charcoal panels in thin gold frames with gem corners, crimson header bars, buttons that glow ember orange, Cinzel labels and EB Garamond text (served from the forum, never from Google). It has the structure of the Riverfront and Local Heretics forums, plus a lobby and one hall per game.

The step-by-step setup, install included, is in `../forum-setup.md` (steps 4 and 8). Updating later is in `UPDATING.md`. A static preview of the look is in `../preview/` (rebuild with `node ../tools/make-preview.js`).

## What's in it

- **Header:** the Emberfish Games logo, then Forums · Rules · Website ↗.
- **Halls bar:** Lobby · one tab per game hall · Support.
- **Lobby (homepage):** a small Emberfish crest (no words), one door per game (art, logo, tagline, pitch, Enter the hall + store button), the announcement bar and the newsletter strip for all Emberfish news (an email field and **Keep me posted**). Nothing else: each hall's page has its own activity panels.
- **Hall page** (`/c/<game>`): the game's banner with its buttons (plus **Get news by email** for the game's own newsletter), the announcement bar, the tab row (Forums · Latest · New · Top · In · New Topic), the game's forums in sections (Official / Community / a section per DLC / Help us build it) with hero medallions, and Latest posts (this game only), Support, Forum stats and Share (the hall's link) on the right.
- **Inside a game** (its forums and topics): a slim banner.
- **Posts:** classic author panel on the left on desktop, full date in the post's top bar, Staff tag.
- Players who open /categories land on the lobby. Staff can still use it.

## Two color palettes

The theme comes with two palettes, and the one picked on the theme page (**Color palette** and **Dark color palette**, set both the same) is the look of the whole forum:
- **Emberfish Ashen Gate**: warm near-black panels with bright gold frames (the original).
- **Emberfish Slate**: cool slate-grey panels, duller gold frames and softer button glow (from how the forum looked under the Dark Reader extension). The buttons follow the palette by its stylesheet's name, so keep the palette's name as it is.

The theme takes its page, panel and frame colors from the palette (secondary = page, hover = lightest panel, highlight = frame gold), so a palette edit in Admin → Color palettes changes the theme too.

## Where a game's look comes from (secrecy)

**The theme holds no game art and names no game.** Theme files and settings are sent to every visitor, so anything in them could reveal an unannounced game. Everything about a game lives on its **category** instead, and Discourse sends a category's data only to people allowed to see it.

A top-level category becomes a **game hall** as soon as it has a **Background image**. In the category's settings → **Images**:

| Field | What the theme does with it | File (from `../category-images/<game>/`) |
|---|---|---|
| Logo image | Square icon: halls bar, topic chips, category badges | `<game> - Logo (icon).png` |
| Dark logo image | The game's wordmark: banner and lobby door | `<game> - Dark logo (wordmark).webp` |
| Background image | Banner art: hall banner and lobby door | `<game> - Background (banner).webp` |

Each **subcategory**'s Logo image is its medallion (`<slug> - Logo.webp`). Subcategories without one show an icon (`category_icons` setting).

A **DLC** is a subcategory with forums of its own (Hadean Tactics › Moonhunter DLC › General Discussion; needs the site setting `max category nesting` = 3). The hall page shows it as its own section, named after it, where `hall_sections` has its `*` line. Its forums get medallions the same way, and its topics count towards the game's lobby door.

Discourse would normally paint the Background image behind the whole category page and show the Logo above the topic list. The theme turns both off.

The tagline, pitch and store buttons come from the `hall_details` setting, one line per game. **Add a game's line only when the game is public**, because settings are public too. Before then, staff see the hidden game's hall with its art but without those words.

## Theme settings (theme page → Settings)

| Setting | Default |
|---|---|
| `nav_rules_url`, `nav_website_url` | `/guidelines`, `https://emberfishgames.com` |
| `hall_details` | `slug;tagline;pitch;button;link;button 2;link 2`, one line per game. Hadean Tactics only |
| `hall_newsletter` | `slug;Kit form number`, one line per game: a **Get news by email** button on the hall banner (not on the lobby door) that opens the game's signup in place. Empty: add each game's forum form (below) |
| `lobby_newsletter` | `bold first words;the rest;Kit form number`: the lobby's newsletter strip, for all Emberfish news. Hidden until the form number is added (below) |
| `support_category` | `support` |
| `hall_sections` | `Section;slug,slug`, one line per section, shared by all games. A line that is just `*` is where DLC sections go |
| `category_icons` | `forum-help:circle-question`, `forum-feedback:comment` |
| `latest_count` | 5 (the hall page's Latest posts) |
| `share_networks` | `x\|reddit\|facebook\|whatsapp\|weibo\|email` |
| `show_stats`, `hide_profile_location`, `hide_profile_bio`, `content_width` | on, on, off, 1280 |

Black Flame's line for reveal day:

```
black-flame;Coming 2027 · Free demo out now;Lead your company down the circles and steal the Black Flame.;Wishlist on Steam;https://store.steampowered.com/app/3382760/Hadean_Tactics_Black_Flame/
```

### Newsletter signups

Both signups send the address to a Kit form without leaving the forum (Kit accepts posts from other sites and answers in JSON), then show "Almost there! Check your inbox…" in place. Kit sends its usual confirmation email. For a logged-in member, the field fills in their forum email when they click into it, not before, so it never shows on a streamed or shared screen. Nothing is sent until they click **Keep me posted**. If Kit asks for a bot check, the visitor is handed over to Kit's own page to finish.

The settings take a Kit form's **number**: open the form in Kit and copy it from the address (`app.kit.com/forms/designers/NUMBER/edit`), or paste that whole address. Kit's share links (`<name>.kit.com/…`) don't contain it.

Use the **forum** forms, so Kit counts forum signups apart from the website's, demos' and games':

| Form in Kit | Setting |
|---|---|
| Black Flame Arena, forum | `hall_newsletter`: `black-flame;NUMBER` |
| Hadean Tactics, forum | `hall_newsletter`: `hadean-tactics;NUMBER` |
| Emberfish, forum | `lobby_newsletter`: put the number after the last `;` |

```
hall_newsletter:   black-flame;NUMBER|hadean-tactics;NUMBER
lobby_newsletter:  The big dates, by email.;Demos, playtests, launches and big sales for all our games. Only the big moments.;NUMBER
```

A new game's line goes in `hall_newsletter` once the game is public, with its own forum form.

## Changing the art

`node ../tools/build-assets.js` rebuilds `assets/` (logo, swirl mark, fonts), `../category-images/` and `../branding/` from the original art. After it runs, re-upload any changed category image in that category's settings.
